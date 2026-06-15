import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_tracker/data/cache/master_content_cache.dart';
import 'package:skincare_tracker/data/cache/shared_prefs_master_content_cache.dart';
import 'package:skincare_tracker/data/remote/remote_content_data_source.dart';
import 'package:skincare_tracker/data/remote_cached/remote_cached_master_content_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/refreshable_repository.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeBundled implements MasterContentRepository {
  final MasterContent content;
  int loadCount = 0;
  _FakeBundled(this.content);
  @override
  Future<MasterContent> load() async {
    loadCount++;
    return content;
  }
}

class _FakeDataSource implements RemoteContentDataSource {
  final MasterContent? response;
  final bool shouldThrow;
  int fetchCount = 0;

  _FakeDataSource({this.response, this.shouldThrow = false});

  @override
  Future<MasterContent> fetchContent() async {
    fetchCount++;
    if (shouldThrow) throw Exception('network error');
    return response!;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterContent _content(String contentVersion) => MasterContent(
      products: [
        MasterProduct(
          id: 'p-$contentVersion',
          name: 'Product $contentVersion',
          categoryId: 'cat-1',
          isDeprecated: false,
          addedInVersion: '1.0.0',
        ),
      ],
      categories: [const Category(id: 'cat-1', name: 'Test', order: 1)],
      rules: [],
      manifest: MasterListManifest(
        contentVersion: contentVersion,
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

RemoteCachedMasterContentRepositoryImpl _makeRepo({
  required MasterContent bundled,
  required _FakeDataSource remote,
  required MasterContentCache cache,
}) =>
    RemoteCachedMasterContentRepositoryImpl(
      bundled: _FakeBundled(bundled),
      remote: remote,
      cache: cache,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RemoteCachedMasterContentRepositoryImpl', () {
    test('load with empty cache returns bundled content', () async {
      final bundled = _content('bundled');
      final repo = _makeRepo(
        bundled: bundled,
        remote: _FakeDataSource(response: _content('remote')),
        cache: SharedPrefsMasterContentCache(),
      );
      expect(await repo.load(), equals(bundled));
    });

    test('load with populated cache returns cached content, not bundled', () async {
      final bundled = _content('bundled');
      final cached = _content('cached');
      final cache = SharedPrefsMasterContentCache();
      await cache.write(cached);

      final bundledRepo = _FakeBundled(bundled);
      final repo = RemoteCachedMasterContentRepositoryImpl(
        bundled: bundledRepo,
        remote: _FakeDataSource(response: _content('remote')),
        cache: cache,
      );

      expect(await repo.load(), equals(cached));
      expect(bundledRepo.loadCount, 0);
    });

    test('second load call returns in-memory result without re-reading cache',
        () async {
      var cacheReadCount = 0;
      final wrappedCache = _CountingCache(
        SharedPrefsMasterContentCache(),
        onRead: () => cacheReadCount++,
      );
      final repo = _makeRepo(
        bundled: _content('bundled'),
        remote: _FakeDataSource(response: _content('remote')),
        cache: wrappedCache,
      );

      await repo.load();
      await repo.load();
      expect(cacheReadCount, 1);
    });

    test('refresh updates in-memory and cache', () async {
      final fresh = _content('fresh');
      final cache = SharedPrefsMasterContentCache();
      final repo = _makeRepo(
        bundled: _content('bundled'),
        remote: _FakeDataSource(response: fresh),
        cache: cache,
      );

      await repo.load();
      await (repo as RefreshableRepository).refresh();

      expect(await repo.load(), equals(fresh));
      expect(await cache.read(), equals(fresh));
    });

    test('refresh when remote throws leaves existing cache unchanged', () async {
      final original = _content('original');
      final cache = SharedPrefsMasterContentCache();
      await cache.write(original);

      final repo = RemoteCachedMasterContentRepositoryImpl(
        bundled: _FakeBundled(_content('bundled')),
        remote: _FakeDataSource(shouldThrow: true),
        cache: cache,
      );
      await repo.load();
      await (repo as RefreshableRepository).refresh();

      expect(await cache.read(), equals(original));
      expect(await repo.load(), equals(original));
    });

    test('concurrent refresh calls result in only one network fetch', () async {
      final remote = _FakeDataSource(response: _content('fresh'));
      final repo = _makeRepo(
        bundled: _content('bundled'),
        remote: remote,
        cache: SharedPrefsMasterContentCache(),
      );
      await repo.load();

      await Future.wait([
        (repo as RefreshableRepository).refresh(),
        (repo as RefreshableRepository).refresh(),
      ]);

      expect(remote.fetchCount, 1);
    });

    test('after refresh, load returns fresh content', () async {
      final fresh = _content('fresh');
      final repo = _makeRepo(
        bundled: _content('bundled'),
        remote: _FakeDataSource(response: fresh),
        cache: SharedPrefsMasterContentCache(),
      );
      await repo.load();
      await (repo as RefreshableRepository).refresh();

      expect(await repo.load(), equals(fresh));
    });
  });
}

class _CountingCache implements MasterContentCache {
  final MasterContentCache _delegate;
  final void Function() onRead;

  _CountingCache(this._delegate, {required this.onRead});

  @override
  Future<MasterContent?> read() async {
    onRead();
    return _delegate.read();
  }

  @override
  Future<void> write(MasterContent content) => _delegate.write(content);

  @override
  Future<void> clear() => _delegate.clear();
}
