import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/photo_repository.dart';

/// Web implementation: persists photos as base64 in SharedPreferences (localStorage).
/// Each photo stored under key `photo_<key>`; index stored under `photo_keys`.
class PhotoRepositoryWeb implements PhotoRepository {
  static const _keyPrefix = 'photo_';
  static const _indexKey = 'photo_keys';

  @override
  Future<void> savePhoto(String key, Uint8List bytes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPrefix + key, base64Encode(bytes));

    final keys = _loadKeys(prefs);
    if (!keys.contains(key)) {
      keys.add(key);
      await prefs.setString(_indexKey, jsonEncode(keys));
    }
  }

  @override
  Future<Uint8List?> readPhoto(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_keyPrefix + key);
    if (encoded == null) return null;
    return base64Decode(encoded);
  }

  @override
  Future<void> deletePhoto(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix + key);

    final keys = _loadKeys(prefs)..remove(key);
    await prefs.setString(_indexKey, jsonEncode(keys));
  }

  @override
  Future<List<String>> listAllKeys() async {
    final prefs = await SharedPreferences.getInstance();
    return _loadKeys(prefs);
  }

  List<String> _loadKeys(SharedPreferences prefs) {
    final raw = prefs.getString(_indexKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>).cast<String>();
  }
}
