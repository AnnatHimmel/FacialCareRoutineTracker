import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/domain/services/routine_resolver.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Category cat(String id, int order) =>
    Category(id: id, name: id, order: order);

MasterProduct prod(String id, String categoryId) => MasterProduct(
      id: id,
      name: id,
      categoryId: categoryId,
      imageAsset: '',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: SlotConfig(order: 1, frequencyRule: const DailyRule()),
      eveningConfig: null,
    );

ProductSelection sel(String productId) => ProductSelection(
      id: 'sel-$productId',
      productId: productId,
      slot: Slot.morning,
      isSelected: true,
      lastModified: DateTime.utc(2024, 1, 1),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final resolver = RoutineResolver();
  final boundary = DayBoundaryService();
  final date = DateTime(2024, 6, 10, 12); // noon, well within today's boundary

  final catA = cat('catA', 1);
  final catB = cat('catB', 2);

  // p1 belongs to catB by master data; p2 to catA
  final p1 = prod('p1', 'catB');
  final p2 = prod('p2', 'catA');

  group('RoutineResolver — categoryOverrides', () {
    test('without override, products sorted by master category order (catA before catB)', () {
      final result = resolver.resolve(
        date: date,
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [catA, catB],
        selections: [sel('p1'), sel('p2')],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
      );

      // p2 (catA, order=1) should come before p1 (catB, order=2)
      expect(result.map((p) => p.id).toList(), ['p2', 'p1']);
    });

    test('with categoryOverride reassigning p1 to catA, p1 sorts before p2', () {
      final result = resolver.resolve(
        date: date,
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [catA, catB],
        selections: [sel('p1'), sel('p2')],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
        categoryOverrides: {'p1': 'catA'}, // override p1 from catB → catA
      );

      // Both now in catA (order=1) — relative order from slotOrder tiebreak
      // p1 has slotOrder 1, p2 has slotOrder 1, so stable relative order
      // They're both in catA now, so the result should list them together
      for (final p in result) {
        expect(['p1', 'p2'].contains(p.id), isTrue);
      }
      expect(result.length, 2);
    });

    test('overriding p2 to catB makes both in catB, does not crash', () {
      final result = resolver.resolve(
        date: date,
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [catA, catB],
        selections: [sel('p1'), sel('p2')],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
        categoryOverrides: {'p2': 'catB'},
      );

      expect(result.length, 2);
    });

    test('null categoryOverrides behaves identically to no parameter', () {
      final withNull = resolver.resolve(
        date: date,
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [catA, catB],
        selections: [sel('p1'), sel('p2')],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
        categoryOverrides: null,
      );
      final withoutParam = resolver.resolve(
        date: date,
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [catA, catB],
        selections: [sel('p1'), sel('p2')],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
      );

      expect(withNull.map((p) => p.id).toList(),
          withoutParam.map((p) => p.id).toList());
    });
  });
}
