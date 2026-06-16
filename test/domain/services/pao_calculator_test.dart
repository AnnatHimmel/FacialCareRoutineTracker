import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/services/pao_calculator.dart';
import 'package:skincare_tracker/domain/enums/pao_tone.dart';

void main() {
  group('PaoCalculator', () {
    final now = DateTime(2026, 6, 15);

    group('when openedDate is null', () {
      test('should_return_isOpened_false_when_openedDate_is_null', () {
        /**
         * Given: A PaoCalculator with openedDate = null
         * When: compute() is called
         * Then: isOpened should be false
         */
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: null,
          paoMonths: 12,
          now: now,
        );

        expect(result.isOpened, false);
      });

      test('should_return_fraction_0_when_openedDate_is_null', () {
        /**
         * Given: A PaoCalculator with openedDate = null
         * When: compute() is called
         * Then: fraction should be 0.0
         */
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: null,
          paoMonths: 12,
          now: now,
        );

        expect(result.fraction, 0.0);
      });

      test('should_return_monthsRemaining_equal_to_paoMonths_when_openedDate_is_null', () {
        /**
         * Given: A PaoCalculator with openedDate = null and paoMonths = 12
         * When: compute() is called
         * Then: monthsRemaining should equal paoMonths
         */
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: null,
          paoMonths: 12,
          now: now,
        );

        expect(result.monthsRemaining, 12);
      });

      test('should_return_tone_ok_when_openedDate_is_null', () {
        /**
         * Given: A PaoCalculator with openedDate = null
         * When: compute() is called
         * Then: tone should be PaoTone.ok
         */
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: null,
          paoMonths: 12,
          now: now,
        );

        expect(result.tone, PaoTone.ok);
      });
    });

    group('when opened 122 days ago', () {
      test('should_return_tone_ok_when_opened_122_days_ago', () {
        /**
         * Given: A product opened 122 days ago with paoMonths = 12
         * When: compute() is called
         * Then: tone should be PaoTone.ok
         */
        final openedDate = now.subtract(const Duration(days: 122));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.tone, PaoTone.ok);
      });

      test('should_return_monthsRemaining_between_7_and_8_when_opened_122_days_ago', () {
        /**
         * Given: A product opened 122 days ago with paoMonths = 12
         * When: compute() is called
         * Then: monthsRemaining should be between 7 and 8
         */
        final openedDate = now.subtract(const Duration(days: 122));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.monthsRemaining, inInclusiveRange(7, 8));
      });

      test('should_return_fraction_between_0_3_and_0_4_when_opened_122_days_ago', () {
        /**
         * Given: A product opened 122 days ago with paoMonths = 12
         * When: compute() is called
         * Then: fraction should be between 0.3 and 0.4
         */
        final openedDate = now.subtract(const Duration(days: 122));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.fraction, inInclusiveRange(0.3, 0.4));
      });
    });

    group('when opened 335 days ago', () {
      test('should_return_tone_warn_when_opened_335_days_ago', () {
        /**
         * Given: A product opened 335 days ago with paoMonths = 12
         * When: compute() is called
         * Then: tone should be PaoTone.warn (fraction ≈ 0.917)
         */
        final openedDate = now.subtract(const Duration(days: 335));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.tone, PaoTone.warn);
      });

      test('should_return_fraction_gte_0_8_and_lt_1_0_when_opened_335_days_ago', () {
        /**
         * Given: A product opened 335 days ago with paoMonths = 12
         * When: compute() is called
         * Then: fraction should be >= 0.8 and < 1.0
         */
        final openedDate = now.subtract(const Duration(days: 335));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.fraction, greaterThanOrEqualTo(0.8));
        expect(result.fraction, lessThan(1.0));
      });
    });

    group('when opened 396 days ago', () {
      test('should_return_tone_bad_when_opened_396_days_ago', () {
        /**
         * Given: A product opened 396 days ago with paoMonths = 12
         * When: compute() is called
         * Then: tone should be PaoTone.bad
         */
        final openedDate = now.subtract(const Duration(days: 396));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.tone, PaoTone.bad);
      });

      test('should_return_monthsRemaining_0_when_opened_396_days_ago', () {
        /**
         * Given: A product opened 396 days ago with paoMonths = 12
         * When: compute() is called
         * Then: monthsRemaining should be 0
         */
        final openedDate = now.subtract(const Duration(days: 396));
        final calculator = PaoCalculator();
        final result = calculator.compute(
          openedDate: openedDate,
          paoMonths: 12,
          now: now,
        );

        expect(result.monthsRemaining, 0);
      });
    });
  });

  group('defaultPaoMonths', () {
    test('should_return_18_for_cat_toner', () {
      /**
       * Given: category ID 'cat-toner'
       * When: defaultPaoMonths() is called
       * Then: should return 18
       */
      final result = defaultPaoMonths('cat-toner');
      expect(result, 18);
    });

    test('should_return_12_for_cat_serum', () {
      /**
       * Given: category ID 'cat-serum'
       * When: defaultPaoMonths() is called
       * Then: should return 12
       */
      final result = defaultPaoMonths('cat-serum');
      expect(result, 12);
    });

    test('should_return_12_for_unknown_category', () {
      /**
       * Given: an unknown category ID 'unknown-cat'
       * When: defaultPaoMonths() is called
       * Then: should return 12 (default)
       */
      final result = defaultPaoMonths('unknown-cat');
      expect(result, 12);
    });
  });
}
