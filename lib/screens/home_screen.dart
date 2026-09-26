import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../services/ble_service.dart';
import '../services/storage_service.dart';
import 'chat_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _nameController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  Future<void> _loadIdentity() async {
    await _requestPermissions();
    final storage = StorageService();
    final name = await storage.loadUserName();
    if (name != null && name.isNotEmpty) {
      _nameController.text = name;
    } else {
      _nameController.text = "User${DateTime.now().millisecond}";
    }
    setState(() => _loading = false);
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startChat() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final storage = StorageService();
    await storage.saveUserName(name);

    String? id = await storage.loadUserId();
    if (id == null) {
      id = const Uuid().v4().substring(0, 8);
      await storage.saveUserId(id);
    }

    final ble = BleService(myUserId: id)..myUserName = name;
    await ble.start();

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatScreen(ble: ble)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            const Text(
              "Offline Mesh Chat",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Works without internet or WiFi.\nJust Bluetooth.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Your display name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _startChat,
                child: const Text("Start Chatting"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
