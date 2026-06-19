import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';

void main() {
  group('SubCategory', () {
    const sub = SubCategory(
      id: 'sub-niacinamide',
      name: 'ניאצינמיד',
      nameEn: 'Niacinamide',
      categoryId: 'cat-serum',
      order: 14,
    );

    test('exposes its fields', () {
      expect(sub.id, 'sub-niacinamide');
      expect(sub.name, 'ניאצינמיד');
      expect(sub.categoryId, 'cat-serum');
      expect(sub.order, 14);
    });

    test('localizedName returns en for "en", he otherwise', () {
      expect(sub.localizedName('en'), 'Niacinamide');
      expect(sub.localizedName('he'), 'ניאצינמיד');
    });

    test('falls back to he when nameEn is null', () {
      const s = SubCategory(id: 's', name: 'שם', categoryId: 'c', order: 1);
      expect(s.localizedName('en'), 'שם');
    });

    test('equality by id, name, categoryId, order', () {
      const a = SubCategory(id: 's', name: 'n', categoryId: 'c', order: 1);
      const b = SubCategory(id: 's', name: 'n', categoryId: 'c', order: 1);
      const c = SubCategory(id: 's', name: 'n', categoryId: 'c', order: 2);
      expect(a, b);
      expect(a == c, isFalse);
    });

    test('copyWith overrides selected fields', () {
      final c = sub.copyWith(order: 99);
      expect(c.order, 99);
      expect(c.id, sub.id);
      expect(c.categoryId, sub.categoryId);
    });
  });
}
