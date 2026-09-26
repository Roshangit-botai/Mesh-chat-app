import 'dart:convert';

class MeshMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? recipientId; // null = broadcast
  final String text;
  final int timestamp;
  final int ttl; // time-to-live hops
  final List<String> hops; // path taken

  MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.recipientId,
    required this.text,
    required this.timestamp,
    this.ttl = 5,
    List<String>? hops,
  }) : hops = hops ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'senderName': senderName,
        'recipientId': recipientId,
        'text': text,
        'timestamp': timestamp,
        'ttl': ttl,
        'hops': hops,
      };

  factory MeshMessage.fromJson(Map<String, dynamic> json) => MeshMessage(
        id: json['id'],
        senderId: json['senderId'],
        senderName: json['senderName'],
        recipientId: json['recipientId'],
        text: json['text'],
        timestamp: json['timestamp'],
        ttl: json['ttl'] ?? 5,
        hops: List<String>.from(json['hops'] ?? []),
      );

  String encode() => jsonEncode(toJson());

  static MeshMessage decode(String raw) =>
      MeshMessage.fromJson(jsonDecode(raw));

  MeshMessage forwarded(String relayId) => MeshMessage(
        id: id,
        senderId: senderId,
        senderName: senderName,
        recipientId: recipientId,
        text: text,
        timestamp: timestamp,
        ttl: ttl - 1,
        hops: [...hops, relayId],
      );

  bool get isExpired => ttl <= 0;
}
