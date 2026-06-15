import '../../domain/repositories/master_content_repository.dart';

abstract class MasterContentCache {
  Future<MasterContent?> read();
  Future<void> write(MasterContent content);
  Future<void> clear();
}
