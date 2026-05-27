import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../../../domain/repositories/photo_repository.dart';

class PhotoRepositoryAndroid implements PhotoRepository {
  static const int _maxDimension = 1080;
  static const int _quality = 85;

  Future<Directory> get _baseDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/skin_photos');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  @override
  Future<void> savePhoto(String key, Uint8List bytes) async {
    final compressed = await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      quality: _quality,
    );
    final base = await _baseDir;
    final file = File('${base.path}/$key.jpg');
    await file.writeAsBytes(compressed);
  }

  @override
  Future<Uint8List?> readPhoto(String key) async {
    final base = await _baseDir;
    final file = File('${base.path}/$key.jpg');
    if (!file.existsSync()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> deletePhoto(String key) async {
    final base = await _baseDir;
    final file = File('${base.path}/$key.jpg');
    if (file.existsSync()) {
      await file.delete();
    }
  }

  @override
  Future<List<String>> listAllKeys() async {
    final base = await _baseDir;
    return base
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.jpg'))
        .map((f) => f.uri.pathSegments.last.replaceAll('.jpg', ''))
        .toList();
  }
}
