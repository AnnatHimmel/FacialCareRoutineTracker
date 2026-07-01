import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/week_glance_builder.dart';

Category cat(String id, int order) => Category(id: id, name: id, order: order);

SubCategory sub(String id, String categoryId, int order) =>
    SubCategory(id: id, name: id, categoryId: categoryId, order: order);

MasterProduct prod(
  String id,
  String categoryId, {
  String? subCategoryId,
  int morningOrder = 1,
  int? eveningOrder,
  bool isDeprecated = false,
  FrequencyRule morningFreq = const DailyRule(),
  FrequencyRule? eveningFreq,
}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: categoryId,
      subCategoryId: subCategoryId,
      isDeprecated: isDeprecated,
      morningConfig:
          SlotConfig(order: morningOrder, frequencyRule: morningFreq),
      eveningConfig: eveningOrder == null
          ? null
          : SlotConfig(
              order: eveningOrder,
              frequencyRule: eveningFreq ?? const DailyRule(),
            ),
    );

ProductSelection selection(String productId, Slot slot, bool isSelected) =>
    ProductSelection(
      id: '$productId-$slot',
      productId: productId,
      slot: slot,
      isSelected: isSelected,
      lastModified: DateTime(2026, 1, 1),
    );

WeekdaySchedule schedule(
  String productId,
  Slot slot,
  Set<int> weekdays,
) =>
    WeekdaySchedule(
      id: '$productId-$slot-schedule',
      productId: productId,
      slot: slot,
      weekdays: weekdays,
      lastModified: DateTime(2026, 1, 1),
    );

IncompatibilityRule productRule(
  String id,
  String pA,
  String pB,
  RuleScope scope, {
  String? reason,
  String? reasonEn,
}) =>
    IncompatibilityRule(
      id: id,
      entityA: RuleTarget(type: RuleTargetType.product, id: pA),
      entityB: RuleTarget(type: RuleTargetType.product, id: pB),
      scope: scope,
      reason: reason,
      reasonEn: reasonEn,
    );

