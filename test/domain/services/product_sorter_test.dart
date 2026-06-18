import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/product_sorter.dart';

Category cat(String id, int order) => Category(id: id, name: id, order: order);

MasterProduct prod(
  String id,
  String categoryId, {
  int morningOrder = 1,
  int? eveningOrder,
}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: categoryId,
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

  group('ProductSorter.adminComparator', () {
    test('sorts by category order', () {
      final p1 = prod('p1', 'catB');
      final p2 = prod('p2', 'catA');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('breaks tie within same category by slot order', () {
      final p1 = prod('p1', 'catA', morningOrder: 3);
      final p2 = prod('p2', 'catA', morningOrder: 1);
      final p3 = prod('p3', 'catA', morningOrder: 2);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        slot: Slot.morning,
      );
      final sorted = [p1, p2, p3]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p3', 'p1']);
    });

    test('uses evening order when slot is evening', () {
      final p1 = prod('p1', 'catA', morningOrder: 1, eveningOrder: 3);
      final p2 = prod('p2', 'catA', morningOrder: 5, eveningOrder: 1);
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        slot: Slot.evening,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });

    test('categoryOverrides remaps product to different category for sorting', () {
      final p1 = prod('p1', 'catB'); // normally catB (order 2)
      final p2 = prod('p2', 'catA'); // catA (order 1)
      // Override p1 to sort as catA (order 1) — same category as p2
      // Within catA: p1 morningOrder=1, p2 morningOrder=1 → stable, both catA
      // Without override p1 sorts after p2; with override both are catA
      final p3 = prod('p3', 'catB');
      final cmp = ProductSorter.adminComparator(
        categories: [catA, catB],
        slot: Slot.morning,
        categoryOverrides: {'p1': 'catA'},
      );
      final sorted = [p3, p1, p2]..sort(cmp);
      // p2 and p1 both in catA (order 1), p3 in catB (order 2)
      expect(sorted.last.id, 'p3');
      expect(sorted.take(2).map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test('unknown category falls to end', () {
      final p1 = prod('p1', 'unknown');
      final p2 = prod('p2', 'catA');
      final cmp = ProductSorter.adminComparator(
        categories: [catA],
        slot: Slot.morning,
      );
      final sorted = [p1, p2]..sort(cmp);
      expect(sorted.map((p) => p.id), ['p2', 'p1']);
    });
  });
}
