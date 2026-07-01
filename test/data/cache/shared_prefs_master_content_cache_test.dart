import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_tracker/data/cache/master_content_cache.dart';
import 'package:skincare_tracker/data/cache/shared_prefs_master_content_cache.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';

MasterContent _minimal() => const MasterContent(
      products: [
        MasterProduct(
          id: 'p1',
          brand: 'COSRX',
          name: 'Snail Cream',
          categoryId: 'cat-1',
          isDeprecated: false,
        ),
      ],
      categories: [
        Category(id: 'cat-1', name: 'לחות', order: 1),
      ],
      rules: [],
      manifest: MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPrefsMasterContentCache', () {
    late MasterContentCache cache;

    setUp(() {
      cache = SharedPrefsMasterContentCache();
    });

    test('read returns null when no entry exists', () async {
      expect(await cache.read(), isNull);
    });

    test('write then read returns equivalent content', () async {
      final content = _minimal();
      await cache.write(content);
      final restored = await cache.read();
      expect(restored, equals(content));
    });

    test('read returns null after cache is cleared', () async {
      await cache.write(_minimal());
      await cache.clear();
      expect(await cache.read(), isNull);
    });

    test('read returns null when stored string is corrupt', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('master_content_cache_v2', 'NOT_VALID_JSON{{{{');
      expect(await cache.read(), isNull);
    });

    test('ignores legacy v1 cache and purges it on write', () async {
      final prefs = await SharedPreferences.getInstance();
      // A stale v1 payload (e.g. written before per-product subCategoryId).
      await prefs.setString('master_content_cache_v1', '{"stale":true}');

      // v1 must never be read by the current cache.
      expect(await cache.read(), isNull);

      // Writing current content purges the orphaned legacy key.
      await cache.write(_minimal());
      expect(prefs.containsKey('master_content_cache_v1'), isFalse);
      expect(await cache.read(), equals(_minimal()));
    });

    test('second write overwrites first', () async {
      final first = _minimal();
      const second = MasterContent(
        products: [
          MasterProduct(
            id: 'p2',
            brand: null,
            name: 'Other',
            categoryId: 'cat-1',
            isDeprecated: false,
          ),
        ],
        categories: [
          Category(id: 'cat-1', name: 'לחות', order: 1),
        ],
        rules: [],
        manifest: MasterListManifest(
          contentVersion: '1.0.1',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );
      await cache.write(first);
      await cache.write(second);
      final restored = await cache.read();
      expect(restored, equals(second));
    });
  });
}
