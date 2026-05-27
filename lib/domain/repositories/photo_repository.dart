import 'dart:typed_data';

abstract class PhotoRepository {
  Future<void> savePhoto(String key, Uint8List bytes);
  Future<Uint8List?> readPhoto(String key);
  Future<void> deletePhoto(String key);
  Future<List<String>> listAllKeys();
}
