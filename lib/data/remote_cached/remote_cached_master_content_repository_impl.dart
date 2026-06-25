import 'package:flutter/foundation.dart';
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

  /// Deduplicates concurrent first-load calls so only one network request fires.
  Future<MasterContent>? _pendingLoad;

  /// Deduplicates concurrent refresh() calls.
  Future<void>? _pendingRefresh;

  RemoteCachedMasterContentRepositoryImpl({
    required MasterContentRepository bundled,
    required RemoteContentDataSource remote,
    required MasterContentCache cache,
  })  : _bundled = bundled,
        _remote = remote,
        _cache = cache;

  /// Returns master content, fetching from Supabase first.
  /// The Supabase result is merged with the bundled JSON so that any products
  /// present in a new app build but not yet pushed to Supabase are preserved.
  /// Supabase wins on any conflict (same product ID). Falls back to disk cache
  /// then bundled JSON when the network is unavailable.
  @override
  Future<MasterContent> load() {
    if (_inMemory != null) return Future.value(_inMemory);
    return _pendingLoad ??= _fetchWithFallback();
  }

  /// Forces a re-fetch from Supabase and updates in-memory state + cache.
  /// If Supabase is unavailable the current state is left unchanged.
  /// Concurrent calls are deduplicated — only one network request fires.
  @override
  Future<void> refresh() {
    _pendingRefresh ??=
        _doRefresh().whenComplete(() => _pendingRefresh = null);
    return _pendingRefresh!;
  }

  Future<MasterContent> _fetchWithFallback() async {
    // 1. Try Supabase (authoritative). Merge with bundled so products that exist
    //    in a new app build but haven't been pushed to Supabase yet are kept.
    try {
      debugPrint('[MasterContent] load: fetching from Supabase...');
      final remote = await _remote.fetchContent();
      final bundled = await _bundled.load();
      final merged = _mergeContent(remote, bundled);
      await _cache.write(merged);
      _inMemory = merged;
      debugPrint(
          '[MasterContent] load: Supabase OK — ${merged.products.length} products');
      return merged;
    } catch (e) {
      debugPrint('[MasterContent] load: Supabase unavailable — $e');
    }

    // 2. Disk cache from a previous successful Supabase fetch.
    final cached = await _cache.read();
    if (cached != null) {
      _inMemory = cached;
      debugPrint(
          '[MasterContent] load: using cache — ${cached.products.length} products');
      return cached;
    }

    // 3. Last resort: bundled JSON shipped with the app.
    final bundled = await _bundled.load();
    _inMemory = bundled;
    debugPrint(
        '[MasterContent] load: using bundled — ${bundled.products.length} products');
    return bundled;
  }

  Future<void> _doRefresh() async {
    try {
      debugPrint('[MasterContent] refresh: fetching from Supabase...');
      final remote = await _remote.fetchContent();
      final bundled = await _bundled.load();
      final merged = _mergeContent(remote, bundled);
      await _cache.write(merged);
      _inMemory = merged;
      _pendingLoad = Future.value(merged);
      debugPrint('[MasterContent] refresh: done ✓');
    } catch (e) {
      debugPrint('[MasterContent] refresh: FAILED — $e');
    }
  }

  /// Merges [remote] (Supabase) with [bundled] (local JSON).
  /// Remote wins for any item that exists in both (same ID). Items only in
  /// bundled are appended as a safety net for new app builds where a product
  /// was added to the bundled JSON but not yet pushed to Supabase.
  static MasterContent _mergeContent(
      MasterContent remote, MasterContent bundled) {
    return MasterContent(
      categories:
          _mergeById(remote.categories, bundled.categories, (c) => c.id),
      subcategories: _mergeById(
          remote.subcategories, bundled.subcategories, (s) => s.id),
      products: _mergeById(remote.products, bundled.products, (p) => p.id),
      rules: _mergeById(remote.rules, bundled.rules, (r) => r.id),
      manifest: remote.manifest,
    );
  }

  static List<T> _mergeById<T>(
      List<T> remote, List<T> local, String Function(T) getId) {
    final remoteIds = {for (final item in remote) getId(item)};
    return [
      ...remote,
      ...local.where((item) => !remoteIds.contains(getId(item))),
    ];
  }
}
