import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/product_sorter.dart';

Category cat(String id, int order) => Category(id: id, name: id, order: order);

SubCategory sub(String id, String categoryId, int order) =>
    SubCategory(id: id, name: id, categoryId: categoryId, order: order);

MasterProduct prod(
  String id,
  String categoryId, {
  String? subCategoryId,
  int morningOrder = 1,
  int? eveningOrder,
}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: SlotConfig(order: morningOrder, frequencyRule: const DailyRule()),
      eveningConfig: eveningOrder == null
          ? null
          : SlotConfig(order: eveningOrder, frequencyRule: const DailyRule()),
    );

void main() {
  final catA = cat('catA', 1);
  final catB = cat('catB', 2);

  // Sub-categories within catA
  final subA1 = sub('subA1', 'catA', 1);
  final subA2 = sub('subA2', 'catA', 2);
  // Sub-category within catB
  final subB1 = sub('subB1', 'catB', 1);

  final allSubs = [subA1, subA2, subB1];

  group('ProductSorter.adminComparator', () {
    test('sorts by category order (phase)', () {
      final p1 = prod('p1', 'catB');
      final p2 = prod('p2', 'catA');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('sorts by sub-category order within the same category', () {
      // Both in catA; p1 in subA2 (order 2), p2 in subA1 (order 1).
      final p1 = prod('p1', 'catA', subCategoryId: 'subA2');
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('null/unknown sub-category sorts last within its category', () {
      // p1 has no sub-category, p2 has subA1, p3 has an unknown sub id.
      final p1 = prod('p1', 'catA');
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1');
      final p3 = prod('p3', 'catA', subCategoryId: 'nope');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2, p3]..sort(cmp);
      // p2 (known sub) first; p1 and p3 both sentinel-last.
      expect(sorted.first.id, 'p2');
      expect(sorted.skip(1).map((p) => p.id), containsAll(['p1', 'p3']));
    });

    test('breaks tie within same sub-category by slot order', () {
      final p1 = prod('p1', 'catA', subCategoryId: 'subA1', morningOrder: 3);
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1', morningOrder: 1);
      final p3 = prod('p3', 'catA', subCategoryId: 'subA1', morningOrder: 2);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2, p3]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p3', 'p1']);
    });

    test('uses evening order when slot is evening', () {
      final p1 = prod('p1', 'catA',
          subCategoryId: 'subA1', morningOrder: 1, eveningOrder: 3);
      final p2 = prod('p2', 'catA',
          subCategoryId: 'subA1', morningOrder: 5, eveningOrder: 1);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        subcategories: allSubs,
        slot: Slot.evening,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('categoryOverrides remaps product to different category for sorting',
        () {
      final p1 = prod('p1', 'catB', subCategoryId: 'subB1');
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1');
      final p3 = prod('p3', 'catB', subCategoryId: 'subB1');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
        categoryOverrides: {'p1': 'catA'},
      );
      final sorted = [p3, p1, p2]..sort(cmp);
      // p1 overridden to catA; p3 stays in catB → last.
      expect(sorted.last.id, 'p3');
      expect(sorted.take(2).map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('subCategoryOverrides remaps product to different sub for sorting', () {
      // p1 naturally subA2 (order 2), p2 subA1 (order 1).
      // Override p1 → subA1 has no effect on relative order beyond slot;
      // instead override p2 → subA2 so p1 (subA2 order 2) now precedes? No:
      // override p1 → subA1 (order 1) so it precedes p2's subA2.
      final p1 = prod('p1', 'catA', subCategoryId: 'subA2', morningOrder: 1);
      final p2 = prod('p2', 'catA', subCategoryId: 'subA2', morningOrder: 1);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        subcategories: allSubs,
        slot: Slot.morning,
        subCategoryOverrides: {'p1': 'subA1'},
      );
      final sorted = [p2, p1]..sort(cmp);
      // p1 overridden to subA1 (order 1) → before p2 in subA2 (order 2).
      expect(sorted.map((p) => p.id), ['p1', 'p2']);
    });

    test('unknown category falls to end', () {
      final p1 = prod('p1', 'unknown');
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1');
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('breaks final tie by product id', () {
      // Same category, same sub, same slot order → fall back to id.
      final p1 = prod('zzz', 'catA', subCategoryId: 'subA1', morningOrder: 1);
      final p2 = prod('aaa', 'catA', subCategoryId: 'subA1', morningOrder: 1);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['aaa', 'zzz']);
    });
  });
}
