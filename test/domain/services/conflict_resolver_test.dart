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
  const resolver = ConflictResolver();

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

    test(
        'acid (cap 3, no prior schedule) spreads to {0,2,4}; '
        'retinoid (daily, no prior schedule) fills remaining {1,3,5,6}', () {
      // Mirrors the real-world startup auto-fix scenario: user has selected a
      // retinoid (daily, evening-only) and an exfoliating acid (weeklyMax:3,
      // evening-only) but neither product has a DB schedule row yet.
      // Expected: acid anchors at 3 evenly-spread nights {0,2,4}; retinoid
      // fills the remaining 4 nights {1,3,5,6}. No overlap.
      //
      // IncompatibilityChecker produces ConflictInfo with
      //   productA = retinoid  (cat-retinoid matches rule entityA)
      //   productB = acid      (cat-exfoliate matches rule entityB)
      final retinoid = _product('retinoid', evening: _daily);
      final acid = _product('acid', evening: _capped(3));

      const schedules = <WeekdaySchedule>[];

      final result = resolver.resolve(
        productA: retinoid,
        productB: acid,
        slot: Slot.evening,
        schedules: schedules,
      );

      expect(result.isPartial, isFalse);

      final after = applyMutations(schedules, result.mutations);
      final acidDays = _daysFor(after, 'acid', Slot.evening);
      final retinoidDays = _daysFor(after, 'retinoid', Slot.evening);

      expect(acidDays, equals({0, 2, 4}),
          reason:
              'acid with cap 3 and no prior schedule must spread evenly to {0,2,4}');
      expect(retinoidDays, equals({1, 3, 5, 6}),
          reason: 'daily retinoid must fill the 4 remaining evenings');
      expect(acidDays.intersection(retinoidDays), isEmpty,
          reason: 'acid and retinoid must not share any evening');
    });

    test(
        'undo for daily retinoid with no prior schedule restores to all 7 evenings',
        () {
      // Same starting state as the previous test. After applying the forward fix
      // and then the inverse, the retinoid must be back on all 7 evenings —
      // not left on the 4 restricted nights or on an empty set.
      final retinoid = _product('retinoid', evening: _daily);
      final acid = _product('acid', evening: _capped(3));

      const schedules = <WeekdaySchedule>[];

      final result = resolver.resolve(
        productA: retinoid,
        productB: acid,
        slot: Slot.evening,
        schedules: schedules,
      );

      final after = applyMutations(schedules, result.mutations);
      final restored = applyMutations(after, result.inverse);

      expect(
        _daysFor(restored, 'retinoid', Slot.evening),
        equals(_allDays),
        reason: 'Undo must restore a daily retinoid (no prior row) to all 7 evenings, '
            'not leave it on the restricted set',
      );
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

  group('ConflictResolver — three-product scenario', () {
    // Mirrors real data: Argireline (bi-slot daily), VitC (AM-only daily),
    // BHA salicylic (PM-only, cap 3/week). Rule: Argireline × VitC conflict
    // in morning → slot-sep moves Argireline to evening. No rule between
    // Argireline and BHA, so BHA is untouched.
    test(
        'argireline moves to evening-only, vitC stays every morning, '
        'BHA stays at 3 evenings — all unrelated schedules untouched', () {
      final argireline =
          _product('argireline', morning: _daily, evening: _daily);
      final vitC = _product('vitC', morning: _daily);

      var schedules = [
        _sched('argireline', Slot.morning, _allDays),
        _sched('argireline', Slot.evening, _allDays),
        _sched('vitC', Slot.morning, _allDays),
        _sched('bha', Slot.evening, {0, 1, 2}),
      ];

      // Resolve the only conflict: Argireline × VitC in morning.
      final resolution = resolver.resolve(
        productA: argireline,
        productB: vitC,
        slot: Slot.morning,
        schedules: schedules,
      );
      schedules = applyMutations(schedules, resolution.mutations);

      // Argireline leaves morning entirely.
      expect(
        _daysFor(schedules, 'argireline', Slot.morning),
        isEmpty,
        reason: 'Argireline must be removed from morning after slot-sep',
      );

      // Argireline keeps full evening schedule — no frequency loss.
      expect(
        _daysFor(schedules, 'argireline', Slot.evening),
        equals(_allDays),
        reason: 'Argireline must keep all 7 evenings',
      );

      // VitC is untouched — it was the slot-locked anchor.
      expect(
        _daysFor(schedules, 'vitC', Slot.morning),
        equals(_allDays),
        reason: 'VitC must stay in morning every day',
      );

      // BHA is untouched — no conflict rule targets Argireline×BHA.
      expect(
        _daysFor(schedules, 'bha', Slot.evening),
        equals({0, 1, 2}),
        reason: 'BHA must remain at its 3-evening schedule',
      );
      expect(
        _daysFor(schedules, 'bha', Slot.evening).length,
        equals(3),
      );
    });
  });

  group('ConflictResolver — multi-product day separation', () {
    // Real-world scenario: three retinoid products (all daily, evening-only)
    // conflict with BHA (cap 3, evening-only) via cat-retinoid × cat-exfoliate.
    // After resolving all three conflicts in sequence, BHA should land on 3
    // non-consecutive days and each retinoid should fill the remaining days.
    test(
        'BHA spreads across 3 non-consecutive days; three retinoids '
        'fill the remaining days without overlapping BHA', () {
      final retinol = _product('retinol', evening: _daily);
      final retinal = _product('retinal', evening: _daily);
      final bakuchiol = _product('bakuchiol', evening: _daily);
      final bha = _product('bha', evening: _capped(3));

      var schedules = <WeekdaySchedule>[];

      // Resolve conflicts in sequence, updating the schedule snapshot after each.
      for (final pair in [
        (productA: retinol, productB: bha),
        (productA: retinal, productB: bha),
        (productA: bakuchiol, productB: bha),
      ]) {
        final resolution = resolver.resolve(
          productA: pair.productA,
          productB: pair.productB,
          slot: Slot.evening,
          schedules: schedules,
        );
        schedules = applyMutations(schedules, resolution.mutations);
      }

      final bhaDays = _daysFor(schedules, 'bha', Slot.evening);
      final retinolDays = _daysFor(schedules, 'retinol', Slot.evening);
      final retinalDays = _daysFor(schedules, 'retinal', Slot.evening);
      final bakuchiolDays = _daysFor(schedules, 'bakuchiol', Slot.evening);

      // BHA must have exactly its capped 3 days.
      expect(bhaDays.length, equals(3),
          reason: 'BHA is capped at 3 days per week');

      // BHA days must be spread: each consecutive pair must have at least 1
      // gap day between them (difference ≥ 2), e.g. {0,2,4} or {1,3,5}.
      expect(_isSpread(bhaDays), isTrue,
          reason:
              'BHA days must have at least 1 gap day between each consecutive '
              'pair — got ${(bhaDays.toList()..sort())}');

      // No retinoid may appear on a BHA day.
      expect(retinolDays.intersection(bhaDays), isEmpty,
          reason: 'Retinol must not be scheduled on BHA days');
      expect(retinalDays.intersection(bhaDays), isEmpty,
          reason: 'Retinal must not be scheduled on BHA days');
      expect(bakuchiolDays.intersection(bhaDays), isEmpty,
          reason: 'Bakuchiol must not be scheduled on BHA days');

      // Each retinoid fills the remaining (non-BHA) days.
      final remaining = _allDays.difference(bhaDays);
      expect(retinolDays, equals(remaining));
      expect(retinalDays, equals(remaining));
      expect(bakuchiolDays, equals(remaining));
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

/// Returns true when every consecutive pair of days in [days] has a gap of
/// at least 1 (i.e. they differ by ≥ 2), e.g. {0,2,4} passes but {0,1,2} fails.
bool _isSpread(Set<int> days) {
  final sorted = days.toList()..sort();
  for (int i = 0; i < sorted.length - 1; i++) {
    if (sorted[i + 1] - sorted[i] < 2) return false;
  }
  return true;
}
