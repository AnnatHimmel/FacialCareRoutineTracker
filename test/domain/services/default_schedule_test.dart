import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/services/default_schedule.dart';

void main() {
  group('spreadWeekdays', () {
    test('returns empty for n <= 0', () {
      expect(spreadWeekdays(0), isEmpty);
      expect(spreadWeekdays(-1), isEmpty);
      expect(spreadWeekdays(-5), isEmpty);
    });

    test('returns all seven weekdays for n >= 7', () {
      expect(spreadWeekdays(7), [0, 1, 2, 3, 4, 5, 6]);
      expect(spreadWeekdays(8), [0, 1, 2, 3, 4, 5, 6]);
      expect(spreadWeekdays(100), [0, 1, 2, 3, 4, 5, 6]);
    });

    test('n = 1 picks a single day', () {
      final r = spreadWeekdays(1);
      expect(r.length, 1);
      expect(r.first, 0);
    });

    test('n = 2 spreads roughly across the week', () {
      final r = spreadWeekdays(2);
      expect(r.length, 2);
      // First day anchored to Sunday, second maximally far.
      expect(r.first, 0);
      // gap between the two days should be near half a week.
      expect(r[1] - r[0], inInclusiveRange(3, 4));
    });

    test('n = 3 yields three evenly spaced days', () {
      final r = spreadWeekdays(3);
      expect(r, [0, 2, 4]);
    });

    test('n = 4 yields four spread days', () {
      final r = spreadWeekdays(4);
      expect(r.length, 4);
      // floor(i * 7 / 4) for i in 0..3 → 0,1,3,5 (gaps 1,2,2, wrap 2).
      expect(r, [0, 1, 3, 5]);
    });

    group('invariants for every n in 1..6', () {
      for (var n = 1; n <= 6; n++) {
        test('n = $n', () {
          final r = spreadWeekdays(n);
          // Correct count.
          expect(r.length, n, reason: 'expected $n days');
          // All within 0..6.
          for (final d in r) {
            expect(d, inInclusiveRange(0, 6));
          }
          // No duplicates.
          expect(r.toSet().length, r.length, reason: 'no duplicate days');
          // Ascending order.
          final sorted = [...r]..sort();
          expect(r, sorted, reason: 'days returned in ascending order');
          // Deterministic.
          expect(spreadWeekdays(n), r);
        });
      }
    });

    test('spacing is maximal — min gap is balanced', () {
      // For n=3, gaps are 2,2 (and wrap gap 3) — no two days adjacent.
      final r = spreadWeekdays(3);
      for (var i = 1; i < r.length; i++) {
        expect(r[i] - r[i - 1], greaterThanOrEqualTo(2));
      }
    });
  });
}
