import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/mesh_message.dart';
import 'storage_service.dart';

class BleService {
  static final Guid SERVICE_UUID =
      Guid("6E400001-B5A3-F393-E0A9-E50E24DCCA9E");
  static final Guid MESSAGE_CHAR_UUID =
      Guid("6E400002-B5A3-F393-E0A9-E50E24DCCA9E");

  final StorageService storage = StorageService();
  final String myUserId;
  String myUserName = "Anonymous";

  final StreamController<MeshMessage> incomingMessages =
      StreamController.broadcast();
  final StreamController<BluetoothDevice> nearbyDevices =
      StreamController.broadcast();
  final StreamController<String> statusUpdates =
      StreamController.broadcast();

  final Set<String> _seenMessageIds = {};
  final Map<String, BluetoothDevice> _knownDevices = {};

  BleService({required this.myUserId});

  // ---------- START EVERYTHING ----------
  Future<void> start() async {
    await _ensureBluetoothOn();
    await _startAdvertising();
    _startScanning();
  }

  Future<void> _ensureBluetoothOn() async {
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      statusUpdates.add("Waiting for Bluetooth...");
      await FlutterBluePlus.adapterState
          .where((s) => s == BluetoothAdapterState.on)
          .first;
    }
    statusUpdates.add("Bluetooth ready");
  }

  // ---------- ADVERTISE (be discoverable) ----------
  Future<void> _startAdvertising() async {
    try {
      await FlutterBluePlus.startAdvertising(
        name: "MeshChat-$myUserId",
        serviceUuids: [SERVICE_UUID],
      );
      statusUpdates.add("Advertising as $myUserName");
    } catch (e) {
      statusUpdates.add("Advertise error: $e");
    }
  }

  // ---------- SCAN (find others) ----------
  void _startScanning() {
    FlutterBluePlus.onScanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.advertisementData.serviceUuids.contains(SERVICE_UUID)) {
          final id = r.device.remoteId.toString();
          if (!_knownDevices.containsKey(id)) {
            _knownDevices[id] = r.device;
            nearbyDevices.add(r.device);
            statusUpdates.add("Found: ${r.device.platformName}");
          }
        }
      }
    });

    FlutterBluePlus.startScan(
      withServices: [SERVICE_UUID],
      continuousUpdates: true,
      timeout: const Duration(seconds: 60),
    );
  }

  // ---------- SEND MESSAGE ----------
  Future<bool> sendMessage(MeshMessage msg) async {
    // Save locally first
    await _handleIncoming(msg, isOwn: true);

    if (_knownDevices.isEmpty) {
      statusUpdates.add("No devices nearby — message will relay when found");
      return false;
    }

    bool sent = false;
    for (final device in _knownDevices.values) {
      try {
        if (!device.isConnected) {
          await device.connect(timeout: const Duration(seconds: 8));
        }
        final services = await device.discoverServices();
        for (final service in services) {
          if (service.uuid == SERVICE_UUID) {
            for (final c in service.characteristics) {
              if (c.uuid == MESSAGE_CHAR_UUID) {
                await c.write(utf8.encode(msg.encode()));
                sent = true;
              }
            }
          }
        }
      } catch (e) {
        statusUpdates.add("Send failed to one peer: $e");
      }
    }
    return sent;
  }

  // ---------- RECEIVE + RELAY ----------
  Future<void> _handleIncoming(MeshMessage msg, {bool isOwn = false}) async {
    // 1. Deduplicate
    if (_seenMessageIds.contains(msg.id)) return;
    _seenMessageIds.add(msg.id);

    // 2. If it's for someone else AND ttl > 0, relay it
    if (!isOwn && msg.recipientId != null && msg.recipientId != myUserId) {
      if (!msg.isExpired) {
        await _relay(msg.forwarded(myUserId));
      }
      return;
    }

    // 3. Save + notify UI
    await storage.saveMessage(msg);
    incomingMessages.add(msg);
  }

  Future<void> _relay(MeshMessage msg) async {
    for (final device in _knownDevices.values) {
      try {
        if (!device.isConnected) {
          await device.connect(timeout: const Duration(seconds: 6));
        }
        final services = await device.discoverServices();
        for (final service in services) {
          if (service.uuid == SERVICE_UUID) {
            for (final c in service.characteristics) {
              if (c.uuid == MESSAGE_CHAR_UUID) {
                await c.write(utf8.encode(msg.encode()));
              }
            }
          }
        }
      } catch (_) {}
    }
  }

  void dispose() {
    FlutterBluePlus.stopScan();
    FlutterBluePlus.stopAdvertising();
    incomingMessages.close();
    nearbyDevices.close();
    statusUpdates.close();
  }
}
