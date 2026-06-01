import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/calendar_stats.dart';

void main() {
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

  DayRecord snapshotted(String date, Slot slot) =>
      makeRecord(date: date, slot: slot, resolved: ['p1'], recorded: []);

  group('computeMonthAvg', () {
    test('empty records → 0.0', () {
      expect(computeMonthAvg([], today: '2026-06-01'), 0.0);
    });

    test('past days fully done → 1.0', () {
      final records = [
        done('2026-05-30', Slot.morning),
        done('2026-05-30', Slot.evening),
        done('2026-05-31', Slot.morning),
        done('2026-05-31', Slot.evening),
      ];
      expect(computeMonthAvg(records, today: '2026-06-01'), 1.0);
    });

    test('today is excluded even when snapshotted', () {
      final records = [
        done('2026-05-31', Slot.morning),
        done('2026-05-31', Slot.evening),
        snapshotted('2026-06-01', Slot.morning), // today — not done yet
        snapshotted('2026-06-01', Slot.evening),
      ];
      // Should only count May 31 → 1.0, not diluted by today's 0%
      expect(computeMonthAvg(records, today: '2026-06-01'), 1.0);
    });

    test('future date record is excluded', () {
      final records = [
        done('2026-05-31', Slot.morning),
        snapshotted('2026-06-02', Slot.morning), // future
      ];
      expect(computeMonthAvg(records, today: '2026-06-01'), 1.0);
    });

    test('partial completion averages correctly across past days', () {
      // May 30: 1 product done out of 2 → 0.5
      // May 31: 2 products done out of 2 → 1.0
      // average = 0.75
      final records = [
        makeRecord(date: '2026-05-30', slot: Slot.morning,
            resolved: ['p1', 'p2'], recorded: ['p1']),
        makeRecord(date: '2026-05-31', slot: Slot.morning,
            resolved: ['p1', 'p2'], recorded: ['p1', 'p2']),
      ];
      expect(computeMonthAvg(records, today: '2026-06-01'), closeTo(0.75, 0.001));
    });

    test('null today includes all records', () {
      final records = [
        done('2026-06-01', Slot.morning),
        done('2026-06-02', Slot.morning),
      ];
      expect(computeMonthAvg(records, today: null), 1.0);
    });
  });
}
