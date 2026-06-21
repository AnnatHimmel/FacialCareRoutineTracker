// Tests for REQ: UserCustomProduct.brand field and toMasterProduct() passthrough.
//
// RED phase: all tests FAIL because:
//   1. UserCustomProduct has no `brand` field.
//   2. toMasterProduct() does not forward `brand` to MasterProduct.

import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';

void main() {
  group('UserCustomProduct.brand', () {
    test(
        'should store a non-null brand when constructed with brand: "CeraVe"',
        () {
      // Given: a UserCustomProduct constructed with brand set
      final product = UserCustomProduct(
        id: 'ucp-1',
        name: 'Foaming Cleanser',
        categoryId: 'cat-cleansers',
        inMorning: true,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2024, 1, 1),
        brand: 'CeraVe',
      );

      // Then: brand is preserved
      expect(product.brand, 'CeraVe');
    });

    test('should store a non-null brand and return it', () {
      // Given
      final product = UserCustomProduct(
        id: 'ucp-2',
        name: 'Moisturiser',
        categoryId: 'cat-moisturisers',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
        brand: 'CeraVe',
      );

      // Then
      expect(product.brand, 'CeraVe');
    });

    test('should default brand to null when not provided', () {
      // Given
      final product = UserCustomProduct(
        id: 'ucp-3',
        name: 'Generic Serum',
        categoryId: 'cat-serums',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
      );

      // Then: omitting brand gives null
      expect(product.brand, isNull);
    });

    test('should preserve brand through copyWith when not overridden', () {
      // Given
      final original = UserCustomProduct(
        id: 'ucp-4',
        name: 'Toner',
        categoryId: 'cat-toners',
        inMorning: false,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        brand: 'Klairs',
      );

      // When: copyWith changes an unrelated field
      final copy = original.copyWith(name: 'Essence');

      // Then: brand survives
      expect(copy.brand, 'Klairs');
    });

    test('should allow copyWith to override brand', () {
      // Given
      final original = UserCustomProduct(
        id: 'ucp-5',
        name: 'SPF',
        categoryId: 'cat-sunscreens',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
        brand: 'Biore',
      );

      // When
      final updated = original.copyWith(brand: 'ISDIN');

      // Then
      expect(updated.brand, 'ISDIN');
    });

    test('should allow copyWith to clear brand to null', () {
      // Given
      final original = UserCustomProduct(
        id: 'ucp-6',
        name: 'Eye Cream',
        categoryId: 'cat-eye-care',
        inMorning: true,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        brand: 'Olay',
      );

      // When: explicitly pass null
      // ignore: avoid_redundant_argument_values
      final cleared = original.copyWith(brand: null);

      // Then
      expect(cleared.brand, isNull);
    });
  });

  group('UserCustomProduct.ingredients', () {
    test('should store a non-null ingredients value when constructed with it',
        () {
      final product = UserCustomProduct(
        id: 'ucp-ing-1',
        name: 'Niacinamide Serum',
        categoryId: 'cat-serums',
        inMorning: false,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua, Niacinamide, Zinc PCA',
      );
      expect(product.ingredients, 'Aqua, Niacinamide, Zinc PCA');
    });

    test('should default ingredients to null when not provided', () {
      final product = UserCustomProduct(
        id: 'ucp-ing-2',
        name: 'Plain Serum',
        categoryId: 'cat-serums',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
      );
      expect(product.ingredients, isNull);
    });

    test('should preserve ingredients through copyWith when not overridden',
        () {
      final original = UserCustomProduct(
        id: 'ucp-ing-3',
        name: 'Toner',
        categoryId: 'cat-toners',
        inMorning: true,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua, Glycerin',
      );
      final copy = original.copyWith(name: 'Essence');
      expect(copy.ingredients, 'Aqua, Glycerin');
    });

    test('should allow copyWith to override ingredients', () {
      final original = UserCustomProduct(
        id: 'ucp-ing-4',
        name: 'Serum',
        categoryId: 'cat-serums',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua',
      );
      final updated = original.copyWith(ingredients: 'Aqua, Niacinamide');
      expect(updated.ingredients, 'Aqua, Niacinamide');
    });

    test('should allow copyWith to clear ingredients to null', () {
      final original = UserCustomProduct(
        id: 'ucp-ing-5',
        name: 'Moisturiser',
        categoryId: 'cat-moisturisers',
        inMorning: true,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua, Shea Butter',
      );
      // ignore: avoid_redundant_argument_values
      final cleared = original.copyWith(ingredients: null);
      expect(cleared.ingredients, isNull);
    });
  });

  group('UserCustomProduct.toMasterProduct() ingredients splitting', () {
    test(
        'should split comma-separated ingredients into a trimmed List<String>',
        () {
      final custom = UserCustomProduct(
        id: 'ucp-ing-10',
        name: 'Serum',
        categoryId: 'cat-serums',
        inMorning: false,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua, Glycerin, Niacinamide',
      );
      final master = custom.toMasterProduct();
      expect(master.ingredients, ['Aqua', 'Glycerin', 'Niacinamide']);
    });

    test('should drop empty segments when splitting ingredients', () {
      final custom = UserCustomProduct(
        id: 'ucp-ing-11',
        name: 'Serum',
        categoryId: 'cat-serums',
        inMorning: false,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
        ingredients: 'Aqua,,Glycerin, ',
      );
      final master = custom.toMasterProduct();
      expect(master.ingredients, ['Aqua', 'Glycerin']);
    });

    test(
        'should produce an empty ingredients list when ingredients is null',
        () {
      final custom = UserCustomProduct(
        id: 'ucp-ing-12',
        name: 'Toner',
        categoryId: 'cat-toners',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
      );
      final master = custom.toMasterProduct();
      expect(master.ingredients, isEmpty);
    });
  });

  group('UserCustomProduct.toMasterProduct() brand passthrough', () {
    test(
        'should produce a MasterProduct with brand == "CeraVe" '
        'when UserCustomProduct has brand "CeraVe"', () {
      // Given
      final custom = UserCustomProduct(
        id: 'ucp-10',
        name: 'Foaming Cleanser',
        categoryId: 'cat-cleansers',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
        brand: 'CeraVe',
      );

      // When
      final master = custom.toMasterProduct();

      // Then
      expect(master, isA<MasterProduct>());
      expect(master.brand, 'CeraVe');
    });

    test(
        'should produce a MasterProduct with brand == null '
        'when UserCustomProduct has brand null', () {
      // Given
      final custom = UserCustomProduct(
        id: 'ucp-11',
        name: 'No-brand Toner',
        categoryId: 'cat-toners',
        inMorning: false,
        inEvening: true,
        isDaily: true,
        lastModified: DateTime(2026),
      );

      // When
      final master = custom.toMasterProduct();

      // Then
      expect(master.brand, isNull);
    });
  });
}
