import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/domain/services/routine_resolver.dart';

// Monday 2024-06-10 noon — dayOfWeek = 1 (Mon=1…Sun=7 → Mon%7=1)
const _date = '2024-06-10';
final _monday = DateTime(2024, 6, 10, 12);
final _boundary = DayBoundaryService();
final _resolver = RoutineResolver();

Category _cat(String id) => Category(id: id, name: id, order: 1);

MasterProduct _dailyBiSlot(String id) => MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat-serum',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterProduct _dailyMorningOnly(String id) => MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat-serum',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      eveningConfig: null,
    );

ProductSelection _morningSelection(String productId) => ProductSelection(
      id: 'sel-$productId',
      productId: productId,
      slot: Slot.morning,
      isSelected: true,
      lastModified: DateTime.utc(2024, 1, 1),
    );

WeekdaySchedule _scheduleWithDays(
  String productId,
  Slot slot,
  Set<int> days,
) =>
    WeekdaySchedule(
      id: 'sched-$productId',
      productId: productId,
      slot: slot,
      weekdays: days,
      lastModified: DateTime.utc(2024, 1, 1),
    );

const _cats = <Category>[];

void main() {
  group('RoutineResolver — daily product + explicit schedule', () {
    test(
        'daily product with empty schedule row is excluded (conflict-resolver suppression)',
        () {
      // This is the key fix: when the ConflictResolver runs slot-separation on
      // a daily product it writes WeekdaySchedule{weekdays: {}}. The
      // RoutineResolver must honour this as "excluded from this slot".
      final argireline = _dailyBiSlot('argireline');

      final result = _resolver.resolve(
        date: _monday,
        slot: Slot.morning,
        allProducts: [argireline],
        categories: _cats,
        selections: [_morningSelection('argireline')],
        schedules: [
          _scheduleWithDays('argireline', Slot.morning, const <int>{}), // empty!
        ],
        orderOverride: null,
        boundary: _boundary,
      );

      expect(result, isEmpty,
          reason: 'Daily product with an explicit empty schedule must not '
              'appear — this is how the conflict resolver suppresses it');
    });

    test(
        'daily product with NO schedule row still appears every day (unchanged default)',
        () {
      final argireline = _dailyBiSlot('argireline');

      final result = _resolver.resolve(
        date: _monday,
        slot: Slot.morning,
        allProducts: [argireline],
        categories: _cats,
        selections: [_morningSelection('argireline')],
        schedules: const [], // no schedule row at all
        orderOverride: null,
        boundary: _boundary,
      );

      expect(result, hasLength(1),
          reason: 'Daily product with no schedule row must still appear');
    });

    test(
        'daily product with non-empty schedule row still appears (schedule not suppressed)',
        () {
      final argireline = _dailyBiSlot('argireline');

      final result = _resolver.resolve(
        date: _monday,
        slot: Slot.morning,
        allProducts: [argireline],
        categories: _cats,
        selections: [_morningSelection('argireline')],
        schedules: [
          _scheduleWithDays('argireline', Slot.morning, {0, 1, 2, 3, 4, 5, 6}),
        ],
        orderOverride: null,
        boundary: _boundary,
      );

      expect(result, hasLength(1),
          reason: 'Daily product with all-days schedule must still appear');
    });

    test(
        'daily product with partial schedule is hidden on a day NOT in the set',
        () {
      // A daily product the user (or auto-fix split) restricted to specific
      // weekdays must honour those days — not appear on every day. {3,5} =
      // Wed/Fri, so on Monday (dayOfWeek 1) it must NOT appear.
      final argireline = _dailyBiSlot('argireline');

      final result = _resolver.resolve(
        date: _monday, // dayOfWeek 1 — not in {3,5}
        slot: Slot.morning,
        allProducts: [argireline],
        categories: _cats,
        selections: [_morningSelection('argireline')],
        schedules: [
          _scheduleWithDays('argireline', Slot.morning, {3, 5}),
        ],
        orderOverride: null,
        boundary: _boundary,
      );

      expect(result, isEmpty,
          reason: 'Daily product restricted to {Wed,Fri} must not appear on '
              'Monday');
    });

    test(
        'daily product with partial schedule appears on a day IN the set',
        () {
      final argireline = _dailyBiSlot('argireline');
      final wednesday = DateTime(2024, 6, 12, 12); // dayOfWeek 3

      final result = _resolver.resolve(
        date: wednesday,
        slot: Slot.morning,
        allProducts: [argireline],
        categories: _cats,
        selections: [_morningSelection('argireline')],
        schedules: [
          _scheduleWithDays('argireline', Slot.morning, {3, 5}),
        ],
        orderOverride: null,
        boundary: _boundary,
      );

      expect(result, hasLength(1),
          reason: 'Daily product restricted to {Wed,Fri} must appear on '
              'Wednesday');
    });

    // Regression: root_providers passes midnight DateTimes (from parseDate).
    // Midnight has hour=0 which is < 6, so a naive re-application of
    // effectiveDate() inside the resolver would shift midnight Saturday back
    // to Friday — causing Saturday (day=6) to match Friday (day=5) schedules.
    group('midnight datetime regression (day must not shift to previous day)', () {
      // 2024-06-15 is a Saturday; DateTime(2024, 6, 15) = midnight Saturday.
      final midnightSaturday = DateTime(2024, 6, 15); // hour=0, weekday=6

      test('Saturday midnight — product scheduled ONLY on Saturday appears', () {
        final product = _dailyBiSlot('p');
        final result = _resolver.resolve(
          date: midnightSaturday,
          slot: Slot.morning,
          allProducts: [product],
          categories: _cats,
          selections: [_morningSelection('p')],
          schedules: [_scheduleWithDays('p', Slot.morning, {6})], // Sat only
          orderOverride: null,
          boundary: _boundary,
        );
        expect(result, hasLength(1),
            reason: 'Product on Saturday (day=6) must appear on Saturday; '
                'midnight must not be re-interpreted as the previous day');
      });

      test('Saturday midnight — product scheduled ONLY on Sun/Tue/Thu does NOT appear', () {
        final product = _dailyBiSlot('p');
        final result = _resolver.resolve(
          date: midnightSaturday,
          slot: Slot.morning,
          allProducts: [product],
          categories: _cats,
          selections: [_morningSelection('p')],
          schedules: [_scheduleWithDays('p', Slot.morning, {0, 2, 4})],
          orderOverride: null,
          boundary: _boundary,
        );
        expect(result, isEmpty,
            reason: 'Product on Sun/Tue/Thu must NOT appear on Saturday');
      });
    });
  });
}
