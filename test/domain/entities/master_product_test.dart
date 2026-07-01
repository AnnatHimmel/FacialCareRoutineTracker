import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/cache/master_content_serializer.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';

void main() {
  group('MasterProduct.editable', () {
    test('defaults to false when constructed without editable', () {
      const product = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(product.editable, isFalse);
    });

    test('can be set to true via constructor', () {
      const product = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: true,
      );
      expect(product.editable, isTrue);
    });

    test('copyWith preserves editable when not overridden', () {
      const product = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: true,
      );
      final copy = product.copyWith(name: 'Other');
      expect(copy.editable, isTrue);
    });

    test('copyWith can override editable', () {
      const product = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: true,
      );
      final copy = product.copyWith(editable: false);
      expect(copy.editable, isFalse);
    });

    test('equality includes editable field', () {
      const a = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: true,
      );
      const b = MasterProduct(
        id: 'p1',
        name: 'Test Product',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: false,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('UserCustomProduct.toMasterProduct editable', () {
    test('toMasterProduct sets editable to true', () {
      final custom = UserCustomProduct(
        id: 'custom-1',
        name: 'My Product',
        categoryId: 'cat-1',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2024, 1, 1),
      );
      final master = custom.toMasterProduct();
      expect(master.editable, isTrue);
    });

  });

  group('MasterContentSerializer round-trip editable', () {
    MasterContent contentWith(MasterProduct product) => MasterContent(
          products: [product],
          categories: const [Category(id: 'cat-1', name: 'לחות', order: 1)],
          subcategories: const [],
          rules: const [],
          manifest: const MasterListManifest(
            contentVersion: '1.0.0',
            appVersion: '1.0.0',
            changelog: [],
          ),
        );

    test('editable: true survives serialize → deserialize round-trip', () {
      const product = MasterProduct(
        id: 'p1',
        name: 'Custom',
        categoryId: 'cat-1',
        isDeprecated: false,
        editable: true,
      );
      final json = MasterContentSerializer.toJson(contentWith(product));
      final restored = MasterContentSerializer.fromCombinedJson(json);
      expect(restored.products.first.editable, isTrue);
    });

    test('JSON without editable key deserializes to editable: false (back-compat)', () {
      // Simulate old JSON that has no 'editable' key at all
      final json = <String, dynamic>{
        'contentVersion': '1.0.0',
        'appVersion': '1.0.0',
        'changelog': <dynamic>[],
        'categories': [
          {'id': 'cat-1', 'name': {'he': 'לחות', 'en': null}, 'order': 1, 'icon': null},
        ],
        'subcategories': <dynamic>[],
        'products': [
          {
            'id': 'p1',
            'brand': null,
            'name': 'Old Product',
            'imageAsset': null,
            'comment': {'he': null, 'en': null},
            'categoryId': 'cat-1',
            'subCategoryId': null,
            'isDeprecated': false,
            'morningConfig': null,
            'eveningConfig': null,
            'ingredients': <dynamic>[],
            'barcodes': <dynamic>[],
            // intentionally no 'editable' key
          }
        ],
        'rules': <dynamic>[],
      };
      final content = MasterContentSerializer.fromCombinedJson(json);
      expect(content.products.first.editable, isFalse);
    });
  });
}
