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

MasterProduct _product(String id) => MasterProduct(
      id: id,
      name: 'Product $id',
      categoryId: 'cat-1',
      isDeprecated: false,
    );

MasterContent _contentWith(List<String> productIds, {String version = '1.0.0'}) =>
    MasterContent(
      products: productIds.map(_product).toList(),
      categories: [const Category(id: 'cat-1', name: 'Test', order: 1)],
      rules: [],
      manifest: MasterListManifest(
        contentVersion: version,
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

List<String> _ids(MasterContent c) => c.products.map((p) => p.id).toList();

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RemoteCachedMasterContentRepositoryImpl — load()', () {
    test('Supabase succeeds: returns Supabase products first', () async {
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: _FakeDataSource(response: _contentWith(['p-supabase'])),
        cache: SharedPrefsMasterContentCache(),
      );
      final result = await repo.load();
      expect(_ids(result).first, 'p-supabase');
    });

    test('Supabase succeeds: bundled-only products are appended (safety net)', () async {
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled-only']),
        remote: _FakeDataSource(response: _contentWith(['p-supabase'])),
        cache: SharedPrefsMasterContentCache(),
      );
      final result = await repo.load();
      expect(_ids(result), containsAll(['p-supabase', 'p-bundled-only']));
    });

    test('Supabase succeeds: Supabase wins for same product ID', () async {
      final supabaseProduct = _product('p-shared')
          .copyWith(name: 'Supabase Name');
      final supabaseContent = MasterContent(
        products: [supabaseProduct],
        categories: [const Category(id: 'cat-1', name: 'Test', order: 1)],
        rules: [],
        manifest: const MasterListManifest(
            contentVersion: '1.0.0', appVersion: '1.0.0', changelog: []),
      );

      final repo = _makeRepo(
        bundled: _contentWith(['p-shared']), // same ID, different name
        remote: _FakeDataSource(response: supabaseContent),
        cache: SharedPrefsMasterContentCache(),
      );
      final result = await repo.load();
      final shared = result.products.firstWhere((p) => p.id == 'p-shared');
      expect(shared.name, 'Supabase Name');
      expect(result.products.where((p) => p.id == 'p-shared').length, 1);
    });

    test('Supabase succeeds: saves merged result to cache', () async {
      final cache = SharedPrefsMasterContentCache();
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled-only']),
        remote: _FakeDataSource(response: _contentWith(['p-supabase'])),
        cache: cache,
      );
      await repo.load();
      final cached = await cache.read();
      expect(cached, isNotNull);
      expect(_ids(cached!), containsAll(['p-supabase', 'p-bundled-only']));
    });

    test('Supabase succeeds: ignores existing disk cache', () async {
      final cache = SharedPrefsMasterContentCache();
      await cache.write(_contentWith(['p-stale-cache']));

      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: _FakeDataSource(response: _contentWith(['p-supabase'])),
        cache: cache,
      );
      final result = await repo.load();
      expect(_ids(result), contains('p-supabase'));
      expect(_ids(result), isNot(contains('p-stale-cache')));
    });

    test('Supabase unavailable and cache exists: returns cache as-is', () async {
      final cache = SharedPrefsMasterContentCache();
      await cache.write(_contentWith(['p-cached']));

      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: _FakeDataSource(shouldThrow: true),
        cache: cache,
      );
      final result = await repo.load();
      expect(_ids(result), equals(['p-cached']));
    });

    test('Supabase unavailable and no cache: returns bundled as-is', () async {
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: _FakeDataSource(shouldThrow: true),
        cache: SharedPrefsMasterContentCache(),
      );
      final result = await repo.load();
      expect(_ids(result), equals(['p-bundled']));
    });

    test('Supabase unavailable and no cache: does not write to cache', () async {
      final cache = SharedPrefsMasterContentCache();
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: _FakeDataSource(shouldThrow: true),
        cache: cache,
      );
      await repo.load();
      expect(await cache.read(), isNull);
    });

    test('second load() returns in-memory — no second network call', () async {
      final remote = _FakeDataSource(response: _contentWith(['p-supabase']));
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: remote,
        cache: SharedPrefsMasterContentCache(),
      );
      await repo.load();
      await repo.load();
      expect(remote.fetchCount, 1);
    });

    test('concurrent load() calls result in only one network fetch', () async {
      final remote = _FakeDataSource(response: _contentWith(['p-supabase']));
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: remote,
        cache: SharedPrefsMasterContentCache(),
      );
      await Future.wait([repo.load(), repo.load(), repo.load()]);
      expect(remote.fetchCount, 1);
    });
  });

  group('RemoteCachedMasterContentRepositoryImpl — refresh()', () {
    test('refresh() fetches Supabase, merges with bundled, updates in-memory and cache',
        () async {
      final cache = SharedPrefsMasterContentCache();
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled-only']),
        remote: _FakeDataSource(response: _contentWith(['p-supabase'])),
        cache: cache,
      );
      await repo.load();
      await (repo as RefreshableRepository).refresh();

      final result = await repo.load();
      expect(_ids(result), containsAll(['p-supabase', 'p-bundled-only']));
      expect(_ids((await cache.read())!),
          containsAll(['p-supabase', 'p-bundled-only']));
    });

    test('refresh() when remote throws leaves in-memory and cache unchanged', () async {
      final cache = SharedPrefsMasterContentCache();
      // First load succeeds — builds in-memory from Supabase.
      final original = _contentWith(['p-original']);
      await cache.write(original);

      final brokenRepo = RemoteCachedMasterContentRepositoryImpl(
        bundled: _FakeBundled(_contentWith(['p-bundled'])),
        remote: _FakeDataSource(shouldThrow: true),
        cache: cache,
      );
      // load() falls back to cache since Supabase throws.
      expect(_ids(await brokenRepo.load()), equals(['p-original']));
      await (brokenRepo as RefreshableRepository).refresh();

      expect(_ids(await brokenRepo.load()), equals(['p-original']));
      expect(_ids((await cache.read())!), equals(['p-original']));
    });

    test('concurrent refresh() calls result in only one network fetch', () async {
      final remote = _FakeDataSource(response: _contentWith(['p-fresh']));
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled']),
        remote: remote,
        cache: SharedPrefsMasterContentCache(),
      );
      await repo.load();
      final fetchCountAfterLoad = remote.fetchCount;

      await Future.wait([
        (repo as RefreshableRepository).refresh(),
        (repo as RefreshableRepository).refresh(),
      ]);

      expect(remote.fetchCount - fetchCountAfterLoad, 1);
    });

    test('after refresh(), load() returns updated merged content', () async {
      final repo = _makeRepo(
        bundled: _contentWith(['p-bundled-only']),
        remote: _FakeDataSource(response: _contentWith(['p-fresh'])),
        cache: SharedPrefsMasterContentCache(),
      );
      await repo.load();
      await (repo as RefreshableRepository).refresh();

      expect(_ids(await repo.load()),
          containsAll(['p-fresh', 'p-bundled-only']));
    });
  });
}
