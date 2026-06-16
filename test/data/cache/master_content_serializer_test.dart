import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/cache/master_content_serializer.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';

MasterContent _makeContent({
  String? imageAsset,
  String? brand,
  FrequencyRule? morningFreq,
  FrequencyRule? eveningFreq,
}) {
  return MasterContent(
    products: [
      MasterProduct(
        id: 'p1',
        brand: brand,
        name: 'Snail Cream',
        imageAsset: imageAsset,
        comment: 'טוב מאוד',
        commentEn: 'Very good',
        categoryId: 'cat-1',
        morningConfig: morningFreq != null
            ? SlotConfig(order: 1, frequencyRule: morningFreq)
            : null,
        eveningConfig: eveningFreq != null
            ? SlotConfig(order: 2, frequencyRule: eveningFreq)
            : null,
        isDeprecated: false,
        addedInVersion: '1.0.0',
      ),
    ],
    categories: [
      const Category(
          id: 'cat-1', name: 'לחות', nameEn: 'Moisturizer', order: 1),
    ],
    rules: [
      const IncompatibilityRule(
        id: 'r1',
        entityA: RuleTarget(type: RuleTargetType.product, id: 'p1'),
        entityB: RuleTarget(type: RuleTargetType.product, id: 'p2'),
        scope: RuleScope.withinSlot,
        reason: 'לא להשתמש יחד',
        reasonEn: 'Do not use together',
      ),
    ],
    manifest: const MasterListManifest(
      contentVersion: '1.0.1',
      appVersion: '1.0.0',
      changelog: [
        ChangelogEntry(contentVersion: '1.0.1', changes: ['Added product']),
      ],
    ),
  );
}

void main() {
  group('MasterContentSerializer', () {
    test('round-trips DailyRule', () {
      final content = _makeContent(morningFreq: const DailyRule());
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored, equals(content));
    });

    test('round-trips WeeklyMaxRule', () {
      final content = _makeContent(eveningFreq: const WeeklyMaxRule(3));
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored, equals(content));
    });

    test('round-trips null imageAsset', () {
      final content = _makeContent(imageAsset: null);
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products.first.imageAsset, isNull);
    });

    test('round-trips https image URL', () {
      final content =
          _makeContent(imageAsset: 'https://example.supabase.co/prod.jpg');
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products.first.imageAsset,
          'https://example.supabase.co/prod.jpg');
    });

    test('round-trips null brand', () {
      final content = _makeContent(brand: null);
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products.first.brand, isNull);
    });

    test('round-trips non-null brand', () {
      final content = _makeContent(brand: 'Beauty of Joseon');
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products.first.brand, 'Beauty of Joseon');
    });

    test('fromCombinedJson with empty products list returns empty list', () {
      final content = MasterContent(
        products: [],
        categories: [],
        rules: [],
        manifest: const MasterListManifest(
          contentVersion: '1.0.0',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products, isEmpty);
    });

    test('fromCombinedJson with malformed frequency defaults to DailyRule', () {
      final content = _makeContent(morningFreq: const DailyRule());
      final json = MasterContentSerializer.toJson(content);
      // Corrupt the frequency type
      final products = json['products'] as List;
      final p = Map<String, dynamic>.from(products[0] as Map);
      final mc = Map<String, dynamic>.from(p['morningConfig'] as Map);
      mc['frequency'] = {'type': 'UNKNOWN_TYPE'};
      p['morningConfig'] = mc;
      products[0] = p;
      json['products'] = products;

      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(
          restored.products.first.morningConfig?.frequencyRule, isA<DailyRule>());
    });
  });

  group('ingredients field', () {
    test('parseProduct reads ingredients array into product.ingredients', () {
      final json = {
        'id': 'p2',
        'brand': null,
        'name': 'Serum',
        'imageAsset': null,
        'comment': {'he': null, 'en': null},
        'categoryId': 'cat-1',
        'isDeprecated': false,
        'addedInVersion': '1.0.0',
        'morningConfig': null,
        'eveningConfig': null,
        'ingredients': ['Niacinamide', 'Panthenol'],
      };
      final product = MasterContentSerializer.parseProduct(json);
      expect(product.ingredients, equals(['Niacinamide', 'Panthenol']));
    });

    test('parseProduct without ingredients field parses to empty list', () {
      final json = {
        'id': 'p3',
        'brand': null,
        'name': 'Toner',
        'imageAsset': null,
        'comment': {'he': null, 'en': null},
        'categoryId': 'cat-1',
        'isDeprecated': false,
        'addedInVersion': '1.0.0',
        'morningConfig': null,
        'eveningConfig': null,
        // no 'ingredients' key
      };
      final product = MasterContentSerializer.parseProduct(json);
      expect(product.ingredients, equals([]));
      expect(product.ingredients, isA<List<String>>());
    });

    test('round-trips ingredients through toJson/fromCombinedJson', () {
      final content = MasterContent(
        products: [
          const MasterProduct(
            id: 'p4',
            name: 'Moisturizer',
            categoryId: 'cat-1',
            isDeprecated: false,
            addedInVersion: '1.0.0',
            ingredients: ['Ceramide', 'Hyaluronic Acid'],
          ),
        ],
        categories: [
          const Category(
              id: 'cat-1', name: 'לחות', nameEn: 'Moisturizer', order: 1),
        ],
        rules: [],
        manifest: const MasterListManifest(
          contentVersion: '1.0.0',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );
      final json = MasterContentSerializer.toJson(content);
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(
          restored.products.first.ingredients, equals(['Ceramide', 'Hyaluronic Acid']));
    });
  });

  group('MasterContent equality', () {
    test('two identical MasterContent instances are equal', () {
      final a = _makeContent(brand: 'X', morningFreq: const DailyRule());
      final b = _makeContent(brand: 'X', morningFreq: const DailyRule());
      expect(a, equals(b));
    });

    test('different products make MasterContent unequal', () {
      final a = _makeContent(brand: 'X');
      final b = _makeContent(brand: 'Y');
      expect(a, isNot(equals(b)));
    });
  });
}
