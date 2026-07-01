import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/domain/services/routine_resolver.dart';

void main() {
  final boundary = DayBoundaryService();
  final resolver = RoutineResolver();

  // Helper to make a daily morning product
  MasterProduct daily(String id, int order) => MasterProduct(
        id: id,
        name: 'Product $id',
        categoryId: 'cat',
        isDeprecated: false,
        morningConfig: SlotConfig(order: order, frequencyRule: const DailyRule()),
      );

  // Helper to make a weekly-max evening product
  MasterProduct weekly(String id, int order, int max) => MasterProduct(
        id: id,
        name: 'Product $id',
        categoryId: 'cat',
        isDeprecated: false,
        eveningConfig: SlotConfig(
          order: order,
          frequencyRule: WeeklyMaxRule(max),
        ),
      );

  ProductSelection sel(String productId, Slot slot) => ProductSelection(
        id: 'sel-$productId',
        productId: productId,
        slot: slot,
        isSelected: true,
        lastModified: DateTime(2026),
      );

  WeekdaySchedule sched(String productId, Slot slot, Set<int> days) =>
      WeekdaySchedule(
        id: 'sched-$productId',
        productId: productId,
        slot: slot,
        weekdays: days,
        lastModified: DateTime(2026),
      );

  group('all-daily routine', () {
    test('returns all daily selected products in admin order', () {
      final p1 = daily('p1', 0);
      final p2 = daily('p2', 1);
      final p3 = daily('p3', 2);
      final result = resolver.resolve(
        date: DateTime(2026, 5, 15, 10), // 10am Friday
        slot: Slot.morning,
        allProducts: [p3, p1, p2],
        categories: [],
        selections: [sel('p1', Slot.morning), sel('p2', Slot.morning), sel('p3', Slot.morning)],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
      );
      expect(result.map((p) => p.id).toList(), ['p1', 'p2', 'p3']);
    });

    test('excludes unselected products', () {
      final p1 = daily('p1', 0);
      final p2 = daily('p2', 1);
      final result = resolver.resolve(
        date: DateTime(2026, 5, 15, 10),
        slot: Slot.morning,
        allProducts: [p1, p2],
        categories: [],
        selections: [sel('p1', Slot.morning)],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
      );
      expect(result.map((p) => p.id).toList(), ['p1']);
    });
  });

  group('occasional (WeeklyMax) products', () {
    test('includes occasional product on scheduled day', () {
      // Wednesday = Dart weekday 3; 3 % 7 = 3 (Wednesday in Sun=0 scheme)
      final p = weekly('p1', 0, 3);
      final wednesday = DateTime(2026, 5, 13, 10); // Wednesday
      final result = resolver.resolve(
        date: wednesday,
        slot: Slot.evening,
        allProducts: [p],
        categories: [],
        selections: [sel('p1', Slot.evening)],
        schedules: [sched('p1', Slot.evening, {3})], // Wednesday=3
        orderOverride: null,
        boundary: boundary,
      );
      expect(result.length, 1);
    });

    test('excludes occasional product on unscheduled day', () {
      final p = weekly('p1', 0, 3);
      final thursday = DateTime(2026, 5, 14, 10); // Thursday = 4
      final result = resolver.resolve(
        date: thursday,
        slot: Slot.evening,
        allProducts: [p],
        categories: [],
        selections: [sel('p1', Slot.evening)],
        schedules: [sched('p1', Slot.evening, {3})], // Wednesday only
        orderOverride: null,
        boundary: boundary,
      );
      expect(result.isEmpty, isTrue);
    });
  });

  group('order override', () {
    test('applies personal order override', () {
      final p1 = daily('p1', 0);
      final p2 = daily('p2', 1);
      final p3 = daily('p3', 2);
      final override = OrderOverride(
        id: 'ov',
        slot: Slot.morning,
        orderedProductIds: ['p3', 'p1', 'p2'],
        lastModified: DateTime(2026),
      );
      final result = resolver.resolve(
        date: DateTime(2026, 5, 15, 10),
        slot: Slot.morning,
        allProducts: [p1, p2, p3],
        categories: [],
        selections: [
          sel('p1', Slot.morning),
          sel('p2', Slot.morning),
          sel('p3', Slot.morning),
        ],
        schedules: [],
        orderOverride: override,
        boundary: boundary,
      );
      expect(result.map((p) => p.id).toList(), ['p3', 'p1', 'p2']);
    });
  });

  group('deprecated products', () {
    test('includes deprecated product if selected', () {
      const p = MasterProduct(
        id: 'p-dep',
        name: 'Old Product',
        categoryId: 'cat',
        isDeprecated: true,
        morningConfig: SlotConfig(order: 0, frequencyRule: DailyRule()),
      );
      final result = resolver.resolve(
        date: DateTime(2026, 5, 15, 10),
        slot: Slot.morning,
        allProducts: [p],
        categories: [],
        selections: [sel('p-dep', Slot.morning)],
        schedules: [],
        orderOverride: null,
        boundary: boundary,
      );
      expect(result.length, 1);
      expect(result.first.isDeprecated, isTrue);
    });
  });
}