void main() {
  final catMorning = cat('catMorning', 1);
  final catEvening = cat('catEvening', 2);
  final categories = [catMorning, catEvening];
  final subcategories = <SubCategory>[];

  group('WeekGlanceBuilder', () {
    group('ProductWeekSpread - activeDays logic', () {
      test(
          'should_return_spread_all_true_when_given_daily_product_with_no_schedule',
          () {
        /// Given: One morning product with DailyRule (frequency-independent),
        /// no schedule row
        /// When: WeekGlanceBuilder builds the glance
        /// Then: activeDays should be all true (0..6)
        final p1 = prod('p1', 'catMorning');
        final morningSelections = [selection('p1', Slot.morning, true)];
        final eveningSelections = <ProductSelection>[];
        final schedules = <WeekdaySchedule>[];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 1);
        final spread = glance.morning.products[0];
        expect(spread.product, p1);
        expect(spread.activeDays, List.filled(7, true));
      });

      test(
          'should_exclude_daily_product_when_schedule_row_is_empty',
          () {
        /// Given: One morning DailyRule product with an EXPLICIT empty schedule
        /// row (= intentionally excluded, as written by auto-fix or the user)
        /// When: WeekGlanceBuilder builds the glance
        /// Then: the product has zero active days, so it is dropped from the
        /// slot's product list entirely (nothing to show on any day).
        final p1 = prod('p1', 'catMorning');
        final morningSelections = [selection('p1', Slot.morning, true)];
        final eveningSelections = <ProductSelection>[];
        final schedules = [
          schedule('p1', Slot.morning, {}), // empty weekdays = excluded
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.morning.products, isEmpty);
      });

      test(
          'should_honor_explicit_schedule_row_for_daily_product',
          () {
        /// Given: One morning DailyRule product with a non-empty schedule row
        /// {1, 3, 5} (the user restricted it to specific weekdays)
        /// When: WeekGlanceBuilder builds the glance
        /// Then: the explicit row wins — activeDays is true only at 1,3,5 (the
        /// actual per-day allocation), matching the schedule screen.
        final p1 = prod('p1', 'catMorning');
        final morningSelections = [selection('p1', Slot.morning, true)];
        final eveningSelections = <ProductSelection>[];
        final schedules = [
          schedule('p1', Slot.morning, {1, 3, 5}),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 1);
        final spread = glance.morning.products[0];
        final expected = List.filled(7, false);
        expected[1] = true;
        expected[3] = true;
        expected[5] = true;
        expect(spread.activeDays, expected);
      });

      test(
          'should_return_spread_matching_weeklymax_schedule_when_given_weeklymax_product_with_schedule',
          () {
        /// Given: One evening product with WeeklyMaxRule(3) and schedule weekdays {1, 3, 5}
        /// When: WeekGlanceBuilder builds the glance
        /// Then: activeDays should be true only at indices 1,3,5; all others false
        final p1 = prod(
          'p1',
          'catEvening',
          eveningOrder: 1,
          eveningFreq: const WeeklyMaxRule(3),
        );
        final morningSelections = <ProductSelection>[];
        final eveningSelections = [selection('p1', Slot.evening, true)];
        final schedules = [
          schedule('p1', Slot.evening, {1, 3, 5}),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.evening.products.length, 1);
        final spread = glance.evening.products[0];
        final expected = List.filled(7, false);
        expected[1] = true;
        expected[3] = true;
        expected[5] = true;
        expect(spread.activeDays, expected);
      });

      test(
          'should_exclude_weeklymax_product_when_no_schedule_row',
          () {
        /// Given: One evening WeeklyMaxRule(3) product with NO schedule row
        /// When: WeekGlanceBuilder builds the glance
        /// Then: it has no active days (a capped product needs a schedule to
        /// pin its days), so it is dropped from the slot's product list.
        final p1 = prod(
          'p1',
          'catEvening',
          eveningOrder: 1,
          eveningFreq: const WeeklyMaxRule(3),
        );
        final morningSelections = <ProductSelection>[];
        final eveningSelections = [selection('p1', Slot.evening, true)];
        final schedules = <WeekdaySchedule>[];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.evening.products, isEmpty);
      });
    });

    group('Conflicts - no rules', () {
      test(
          'should_have_no_issues_when_given_morning_and_evening_products_with_no_rules',
          () {
        /// Given: Morning and evening products with empty rules list
        /// When: WeekGlanceBuilder builds the glance
        /// Then: both slots should have hasIssues == false, issueCount == 0, and no conflictDays
        final p1 = prod('p1', 'catMorning');
        final p2 = prod(
          'p2',
          'catEvening',
          eveningOrder: 1,
        );
        final morningSelections = [selection('p1', Slot.morning, true)];
        final eveningSelections = [selection('p2', Slot.evening, true)];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1, p2],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: eveningSelections,
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.morning.hasIssues, isFalse);
        expect(glance.morning.issueCount, 0);
        expect(glance.morning.products[0].conflictDays, isEmpty);

        expect(glance.evening.hasIssues, isFalse);
        expect(glance.evening.issueCount, 0);
        expect(glance.evening.products[0].conflictDays, isEmpty);
      });
    });

    group('Conflicts - withinSlot', () {
      test(
          'should_detect_evening_conflict_when_given_two_products_under_withslot_rule',
          () {
        /// Given: Two evening products (pe1, pe2), both DailyRule (active all days),
        /// a withinSlot rule targeting both
        /// When: WeekGlanceBuilder builds the glance
        /// Then: evening.hasIssues == true, issueCount == 1, the pair's days == {0..6},
        /// and BOTH products have conflictDays == {0..6}
        final pe1 = prod(
          'pe1',
          'catEvening',
          eveningOrder: 1,
        );
        final pe2 = prod(
          'pe2',
          'catEvening',
          eveningOrder: 2,
        );
        final rule = productRule(
          'rule1',
          'pe1',
          'pe2',
          RuleScope.withinSlot,
          reason: 'סיבת בדיקה',
        );

        final eveningSelections = [
          selection('pe1', Slot.evening, true),
          selection('pe2', Slot.evening, true),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [pe1, pe2],
          categories: categories,
          subcategories: subcategories,
          rules: [rule],
          morningSelections: [],
          eveningSelections: eveningSelections,
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.evening.hasIssues, isTrue);
        expect(glance.evening.issueCount, 1);

        final conflictPair = glance.evening.conflicts[0];
        expect(conflictPair.days, {0, 1, 2, 3, 4, 5, 6});
        expect(
            conflictPair.reason,
            'סיבת בדיקה'); // reason should flow from the rule

        // Both products should have all 7 days in their conflictDays
        final spread1 = glance.evening.products
            .firstWhere((s) => s.product.id == 'pe1');
        final spread2 = glance.evening.products
            .firstWhere((s) => s.product.id == 'pe2');
        expect(spread1.conflictDays, {0, 1, 2, 3, 4, 5, 6});
        expect(spread2.conflictDays, {0, 1, 2, 3, 4, 5, 6});
      });

      test('should_not_detect_conflict_when_rule_is_muted', () {
        /// Given: Same two evening products and withinSlot rule as above,
        /// but the rule id is in mutedRuleIds
        /// When: WeekGlanceBuilder builds the glance
        /// Then: evening.hasIssues == false, issueCount == 0
        final pe1 = prod(
          'pe1',
          'catEvening',
          eveningOrder: 1,
        );
        final pe2 = prod(
          'pe2',
          'catEvening',
          eveningOrder: 2,
        );
        final rule = productRule(
          'rule1',
          'pe1',
          'pe2',
          RuleScope.withinSlot,
        );

        final eveningSelections = [
          selection('pe1', Slot.evening, true),
          selection('pe2', Slot.evening, true),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [pe1, pe2],
          categories: categories,
          subcategories: subcategories,
          rules: [rule],
          morningSelections: [],
          eveningSelections: eveningSelections,
          schedules: [],
          mutedRuleIds: {'rule1'},
        );

        expect(glance.evening.hasIssues, isFalse);
        expect(glance.evening.issueCount, 0);
      });

      test(
          'should_detect_conflict_only_on_overlapping_active_days_when_products_have_different_schedules',
          () {
        /// Given: Two evening products under a withinSlot rule:
        /// - pe1 has DailyRule (all days active)
        /// - pe2 has WeeklyMaxRule(2) with schedule {2, 4}
        /// When: WeekGlanceBuilder builds the glance
        /// Then: the conflict pair days == {2, 4} (only days both are active),
        /// pe1.conflictDays == {2, 4}, pe2.conflictDays == {2, 4}
        final pe1 = prod(
          'pe1',
          'catEvening',
          eveningOrder: 1,
        );
        final pe2 = prod(
          'pe2',
          'catEvening',
          eveningOrder: 2,
          eveningFreq: const WeeklyMaxRule(2),
        );
        final rule = productRule(
          'rule1',
          'pe1',
          'pe2',
          RuleScope.withinSlot,
        );

        final eveningSelections = [
          selection('pe1', Slot.evening, true),
          selection('pe2', Slot.evening, true),
        ];
        final schedules = [
          schedule('pe2', Slot.evening, {2, 4}),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [pe1, pe2],
          categories: categories,
          subcategories: subcategories,
          rules: [rule],
          morningSelections: [],
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.evening.hasIssues, isTrue);
        expect(glance.evening.issueCount, 1);

        final conflictPair = glance.evening.conflicts[0];
        expect(conflictPair.days, {2, 4});

        final spread1 = glance.evening.products
            .firstWhere((s) => s.product.id == 'pe1');
        final spread2 = glance.evening.products
            .firstWhere((s) => s.product.id == 'pe2');
        // pe1's conflictDays is the union of all conflicts it appears in
        expect(spread1.conflictDays, {2, 4});
        expect(spread2.conflictDays, {2, 4});
      });
    });

    group('Product filtering', () {
      test('should_exclude_unselected_products_from_results', () {
        /// Given: Two morning products, only one is selected (isSelected: true)
        /// When: WeekGlanceBuilder builds the glance
        /// Then: morning.products should contain only the selected product
        final p1 = prod('p1', 'catMorning');
        final p2 = prod('p2', 'catMorning');

        final morningSelections = [
          selection('p1', Slot.morning, true),
          selection('p2', Slot.morning, false), // not selected
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1, p2],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: [],
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 1);
        expect(glance.morning.products[0].product.id, 'p1');
      });

      test('should_exclude_deprecated_products_from_results', () {
        /// Given: One selected morning product that is deprecated
        /// When: WeekGlanceBuilder builds the glance
        /// Then: morning.products should be empty (deprecated products excluded)
        final p1 = prod('p1', 'catMorning', isDeprecated: true);

        final morningSelections = [selection('p1', Slot.morning, true)];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: [],
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 0);
      });

      test(
          'should_exclude_products_without_slot_config_from_results',
          () {
        /// Given: One morning product without morningConfig (eveningConfig only)
        /// When: WeekGlanceBuilder builds the glance
        /// Then: morning.products should be empty (no config for slot)
        const p1 = MasterProduct(
          id: 'p1',
          name: 'p1',
          categoryId: 'catEvening',
          isDeprecated: false,
          eveningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
        );

        final morningSelections = [selection('p1', Slot.morning, true)];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1],
          categories: categories,
          subcategories: subcategories,
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: [],
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 0);
      });
    });

    group('Product ordering', () {
      test('should_order_products_by_admin_comparator_within_slot', () {
        /// Given: Two morning products where p2 comes before p1 in admin order
        /// When: WeekGlanceBuilder builds the glance
        /// Then: morning.products should be ordered as [p2, p1]
        final catA = cat('catA', 1);
        final catB = cat('catB', 2);
        final cats = [catA, catB];

        final p1 = prod('p1', 'catB', morningOrder: 1);
        final p2 = prod('p2', 'catA', morningOrder: 1);

        final morningSelections = [
          selection('p1', Slot.morning, true),
          selection('p2', Slot.morning, true),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1, p2],
          categories: cats,
          subcategories: [],
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: [],
          schedules: [],
          mutedRuleIds: {},
        );

        expect(glance.morning.products.length, 2);
        expect(glance.morning.products[0].product.id, 'p2');
        expect(glance.morning.products[1].product.id, 'p1');
      });

      test('should_follow_order_override_when_present', () {
        /// Given: Two morning products whose admin order would be [p2, p1],
        /// but a global OrderOverride pins the order to [p1, p2]
        /// When: WeekGlanceBuilder builds the glance
        /// Then: the persisted override wins — products are [p1, p2], matching
        /// the order the routine uses (no re-deriving from admin sort).
        final catA = cat('catA', 1);
        final catB = cat('catB', 2);
        final cats = [catA, catB];

        // Admin order alone would put p2 (catA) before p1 (catB).
        final p1 = prod('p1', 'catB', morningOrder: 1);
        final p2 = prod('p2', 'catA', morningOrder: 1);

        final morningSelections = [
          selection('p1', Slot.morning, true),
          selection('p2', Slot.morning, true),
        ];

        final override = OrderOverride(
          id: 'ov-morning',
          slot: Slot.morning,
          weekday: null, // global override
          orderedProductIds: ['p1', 'p2'],
          lastModified: DateTime(2026, 1, 1),
        );

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [p1, p2],
          categories: cats,
          subcategories: [],
          rules: [],
          morningSelections: morningSelections,
          eveningSelections: [],
          schedules: [],
          mutedRuleIds: {},
          morningOrderOverride: override,
        );

        expect(glance.morning.products.length, 2);
        expect(glance.morning.products[0].product.id, 'p1');
        expect(glance.morning.products[1].product.id, 'p2');
      });
    });

    group('Multiple conflicts per pair', () {
      test(
          'should_union_conflicting_days_when_same_pair_conflicts_on_different_days',
          () {
        /// Given: Two evening products under one withinSlot rule,
        /// pe1 always active, pe2 active on {1, 2} only,
        /// (A conflict pair on days {1, 2} from the one rule)
        /// When: WeekGlanceBuilder builds the glance
        /// Then: the single conflict pair should have days == {1, 2}
        final pe1 = prod('pe1', 'catEvening', eveningOrder: 1);
        final pe2 = prod(
          'pe2',
          'catEvening',
          eveningOrder: 2,
          eveningFreq: const WeeklyMaxRule(2),
        );
        final rule = productRule(
          'rule1',
          'pe1',
          'pe2',
          RuleScope.withinSlot,
        );

        final eveningSelections = [
          selection('pe1', Slot.evening, true),
          selection('pe2', Slot.evening, true),
        ];
        final schedules = [
          schedule('pe2', Slot.evening, {1, 2}),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [pe1, pe2],
          categories: categories,
          subcategories: subcategories,
          rules: [rule],
          morningSelections: [],
          eveningSelections: eveningSelections,
          schedules: schedules,
          mutedRuleIds: {},
        );

        expect(glance.evening.issueCount, 1);
        expect(glance.evening.conflicts[0].days, {1, 2});
      });
    });

    group('Distinct conflict pairs', () {
      test(
          'should_dedupe_unordered_product_pairs_within_slot',
          () {
        /// Given: Two evening products under a withinSlot rule,
        /// IncompatibilityChecker will return (pe1, pe2) and (pe2, pe1) as separate ConflictInfos
        /// When: WeekGlanceBuilder builds the glance
        /// Then: conflicts should contain only ONE deduplicated pair (not two)
        final pe1 = prod('pe1', 'catEvening', eveningOrder: 1);
        final pe2 = prod('pe2', 'catEvening', eveningOrder: 2);
        final rule = productRule(
          'rule1',
          'pe1',
          'pe2',
          RuleScope.withinSlot,
        );

        final eveningSelections = [
          selection('pe1', Slot.evening, true),
          selection('pe2', Slot.evening, true),
        ];

        const builder = WeekGlanceBuilder();
        final glance = builder.build(
          allProducts: [pe1, pe2],
          categories: categories,
          subcategories: subcategories,
          rules: [rule],
          morningSelections: [],
          eveningSelections: eveningSelections,
          schedules: [],
          mutedRuleIds: {},
        );

        // IncompatibilityChecker returns both directions, but we should dedupe
        expect(glance.evening.issueCount, 1);
        expect(glance.evening.conflicts.length, 1);
      });
    });
  });
}
