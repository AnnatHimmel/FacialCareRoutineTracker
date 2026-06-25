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
  String? name,
}) =>
    MasterProduct(
      id: id,
      name: name ?? id,
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

    test('mixed null/unknown sub-category falls through to slot order then id', () {
      // Subcategory comparison is skipped when either product has a null/unknown
      // sub-category (defensive fix for Bug 5: asymmetric Supabase data must not
      // invert the admin-intended config.order).
      // p1 has no sub-category, p2 has subA1, p3 has an unknown sub id.
      // All have morningOrder=1, so they tie on slotOrder and fall through to id.
      final p1 = prod('p1', 'catA');
      final p2 = prod('p2', 'catA', subCategoryId: 'subA1');
      final p3 = prod('p3', 'catA', subCategoryId: 'nope');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [p3, p2, p1]..sort(cmp);
      // When subcategory is skipped and slot orders all tie, products fall
      // through to id comparison: 'p1' < 'p2' < 'p3'.
      expect(sorted.map((p) => p.id), ['p1', 'p2', 'p3']);
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

    test('mixed subcategory (one known, one null) falls through to slot order', () {
      // Bug 5 regression: if one product has a known subCategoryId and another
      // has null (sentinel 9999), the subcategory tier must be SKIPPED entirely
      // so that the lower slot config.order wins.
      // cat-serum products: p_azelaic has config.order 6 and subCategoryId null,
      // p_niacinamide has config.order 9 and subCategoryId 'subA1'.
      // Expected: p_azelaic (order 6) sorts before p_niacinamide (order 9).
      final pAzelaic = prod('p_azelaic', 'catA', morningOrder: 6);          // no sub
      final pNiacinamide = prod('p_niacinamide', 'catA',
          subCategoryId: 'subA1', morningOrder: 9);
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        subcategories: allSubs,
        slot: Slot.morning,
      );
      final sorted = [pNiacinamide, pAzelaic]..sort(cmp);
      expect(sorted.first.id, 'p_azelaic',
          reason: 'lower config.order must win when subcategories are mixed null/known');
    });

    group('moisture lotion-before-cream weight rule', () {
      // Real category id used by the rule, plus its two known subcategories.
      final moisture = cat('cat-moisturizer', 6);
      final subSerum = sub('sub-moisture-serum', 'cat-moisturizer', 1);
      final subCream = sub('sub-moisturizer', 'cat-moisturizer', 2);
      final moistureSubs = [subSerum, subCream];

      test('lotion sorts before cream despite lower cream slot order', () {
        // Both moisture, same (null) subcategory. Cream has the lower numeric
        // order but the name rule must put the lotion first.
        final cream = prod('p-cream', 'cat-moisturizer',
            morningOrder: 1, name: 'Heartleaf Calming Cream');
        final lotion = prod('p-lotion', 'cat-moisturizer',
            morningOrder: 5, name: 'Cicapair Soothing Lotion');
        final cmp = ProductSorter.adminComparator(
          categories: [moisture],
          subcategories: moistureSubs,
          slot: Slot.morning,
        );
        final sorted = [cream, lotion]..sort(cmp);
        expect(sorted.map((p) => p.id), ['p-lotion', 'p-cream']);
      });

      test('real-data shape: lotion first, creams keep relative slot order', () {
        // Mirrors the bundled data: all subCategoryId null.
        final lotion = prod('prod-018', 'cat-moisturizer',
            morningOrder: 14, name: 'Cicapair Repair Treatment Lotion');
        final cream1 = prod('prod-027', 'cat-moisturizer',
            morningOrder: 15, name: 'Ectoin Sensitivity Repair Cream');
        final cream2 = prod('prod-031', 'cat-moisturizer',
            morningOrder: 16, name: 'Dynasty Cream');
        final cmp = ProductSorter.adminComparator(
          categories: [moisture],
          subcategories: moistureSubs,
          slot: Slot.morning,
        );
        final sorted = [cream2, cream1, lotion]..sort(cmp);
        expect(sorted.map((p) => p.id), ['prod-018', 'prod-027', 'prod-031']);
      });

      test('rule is scoped to moisture only — other categories ignore names', () {
        // Same lotion/cream pairing in catA: lower slot order must still win.
        final cream = prod('p-cream', 'catA',
            morningOrder: 1, name: 'Some Cream');
        final lotion = prod('p-lotion', 'catA',
            morningOrder: 5, name: 'Some Lotion');
        final cmp = ProductSorter.adminComparator(
          categories: [catA, moisture],
          subcategories: [...allSubs, ...moistureSubs],
          slot: Slot.morning,
        );
        final sorted = [lotion, cream]..sort(cmp);
        expect(sorted.map((p) => p.id), ['p-cream', 'p-lotion']);
      });

      test('different known subcategory still decided by subcategory order', () {
        // Lotion in the cream subcategory (order 2), cream in the serum
        // subcategory (order 1). The name rule must NOT fire across groups —
        // subcategory order wins, so the serum-group cream comes first.
        final lotion = prod('p-lotion', 'cat-moisturizer',
            subCategoryId: 'sub-moisturizer', morningOrder: 1, name: 'X Lotion');
        final cream = prod('p-cream', 'cat-moisturizer',
            subCategoryId: 'sub-moisture-serum', morningOrder: 9, name: 'X Cream');
        final cmp = ProductSorter.adminComparator(
          categories: [moisture],
          subcategories: moistureSubs,
          slot: Slot.morning,
        );
        final sorted = [lotion, cream]..sort(cmp);
        expect(sorted.map((p) => p.id), ['p-cream', 'p-lotion']);
      });

      test('moisture product with neither keyword is unaffected (slot order)', () {
        final serum = prod('p-serum', 'cat-moisturizer',
            morningOrder: 1, name: 'Hydrating Serum');
        final cream = prod('p-cream', 'cat-moisturizer',
            morningOrder: 5, name: 'Rich Cream');
        final cmp = ProductSorter.adminComparator(
          categories: [moisture],
          subcategories: moistureSubs,
          slot: Slot.morning,
        );
        final sorted = [cream, serum]..sort(cmp);
        expect(sorted.map((p) => p.id), ['p-serum', 'p-cream']);
      });
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
