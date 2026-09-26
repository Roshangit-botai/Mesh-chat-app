import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mesh_message.dart';

class StorageService {
  static const _msgKey = 'mesh_messages';
  static const _idKey = 'my_user_id';
  static const _nameKey = 'my_user_name';

  Future<void> saveMessage(MeshMessage msg) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_msgKey) ?? [];
    list.add(msg.encode());
    // Keep only last 200 messages
    if (list.length > 200) list.removeAt(0);
    await prefs.setStringList(_msgKey, list);
  }

  Future<List<MeshMessage>> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_msgKey) ?? [];
    return list.map((e) => MeshMessage.decode(e)).toList();
  }

  Future<void> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_idKey, id);
  }

  Future<String?> loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<String?> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }
}
