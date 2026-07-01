import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';

void main() {
  group('MasterProduct.brand', () {
    test('non-null brand is stored and returned', () {
      const p = MasterProduct(
        id: 'p1',
        brand: 'COSRX',
        name: 'Snail 96',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(p.brand, 'COSRX');
    });

    test('null brand is stored and returned', () {
      const p = MasterProduct(
        id: 'p2',
        brand: null,
        name: 'Generic Cleansing Gel',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(p.brand, isNull);
    });

    test('brand participates in equality', () {
      const a = MasterProduct(
        id: 'p1',
        brand: 'COSRX',
        name: 'Snail 96',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      const b = MasterProduct(
        id: 'p1',
        brand: 'Other',
        name: 'Snail 96',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      const c = MasterProduct(
        id: 'p1',
        brand: 'COSRX',
        name: 'Snail 96',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(a == b, isFalse);
      expect(a == c, isTrue);
    });

    test('copyWith can change brand', () {
      const p = MasterProduct(
        id: 'p1',
        brand: 'COSRX',
        name: 'Snail 96',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(p.copyWith(brand: 'Other').brand, 'Other');
      expect(p.copyWith(brand: null).brand, isNull);
    });

    test('omitting brand defaults to null (backwards compat)', () {
      const p = MasterProduct(
        id: 'p1',
        name: 'Old Product',
        categoryId: 'cat-1',
        isDeprecated: false,
      );
      expect(p.brand, isNull);
    });
  });
}
