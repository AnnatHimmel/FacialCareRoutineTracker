import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/domain/services/streak_calculator.dart';

void main() {
  final boundary = DayBoundaryService();
  final calc = StreakCalculator();

  DayRecord makeRecord({
    required String date,
    required Slot slot,
    required List<String> resolved,
    required List<String> recorded,
  }) =>
      DayRecord(
        id: '$date-${slot.name}',
        date: date,
        slot: slot,
        resolvedProductIds: resolved,
        recordedProductIds: recorded,
        resolvedAtMasterVersion: '1.0.0',
        lastModified: DateTime(2026),
      );

  DayRecord done(String date, Slot slot) =>
      makeRecord(date: date, slot: slot, resolved: ['p1'], recorded: ['p1']);

  DayRecord missed(String date, Slot slot) =>
      makeRecord(date: date, slot: slot, resolved: ['p1'], recorded: []);

  group('perfect days', () {
    test('5 complete days → streak 5', () {
      final records = <DayRecord>[];
      for (var i = 1; i <= 5; i++) {
        final date = '2026-05-${i.toString().padLeft(2, '0')}';
        records.add(done(date, Slot.morning));
        records.add(done(date, Slot.evening));
      }
      // asOf = May 6 at 10am (effective date = May 6, so yesterday = May 5)
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 6, 10),
        boundary: boundary,
      );
      expect(result.currentStreak, greaterThanOrEqualTo(4));
    });
  });

  group('grace budget', () {
    test('3 misses in one week → streak continues', () {
      // Sunday May 3 week: Sun=May 3, Mon=4, Tue=5
      final records = [
        done('2026-05-03', Slot.morning),
        done('2026-05-03', Slot.evening),
        done('2026-05-04', Slot.morning),
        missed('2026-05-04', Slot.evening), // miss 1
        done('2026-05-05', Slot.morning),
        missed('2026-05-05', Slot.evening), // miss 2
        done('2026-05-06', Slot.morning),
        missed('2026-05-06', Slot.evening), // miss 3
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 7, 10),
        boundary: boundary,
      );
      // Streak should still be active (3 misses ≤ grace budget of 3)
      expect(result.currentStreak, greaterThan(0));
    });

    test('4th miss in same week resets streak', () {
      final records = [
        done('2026-05-03', Slot.morning),
        missed('2026-05-03', Slot.evening), // miss 1
        done('2026-05-04', Slot.morning),
        missed('2026-05-04', Slot.evening), // miss 2
        done('2026-05-05', Slot.morning),
        missed('2026-05-05', Slot.evening), // miss 3
        done('2026-05-06', Slot.morning),
        missed('2026-05-06', Slot.evening), // miss 4 → reset
        done('2026-05-07', Slot.morning),
        done('2026-05-07', Slot.evening),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 8, 10),
        boundary: boundary,
      );
      // Streak should be at most 1 (only yesterday was complete after reset)
      expect(result.currentStreak, lessThanOrEqualTo(2));
    });
  });

  group('unscheduled slots', () {
    test('unscheduled slot not counted as miss', () {
      // Only morning records, no evening → evening is unscheduled
      final records = [
        done('2026-05-04', Slot.morning),
        done('2026-05-05', Slot.morning),
        done('2026-05-06', Slot.morning),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 7, 10),
        boundary: boundary,
      );
      // missesThisWeek should be 0 (no evening records = unscheduled)
      expect(result.missesThisWeek, 0);
    });

    test('morning-only routine: complete mornings count as complete days', () {
      // No evening records at all → morning-only routine
      final records = [
        done('2026-05-03', Slot.morning),
        done('2026-05-04', Slot.morning),
        done('2026-05-05', Slot.morning),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 6, 10),
        boundary: boundary,
      );
      // 3 complete mornings (no evening scheduled) = streak of 3
      expect(result.currentStreak, 3);
    });
  });

  group('missed days do not increment streak', () {
    // BUG 1: _contributingDaysInRange used _isScheduled, counting missed days
    // Fix: _completeDaysInRange must use _isDone for every scheduled slot

    test('2 complete days + 1 morning-missed day → streak 2, not 3', () {
      // Week: May 3 (Sun) through May 9 (Sat)
      // May 3: complete (morning + evening done)
      // May 4: complete (morning + evening done)
      // May 5: partial — morning scheduled+missed, evening done → NOT a complete day
      // asOf: May 6 10am → yesterday = May 5
      final records = [
        done('2026-05-03', Slot.morning),
        done('2026-05-03', Slot.evening),
        done('2026-05-04', Slot.morning),
        done('2026-05-04', Slot.evening),
        missed('2026-05-05', Slot.morning), // scheduled but not recorded
        done('2026-05-05', Slot.evening),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 6, 10),
        boundary: boundary,
      );
      expect(result.currentStreak, 2);
    });

    test('1 complete day + 3 missed days (grace absorbs) → streak 1, not 4', () {
      // May 3: complete
      // May 4, 5, 6: each has 1 missed slot (3 misses total — within grace of 3)
      // asOf: May 7 10am → yesterday = May 6
      final records = [
        done('2026-05-03', Slot.morning),
        done('2026-05-03', Slot.evening),
        missed('2026-05-04', Slot.morning),
        missed('2026-05-05', Slot.morning),
        missed('2026-05-06', Slot.morning),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 7, 10),
        boundary: boundary,
      );
      // Streak stays alive (≤3 misses), but only 1 day was actually complete
      expect(result.currentStreak, 1);
    });

    test('4 missed days in one week → streak resets to 0', () {
      // May 3–6: each day has 1 morning miss = 4 misses → grace exhausted
      final records = [
        missed('2026-05-03', Slot.morning),
        missed('2026-05-04', Slot.morning),
        missed('2026-05-05', Slot.morning),
        missed('2026-05-06', Slot.morning),
      ];
      final result = calc.compute(
        allRecords: records,
        asOf: DateTime(2026, 5, 7, 10),
        boundary: boundary,
      );
      expect(result.currentStreak, 0);
    });
  });
}
