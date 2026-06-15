import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/master_content_repository.dart';
import 'master_content_cache.dart';
import 'master_content_serializer.dart';

class SharedPrefsMasterContentCache implements MasterContentCache {
  static const _key = 'master_content_cache_v1';

  @override
  Future<MasterContent?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return MasterContentSerializer.fromCombinedJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(MasterContent content) async {
    final prefs = await SharedPreferences.getInstance();
    final json = MasterContentSerializer.toJson(content);
    await prefs.setString(_key, jsonEncode(json));
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
