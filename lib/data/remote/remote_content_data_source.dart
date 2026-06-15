import '../../domain/repositories/master_content_repository.dart';

abstract class RemoteContentDataSource {
  Future<MasterContent> fetchContent();
}
