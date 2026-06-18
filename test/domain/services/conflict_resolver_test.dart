import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/conflict_resolver.dart';

// ── Helpers ─────────────────────────────────────────────────────────────────

MasterProduct _product(
  String id, {
  SlotConfig? morning,
  SlotConfig? evening,
}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: morning,
      eveningConfig: evening,
    );

const _daily = SlotConfig(order: 1, frequencyRule: DailyRule());
SlotConfig _capped(int n) =>
    SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(n));

WeekdaySchedule _sched(String productId, Slot slot, Set<int> days) =>
    WeekdaySchedule(
      id: 's-$productId-${slot.name}',
      productId: productId,
      slot: slot,
      weekdays: days,
      lastModified: DateTime(2024, 1, 1),
    );

const _allDays = {0, 1, 2, 3, 4, 5, 6};

void main() {
  final resolver = ConflictResolver();

  group('ConflictResolver — slot separation', () {
    test(
        'bi-slot product moves to the other slot when the other product is slot-locked',
        () {
      // Argireline: bi-slot (both AM + PM). VitC: AM-locked (morning only).
      // Conflict is in the morning. Argireline (the flexible one) should move
      // to the evening; VitC keeps its morning placement. No frequency loss.
      final argireline = _product('argireline', morning: _daily, evening: _daily);
      final vitC = _product('vitC', morning: _daily);

      final schedules = [
        _sched('argireline', Slot.morning, _allDays),
        _sched('argireline', Slot.evening, _allDays),
        _sched('vitC', Slot.morning, _allDays),
      ];

      final result = resolver.resolve(
        productA: argireline,
        productB: vitC,
        slot: Slot.morning,
        schedules: schedules,
      );

      expect(result.isPartial, isFalse);

      // Applying the resolution must clear Argireline from the morning so the
      // conflict no longer holds (both present in morning).
      final after = applyMutations(schedules, result.mutations);
      final argMorning = _daysFor(after, 'argireline', Slot.morning);
      expect(argMorning, isEmpty,
          reason: 'Argireline should no longer be in the morning slot');

      // Argireline keeps a full evening schedule — no frequency loss.
      final argEvening = _daysFor(after, 'argireline', Slot.evening);
      expect(argEvening, equals(_allDays));

      // VitC untouched in the morning.
      final vitMorning = _daysFor(after, 'vitC', Slot.morning);
      expect(vitMorning, equals(_allDays));
    });

    test('resolution is reversible — inverse restores the original state', () {
      final argireline = _product('argireline', morning: _daily, evening: _daily);
      final vitC = _product('vitC', morning: _daily);

      final schedules = [
        _sched('argireline', Slot.morning, _allDays),
        _sched('argireline', Slot.evening, _allDays),
        _sched('vitC', Slot.morning, _allDays),
      ];

      final result = resolver.resolve(
        productA: argireline,
        productB: vitC,
        slot: Slot.morning,
        schedules: schedules,
      );

      final after = applyMutations(schedules, result.mutations);
      final restored = applyMutations(after, result.inverse);

      expect(_daysFor(restored, 'argireline', Slot.morning), equals(_allDays));
      expect(_daysFor(restored, 'argireline', Slot.evening), equals(_allDays));
      expect(_daysFor(restored, 'vitC', Slot.morning), equals(_allDays));
    });

    test(
        'undo for daily product with no prior schedule restores to all-days '
        '(so RoutineResolver sees it as daily again)', () {
      // Real-world case: Argireline was selected but never given an explicit
      // schedule row (daily products don't need one). After conflict-resolver
      // slot-sep writes an empty schedule, the undo must restore to all-days,
      // not an empty set — otherwise the product stays suppressed forever.
      final argireline = _product('argireline', morning: _daily, evening: _daily);
      final vitC = _product('vitC', morning: _daily);

      // No pre-existing schedule row for argireline in morning.
      final schedules = [
        _sched('argireline', Slot.evening, _allDays),
        _sched('vitC', Slot.morning, _allDays),
      ];

      final result = resolver.resolve(
        productA: argireline,
        productB: vitC,
        slot: Slot.morning,
        schedules: schedules,
      );

      // Forward: argireline must be removed from morning.
      final after = applyMutations(schedules, result.mutations);
      expect(_daysFor(after, 'argireline', Slot.morning), isEmpty);

      // Undo: argireline must come back to morning — not left as empty.
      final restored = applyMutations(after, result.inverse);
      expect(
        _daysFor(restored, 'argireline', Slot.morning),
        equals(_allDays),
        reason: 'Undo must restore a daily product to all-days, '
            'not an empty schedule that would keep it suppressed',
      );
    });
  });

  group('ConflictResolver — day separation', () {
    test(
        'capped product anchors its N nights; daily product takes the remaining days',
        () {
      // Retinoid: PM daily. Acids: PM cap 3. Both evening-locked, conflict in PM.
      // Day separation: acids keep 3 nights, retinoid takes the other 4.
      final retinoid = _product('retinoid', evening: _daily);
      final acids = _product('acids', evening: _capped(3));

      final schedules = [
        _sched('retinoid', Slot.evening, _allDays),
        _sched('acids', Slot.evening, {0, 1, 2}),
      ];

      final result = resolver.resolve(
        productA: retinoid,
        productB: acids,
        slot: Slot.evening,
        schedules: schedules,
      );

      expect(result.isPartial, isFalse);

      final after = applyMutations(schedules, result.mutations);
      final acidDays = _daysFor(after, 'acids', Slot.evening);
      final retinoidDays = _daysFor(after, 'retinoid', Slot.evening);

      // Acids keep their full cap of 3 nights.
      expect(acidDays.length, equals(3));
      // Retinoid fills the remaining 4 nights.
      expect(retinoidDays.length, equals(4));
      // No overlap → conflict resolved.
      expect(acidDays.intersection(retinoidDays), isEmpty);
      // Together they cover the week.
      expect(acidDays.union(retinoidDays), equals(_allDays));
    });

    test('unfittable case yields a partial, flagged resolution', () {
      // Two capped PM products that each need 5 nights → 10 > 7. They cannot be
      // fully separated. Result must be flagged partial but still reduce overlap.
      final acidsA = _product('acidsA', evening: _capped(5));
      final acidsB = _product('acidsB', evening: _capped(5));

      final schedules = [
        _sched('acidsA', Slot.evening, {0, 1, 2, 3, 4}),
        _sched('acidsB', Slot.evening, {0, 1, 2, 3, 4}),
      ];

      final result = resolver.resolve(
        productA: acidsA,
        productB: acidsB,
        slot: Slot.evening,
        schedules: schedules,
      );

      expect(result.isPartial, isTrue,
          reason: 'cannot fully separate two 5-night products in a 7-day week');

      final after = applyMutations(schedules, result.mutations);
      final aDays = _daysFor(after, 'acidsA', Slot.evening);
      final bDays = _daysFor(after, 'acidsB', Slot.evening);
      // Best partial separation: overlap is smaller than the original 5.
      expect(aDays.intersection(bDays).length, lessThan(5));
    });

    test('tiebreak — when both are equally flexible the second product yields',
        () {
      // Two daily PM products (equally flexible). The second (productB) should
      // be the one whose days get reduced.
      final first = _product('first', evening: _daily);
      final second = _product('second', evening: _daily);

      final schedules = [
        _sched('first', Slot.evening, _allDays),
        _sched('second', Slot.evening, _allDays),
      ];

      final result = resolver.resolve(
        productA: first,
        productB: second,
        slot: Slot.evening,
        schedules: schedules,
      );

      final after = applyMutations(schedules, result.mutations);
      final firstDays = _daysFor(after, 'first', Slot.evening);
      final secondDays = _daysFor(after, 'second', Slot.evening);

      // No overlap.
      expect(firstDays.intersection(secondDays), isEmpty);
      // The first (anchor) keeps at least as many days as the second (yielder).
      expect(firstDays.length, greaterThanOrEqualTo(secondDays.length));
    });
  });

  group('ConflictResolver — description', () {
    test('resolution carries a non-empty human description', () {
      final argireline = _product('argireline', morning: _daily, evening: _daily);
      final vitC = _product('vitC', morning: _daily);

      final result = resolver.resolve(
        productA: argireline,
        productB: vitC,
        slot: Slot.morning,
        schedules: [
          _sched('argireline', Slot.morning, _allDays),
          _sched('argireline', Slot.evening, _allDays),
          _sched('vitC', Slot.morning, _allDays),
        ],
      );

      expect(result.description, isNotEmpty);
    });
  });
}

// ── Test-local helpers that exercise the public API ─────────────────────────

Set<int> _daysFor(List<WeekdaySchedule> schedules, String productId, Slot slot) {
  final s = schedules
      .where((s) => s.productId == productId && s.slot == slot)
      .firstOrNull;
  return s?.weekdays ?? <int>{};
}
