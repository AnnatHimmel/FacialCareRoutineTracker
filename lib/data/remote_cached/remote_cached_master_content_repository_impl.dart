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

    // Always load bundled first so we can compare contentVersions.
    // MasterContentRepositoryImpl caches its result in-memory, so this is
    // only expensive on the very first call.
    final bundled = await _bundled.load();

    final cached = await _cache.read();
    if (cached != null) {
      if (_compareVersions(
              cached.manifest.contentVersion,
              bundled.manifest.contentVersion) >=
          0) {
        // Cache is at least as new as the bundled asset — use it.
        _inMemory = cached;
        return cached;
      }
      // Bundled asset is newer (e.g. a new app release added fields like
      // barcodes). Discard the stale cache so next launch also uses bundled.
      await _cache.clear();
    }

    _inMemory = bundled;
    return bundled;
  }

  /// Compares two semantic version strings (major.minor.patch).
  /// Returns negative if [a] < [b], 0 if equal, positive if [a] > [b].
  /// Non-numeric segments compare as 0 so arbitrary strings are treated equal.
  static int _compareVersions(String a, String b) {
    final aParts = a.split('.');
    final bParts = b.split('.');
    for (var i = 0; i < 3; i++) {
      final av = int.tryParse(aParts.elementAtOrNull(i) ?? '') ?? 0;
      final bv = int.tryParse(bParts.elementAtOrNull(i) ?? '') ?? 0;
      if (av != bv) return av - bv;
    }
    return 0;
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
