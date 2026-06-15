import '../../domain/repositories/master_content_repository.dart';
import '../../domain/repositories/refreshable_repository.dart';
import '../cache/master_content_cache.dart';
import '../remote/remote_content_data_source.dart';

class RemoteCachedMasterContentRepositoryImpl
    implements MasterContentRepository, RefreshableRepository {
  final MasterContentRepository _bundled;
  final RemoteContentDataSource _remote;
  final MasterContentCache _cache;

  MasterContent? _inMemory;
  bool _isRefreshing = false;

  RemoteCachedMasterContentRepositoryImpl({
    required MasterContentRepository bundled,
    required RemoteContentDataSource remote,
    required MasterContentCache cache,
  })  : _bundled = bundled,
        _remote = remote,
        _cache = cache;

  @override
  Future<MasterContent> load() async {
    if (_inMemory != null) return _inMemory!;
    final cached = await _cache.read();
    if (cached != null) {
      _inMemory = cached;
      return cached;
    }
    final bundled = await _bundled.load();
    _inMemory = bundled;
    return bundled;
  }

  @override
  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      final fresh = await _remote.fetchContent();
      await _cache.write(fresh);
      _inMemory = fresh;
    } catch (_) {
      // network unavailable — keep existing cache and in-memory state
    } finally {
      _isRefreshing = false;
    }
  }
}
