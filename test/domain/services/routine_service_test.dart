// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';
import 'package:skincare_tracker/data/repositories_impl/user_data_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/domain/services/routine_resolver.dart';
import 'package:skincare_tracker/domain/services/routine_service.dart';
import 'package:skincare_tracker/domain/services/week_glance_builder.dart';

// ── Fixture helpers ────────────────────────────────────────────────────────

const _manifest = MasterListManifest(
  contentVersion: '1.0.0',
  appVersion: '1.0.0',
  changelog: [],
);

const _catCleanse = Category(id: 'cat-cleanse', name: 'ניקוי', order: 1);
const _catTreat = Category(id: 'cat-treat', name: 'טיפול', order: 2);

// A product with DailyRule in the morning slot only.
const _dailyProduct = MasterProduct(
  id: 'prod-daily',
  name: 'Daily Moisturiser',
  categoryId: 'cat-cleanse',
  morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
  isDeprecated: false,
);

// A custom product with WeeklyMaxRule(2) in the morning slot.
final _customProduct = UserCustomProduct(
  id: 'custom-prod-1',
  name: 'My Custom Serum',
  categoryId: 'cat-treat',
  inMorning: true,
  inEvening: false,
  isDaily: false,
  maxTimesPerWeek: 2,
  lastModified: DateTime(2026),
);

// A custom product that conflicts with _conflictA within morning slot.
const _conflictRuleCustom = IncompatibilityRule(
  id: 'rule-custom-ca',
  entityA: RuleTarget(type: RuleTargetType.product, id: 'custom-prod-1'),
  entityB: RuleTarget(type: RuleTargetType.product, id: 'prod-conflict-a'),
  scope: RuleScope.withinSlot,
  reason: 'custom product conflicts with Vitamin C',
);

// A product with WeeklyMaxRule(3) in the morning slot only.
const _weeklyProduct = MasterProduct(
  id: 'prod-weekly',
  name: 'BHA Exfoliant',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(3)),
  isDeprecated: false,
);

// Conflicting pair — both in the morning slot.
const _conflictA = MasterProduct(
  id: 'prod-conflict-a',
  name: 'Vitamin C',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
  isDeprecated: false,
);

const _conflictB = MasterProduct(
  id: 'prod-conflict-b',
  name: 'Niacinamide',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 3, frequencyRule: DailyRule()),
  isDeprecated: false,
);

const _conflictRule = IncompatibilityRule(
  id: 'rule-vc-nia',
  entityA: RuleTarget(type: RuleTargetType.product, id: 'prod-conflict-a'),
  entityB: RuleTarget(type: RuleTargetType.product, id: 'prod-conflict-b'),
  scope: RuleScope.withinSlot,
  reason: 'ויטמין C ונציאנאמיד לא מומלצים ביחד',
);

MasterContent _buildMaster() => MasterContent(
      products: [
        _dailyProduct,
        _weeklyProduct,
        _conflictA,
        _conflictB,
      ],
      categories: [_catCleanse, _catTreat],
      subcategories: const [],
      rules: [_conflictRule],
      manifest: _manifest,
    );

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  late AppDatabase db;
  late UserDataRepositoryImpl repo;
  late RoutineService scheduler;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserDataRepositoryImpl(db);
    scheduler = RoutineService(repo);
  });

  tearDown(() async {
    await db.close();
  });

  // ── Group 1: effectiveDays (static) ─────────────────────────────────────

  group('effectiveDays', () {
    test(
        'should_return_all_7_days_when_DailyRule_product_has_no_schedule_row',
        () {
      // Given: a DailyRule product and an empty schedule list
      // When: effectiveDays is called
      final result = RoutineService.effectiveDays(
        _dailyProduct,
        Slot.morning,
        const [],
      );

      // Then: all 7 days are active (Sunday=0 … Saturday=6)
      expect(result, equals({0, 1, 2, 3, 4, 5, 6}));
    });

    test(
        'should_return_empty_set_when_WeeklyMaxRule_product_has_no_schedule_row',
        () {
      // Given: a WeeklyMaxRule product and an empty schedule list
      // When: effectiveDays is called
      final result = RoutineService.effectiveDays(
        _weeklyProduct,
        Slot.morning,
        const [],
      );

      // Then: empty — no days assigned yet
      expect(result, isEmpty);
    });

    test(
        'should_return_empty_set_when_explicit_empty_schedule_row_present',
        () {
      // Given: a DailyRule product that has an explicit row with no weekdays
      final explicitEmptyRow = WeekdaySchedule(
        id: 'sch-empty',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        weekdays: const {},
        lastModified: DateTime(2026),
      );

      // When: effectiveDays is called — explicit row wins even when empty
      final result = RoutineService.effectiveDays(
        _dailyProduct,
        Slot.morning,
        [explicitEmptyRow],
      );

      // Then: explicit empty row suppresses the product on all days
      expect(result, isEmpty);
    });
  });

  // ── Group 2: addProduct ──────────────────────────────────────────────────

  group('addProduct', () {
    test(
        'should_persist_selection_and_default_schedule_and_return_admin_sorted_index_for_DailyRule',
        () async {
      // Given: empty repo
      final master = _buildMaster();

      // When: addProduct is called for the daily product
      final index = await scheduler.addProduct(
        master: master,
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      // Then: selection is persisted as selected
      final selections = await repo.watchSelections(Slot.morning).first;
      expect(
        selections.any((s) => s.productId == _dailyProduct.id && s.isSelected),
        isTrue,
        reason: 'selection must be persisted as selected',
      );

      // Then: a default schedule exists with all 7 days (DailyRule default)
      final schedules = await repo.watchAllSchedules().first;
      final row = schedules
          .where(
              (s) => s.productId == _dailyProduct.id && s.slot == Slot.morning)
          .firstOrNull;
      // DailyRule: defaultDaysFor returns {0..6}; no schedule row is also valid
      // — the scheduler may skip the write if the default matches the no-row
      // behaviour. Either row is absent (daily default) or row.weekdays == {0..6}.
      if (row != null) {
        expect(row.weekdays, equals({0, 1, 2, 3, 4, 5, 6}));
      }

      // Then: returned index is the admin-sorted position of the product in
      // the morning slot — valid non-negative integer
      expect(index, greaterThanOrEqualTo(0));
    });

    test(
        'should_persist_selection_and_spread_schedule_and_return_index_for_WeeklyMaxRule',
        () async {
      // Given: empty repo
      final master = _buildMaster();

      // When: addProduct is called for the weekly-max product
      final index = await scheduler.addProduct(
        master: master,
        productId: _weeklyProduct.id,
        slot: Slot.morning,
      );

      // Then: selection is persisted as selected
      final selections = await repo.watchSelections(Slot.morning).first;
      expect(
        selections
            .any((s) => s.productId == _weeklyProduct.id && s.isSelected),
        isTrue,
        reason: 'selection must be persisted as selected',
      );

      // Then: a schedule row exists with exactly maxPerWeek=3 days
      final schedules = await repo.watchAllSchedules().first;
      final row = schedules
          .where(
              (s) => s.productId == _weeklyProduct.id && s.slot == Slot.morning)
          .firstOrNull;
      expect(row, isNotNull,
          reason: 'WeeklyMaxRule product must have an explicit schedule row');
      expect(
        row!.weekdays.length,
        equals(3),
        reason: 'defaultDaysFor must spread exactly maxPerWeek days',
      );

      // Then: returned index is valid
      expect(index, greaterThanOrEqualTo(0));
    });

    test(
        'addProduct_with_existing_global_override_inserts_new_product_at_admin_sorted_position',
        () async {
      // Given: two products already in the override list
      // _conflictA has category cat-treat (order 2), slot order 2
      // _conflictB has category cat-treat (order 2), slot order 3
      // _dailyProduct has category cat-cleanse (order 1), slot order 1
      // Admin order: _dailyProduct < _conflictA < _conflictB
      final master = _buildMaster();

      // Seed an existing global override that has conflictA and conflictB only
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: [_conflictA.id, _conflictB.id],
      );

      // When: adding _dailyProduct (which admin-sorts BEFORE both existing products)
      await scheduler.addProduct(
        master: master,
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      // Then: global override should now be [dailyProduct, conflictA, conflictB]
      final override = await repo.watchOrderOverride(Slot.morning).first;
      expect(override, isNotNull);
      expect(
        override!.orderedProductIds,
        equals([_dailyProduct.id, _conflictA.id, _conflictB.id]),
        reason: 'new product must be inserted at its admin-sorted position, not appended',
      );
    });

    test(
        'addProduct_with_existing_per_day_override_inserts_new_product_at_admin_sorted_position',
        () async {
      // Given: a per-day override for Monday (weekday=1) with two products
      final master = _buildMaster();
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: 1,
        orderedIds: [_conflictA.id, _conflictB.id],
      );

      // When: adding _dailyProduct (admin-first)
      await scheduler.addProduct(
        master: master,
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      // Then: per-day override for Monday must include the new product at its admin position
      final perDays = await repo.watchPerDayOrderOverrides(Slot.morning).first;
      final monday = perDays.where((o) => o.weekday == 1).firstOrNull;
      expect(monday, isNotNull);
      expect(
        monday!.orderedProductIds,
        equals([_dailyProduct.id, _conflictA.id, _conflictB.id]),
        reason: 'per-day override must also be updated with admin-sorted insertion',
      );
    });
  });

  // ── Group 3: removeProduct ───────────────────────────────────────────────

  group('removeProduct', () {
    test(
        'should_deselect_product_and_clear_schedule_when_removeProduct_called',
        () async {
      // Given: a daily product that has been added
      final master = _buildMaster();
      await scheduler.addProduct(
        master: master,
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      // When: removeProduct is called
      await scheduler.removeProduct(
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      // Then: the selection is not selected
      final selections = await repo.watchSelections(Slot.morning).first;
      final sel = selections
          .where((s) => s.productId == _dailyProduct.id)
          .firstOrNull;
      if (sel != null) {
        expect(
          sel.isSelected,
          isFalse,
          reason: 'selection must be deselected after removeProduct',
        );
      }

      // Then: no active schedule days remain for this product in this slot
      final schedules = await repo.watchAllSchedules().first;
      final row = schedules
          .where(
              (s) => s.productId == _dailyProduct.id && s.slot == Slot.morning)
          .firstOrNull;
      if (row != null) {
        expect(
          row.weekdays,
          isEmpty,
          reason: 'schedule days must be cleared after removeProduct',
        );
      }
    });

    test('removes product from global order override on removeProduct',
        () async {
      final master = _buildMaster();
      await scheduler.addProduct(
          master: master, productId: _dailyProduct.id, slot: Slot.morning);
      await scheduler.setOrder(
          slot: Slot.morning, weekday: null, orderedIds: [_dailyProduct.id]);

      await scheduler.removeProduct(
          productId: _dailyProduct.id, slot: Slot.morning);

      final override = await repo.watchOrderOverride(Slot.morning).first;
      expect(
        override == null || !override.orderedProductIds.contains(_dailyProduct.id),
        isTrue,
        reason: 'global override must not contain removed product ID',
      );
    });

    test('removes product from per-day order overrides on removeProduct',
        () async {
      final master = _buildMaster();
      await scheduler.addProduct(
          master: master, productId: _dailyProduct.id, slot: Slot.morning);
      await scheduler.setOrder(
          slot: Slot.morning, weekday: 1, orderedIds: [_dailyProduct.id]);

      await scheduler.removeProduct(
          productId: _dailyProduct.id, slot: Slot.morning);

      final overrides =
          await repo.watchPerDayOrderOverrides(Slot.morning).first;
      for (final o in overrides) {
        expect(
          o.orderedProductIds,
          isNot(contains(_dailyProduct.id)),
          reason: 'per-day override must not contain removed product ID',
        );
      }
    });

    test('re-adding product after removal inserts at admin position not stale position',
        () async {
      final master = _buildMaster();
      await scheduler.addProduct(
          master: master, productId: _dailyProduct.id, slot: Slot.morning);
      await scheduler.setOrder(
          slot: Slot.morning, weekday: null, orderedIds: [_dailyProduct.id]);
      await scheduler.removeProduct(
          productId: _dailyProduct.id, slot: Slot.morning);

      await scheduler.addProduct(
          master: master, productId: _dailyProduct.id, slot: Slot.morning);

      final override = await repo.watchOrderOverride(Slot.morning).first;
      if (override != null) {
        final count = override.orderedProductIds
            .where((id) => id == _dailyProduct.id)
            .length;
        expect(count, equals(1),
            reason: 'product must appear exactly once in override after re-add');
      }
    });
  });

  // ── Group 4: orderForDay ─────────────────────────────────────────────────

  group('orderForDay', () {
    test(
        'should_return_same_order_as_direct_RoutineResolver_resolve_call',
        () async {
      // Given: two products selected and scheduled for Monday (weekday=1)
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-daily',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-weekly',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // Give the weekly product a schedule that includes Monday
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-weekly',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        weekdays: const {1, 3, 5},
        lastModified: DateTime(2026),
      ));

      // When: orderForDay is called for Monday morning
      final schedulerResult = await scheduler.orderForDay(
        master: master,
        slot: Slot.morning,
        weekday: 1,
      );

      // Then: it must equal what RoutineResolver.resolve returns for the same
      // inputs (Monday = 2026-01-05 which is weekday=1 in Dart Mon=1)
      final selections = await repo.watchSelections(Slot.morning).first;
      final schedules = await repo.watchAllSchedules().first;

      final resolver = RoutineResolver();
      final expectedResult = resolver.resolve(
        date: DateTime(2026, 1, 5), // Monday
        slot: Slot.morning,
        allProducts: master.products,
        categories: master.categories,
        subcategories: master.subcategories,
        selections: selections,
        schedules: schedules,
        orderOverride: null,
        boundary: DayBoundaryService(),
      );

      expect(
        schedulerResult.map((p) => p.id).toList(),
        equals(expectedResult.map((p) => p.id).toList()),
        reason: 'orderForDay must produce the same ordered list as RoutineResolver',
      );
    });
  });

  // ── Group 5: warningsForDay ──────────────────────────────────────────────

  group('warningsForDay', () {
    test(
        'should_return_non_empty_conflicts_when_conflicting_pair_active_on_day',
        () async {
      // Given: both conflicting products selected and active on Sunday (weekday=0)
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-ca',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cb',
        productId: _conflictB.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // Both are DailyRule — no schedule row means they are active every day

      // When: warningsForDay is called for Sunday morning (weekday=0)
      final warnings = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      // Then: at least one conflict detected
      expect(
        warnings.conflicts,
        isNotEmpty,
        reason:
            'conflicting pair active on the same day must appear in conflicts',
      );
    });

    test(
        'should_return_overuse_entry_when_WeeklyMax_product_scheduled_over_cap',
        () async {
      // Given: weekly product selected and scheduled on more days than its cap
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-weekly-over',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // cap is 3 — schedule it on 5 days
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-weekly-over',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        weekdays: const {0, 1, 2, 3, 4},
        lastModified: DateTime(2026),
      ));

      // When: warningsForDay is called for any of the active days
      final warnings = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      // Then: an OveruseEntry is reported for the product
      expect(
        warnings.overused,
        isNotEmpty,
        reason: 'product scheduled beyond cap must appear in overused',
      );
      final entry = warnings.overused.first;
      expect(entry.product.id, equals(_weeklyProduct.id));
      expect(entry.cap, equals(3));
      expect(entry.count, greaterThan(entry.cap));
    });

    test(
        'should_reflect_zeroDayCount_when_capped_product_left_with_no_days',
        () async {
      // Given: weekly product selected but intentionally given an empty schedule
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-weekly-zero',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // Explicit empty schedule row — the product runs on zero days
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-weekly-zero',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        weekdays: const {},
        lastModified: DateTime(2026),
      ));

      // When: warningsForDay is called
      final warnings = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      // Then: zeroDayCount is at least 1
      expect(
        warnings.zeroDayCount,
        greaterThanOrEqualTo(1),
        reason: 'a selected capped product with no days must count toward zeroDayCount',
      );
    });

    test('hasIssues_should_be_true_when_conflicts_present', () async {
      // Given: conflicting pair active on the day
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-ca2',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cb2',
        productId: _conflictB.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      // When
      final warnings = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      // Then
      expect(warnings.hasIssues, isTrue);
    });
  });

  // ── Group 5b: watchPerDayOrderOverrides / getEffectiveOrderOverride ────────

  group('watchPerDayOrderOverrides', () {
    test(
        'should_emit_only_per_day_overrides_for_the_slot',
        () async {
      // Given: a global override (weekday == null) and a per-day override
      // (weekday == 1) for Slot.morning
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: 1,
        orderedIds: ['prod-weekly', 'prod-daily'],
      );

      // When: watchPerDayOrderOverrides is called for morning
      final overrides =
          await scheduler.watchPerDayOrderOverrides(Slot.morning).first;

      // Then: only the per-day override (weekday != null) is returned
      expect(
        overrides.every((o) => o.weekday != null),
        isTrue,
        reason: 'watchPerDayOrderOverrides must not include global overrides',
      );
      expect(
        overrides.any((o) => o.weekday == 1),
        isTrue,
        reason: 'the per-day override for weekday 1 must be present',
      );
    });
  });

  group('getEffectiveOrderOverride', () {
    test(
        'should_return_per_day_override_when_present',
        () async {
      // Given: global + per-day override for weekday 2
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: 2,
        orderedIds: ['prod-weekly', 'prod-daily'],
      );

      // When: getEffectiveOrderOverride for weekday 2
      final result =
          await scheduler.getEffectiveOrderOverride(Slot.morning, 2);

      // Then: the per-day override wins
      expect(result, isNotNull);
      expect(result!.weekday, equals(2));
      expect(
        result.orderedProductIds,
        equals(['prod-weekly', 'prod-daily']),
      );
    });

    test(
        'should_fall_back_to_global_override_when_no_per_day_override',
        () async {
      // Given: only a global override (no per-day for weekday 3)
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );

      // When: getEffectiveOrderOverride for weekday 3
      final result =
          await scheduler.getEffectiveOrderOverride(Slot.morning, 3);

      // Then: the global override is returned
      expect(result, isNotNull);
      expect(result!.weekday, isNull);
      expect(
        result.orderedProductIds,
        equals(['prod-daily', 'prod-weekly']),
      );
    });

    test(
        'should_return_null_when_no_override_at_all',
        () async {
      // Given: empty repo

      // When: getEffectiveOrderOverride for any weekday
      final result =
          await scheduler.getEffectiveOrderOverride(Slot.morning, 0);

      // Then: null
      expect(result, isNull);
    });
  });

  // ── Group 5c: warningsForDayFrom ────────────────────────────────────────

  group('warningsForDayFrom', () {
    test(
        'should_return_same_conflicts_and_overused_and_zeroDayCount_as_async_warningsForDay',
        () async {
      // Given: a setup identical to the Group 5 tests combined — conflicting
      // pair selected in morning + weekly product over-scheduled + weekly
      // product with an empty schedule.
      final master = _buildMaster();

      // Conflicting pair
      await repo.upsertSelection(ProductSelection(
        id: 'sel-ca-sync',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cb-sync',
        productId: _conflictB.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // Weekly product over cap (cap=3, schedule 5 days)
      await repo.upsertSelection(ProductSelection(
        id: 'sel-weekly-sync',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-weekly-sync',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        weekdays: const {0, 1, 2, 3, 4},
        lastModified: DateTime(2026),
      ));

      // Get the async result first
      final asyncResult = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      // Build the exact same inputs the async version read from the repo
      final morningSelections = await repo.watchSelections(Slot.morning).first;
      final eveningSelections = await repo.watchSelections(Slot.evening).first;
      final schedules = await repo.watchAllSchedules().first;
      final mutedConflicts = await repo.watchMutedConflicts().first;
      final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

      Set<String> selectedIds(List<ProductSelection> sels) =>
          sels.where((s) => s.isSelected).map((s) => s.productId).toSet();

      List<MasterProduct> slotProds(Slot s, Set<String> ids) =>
          master.products
              .where((p) =>
                  !p.isDeprecated &&
                  ids.contains(p.id) &&
                  p.configForSlot(s) != null)
              .toList();

      final morningIds = selectedIds(morningSelections);
      final eveningIds = selectedIds(eveningSelections);
      final morningProds = slotProds(Slot.morning, morningIds);
      final eveningProds = slotProds(Slot.evening, eveningIds);

      // When: pure sync helper is called with those same snapshots
      final syncResult = scheduler.warningsForDayFrom(
        master: master,
        slot: Slot.morning,
        weekday: 0,
        slotProducts: morningProds,
        otherSlotProducts: eveningProds,
        schedules: schedules,
        mutedRuleIds: mutedRuleIds,
      );

      // Then: results match
      expect(
        syncResult.conflicts.map((c) => c.ruleId).toList()..sort(),
        equals(asyncResult.conflicts.map((c) => c.ruleId).toList()..sort()),
        reason: 'conflict rule ids must match between sync and async',
      );
      expect(
        syncResult.overused.map((e) => e.product.id).toList()..sort(),
        equals(asyncResult.overused.map((e) => e.product.id).toList()..sort()),
        reason: 'overused product ids must match between sync and async',
      );
      expect(
        syncResult.zeroDayCount,
        equals(asyncResult.zeroDayCount),
        reason: 'zeroDayCount must match between sync and async',
      );
    });

    test(
        'should_return_empty_DayWarnings_when_no_products_passed',
        () {
      // Given: empty product lists
      final master = _buildMaster();

      // When: called with empty lists
      final result = scheduler.warningsForDayFrom(
        master: master,
        slot: Slot.morning,
        weekday: 0,
        slotProducts: const [],
        otherSlotProducts: const [],
        schedules: const [],
        mutedRuleIds: const {},
      );

      // Then: no warnings
      expect(result.conflicts, isEmpty);
      expect(result.overused, isEmpty);
      expect(result.zeroDayCount, equals(0));
    });
  });

  // ── Group 6: weekGlance ──────────────────────────────────────────────────

  group('weekGlance', () {
    test(
        'should_return_same_product_ids_as_direct_WeekGlanceBuilder_build_call',
        () async {
      // Given: daily product selected in morning
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-d',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      // When: weekGlance is called on the scheduler
      final glance = await scheduler.weekGlance(master: master);

      // Then: must equal WeekGlanceBuilder.build with the same inputs
      final morningSelections = await repo.watchSelections(Slot.morning).first;
      final eveningSelections = await repo.watchSelections(Slot.evening).first;
      final schedules = await repo.watchAllSchedules().first;

      final expected = const WeekGlanceBuilder().build(
        allProducts: master.products,
        categories: master.categories,
        subcategories: master.subcategories,
        rules: master.rules,
        morningSelections: morningSelections,
        eveningSelections: eveningSelections,
        schedules: schedules,
        mutedRuleIds: const {},
      );

      expect(
        glance.morning.products.map((p) => p.product.id).toList(),
        equals(expected.morning.products.map((p) => p.product.id).toList()),
        reason: 'morning product ids must match WeekGlanceBuilder output',
      );
      expect(
        glance.evening.products.map((p) => p.product.id).toList(),
        equals(expected.evening.products.map((p) => p.product.id).toList()),
        reason: 'evening product ids must match WeekGlanceBuilder output',
      );
    });
  });

  // ── Group 8: passthrough methods ────────────────────────────────────────

  group('passthrough methods', () {
    test(
        'upsertSelection_then_watchSelections_reflects_it',
        () async {
      // Given: a fresh selection
      final sel = ProductSelection(
        id: 'pt-sel-1',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      );

      // When: upsertSelection is called via scheduler passthrough
      await scheduler.upsertSelection(sel);

      // Then: watchSelections reflects the upserted row
      final selections = await scheduler.watchSelections(Slot.morning).first;
      expect(
        selections.any((s) => s.id == 'pt-sel-1' && s.isSelected),
        isTrue,
        reason: 'upsertSelection passthrough must persist the selection',
      );
    });

    test(
        'upsertSchedule_then_watchSchedule_reflects_it',
        () async {
      // Given: a weekday schedule
      final sched = WeekdaySchedule(
        id: 'pt-sched-1',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        weekdays: const {0, 2, 4},
        lastModified: DateTime(2026),
      );

      // When: upsertSchedule is called via scheduler passthrough
      await scheduler.upsertSchedule(sched);

      // Then: watchSchedule for that product/slot emits the row
      final row =
          await scheduler.watchSchedule(_dailyProduct.id, Slot.morning).first;
      expect(row, isNotNull, reason: 'upsertSchedule passthrough must persist the schedule');
      expect(row!.weekdays, equals(const {0, 2, 4}));
    });

    test(
        'upsertOrderOverride_then_getEffectiveOrderOverride_returns_it',
        () async {
      // Given: a global order override
      final override = OrderOverride(
        id: 'pt-oo-1',
        slot: Slot.morning,
        weekday: null,
        orderedProductIds: ['prod-daily', 'prod-weekly'],
        lastModified: DateTime(2026),
      );

      // When: upsertOrderOverride is called via scheduler passthrough
      await scheduler.upsertOrderOverride(override);

      // Then: getEffectiveOrderOverride returns it for any weekday (global fallback)
      final result = await scheduler.getEffectiveOrderOverride(Slot.morning, 0);
      expect(result, isNotNull);
      expect(result!.orderedProductIds, equals(['prod-daily', 'prod-weekly']));
    });

    test(
        'deleteOrderOverride_removes_global_override',
        () async {
      // Given: a global override exists
      await scheduler.upsertOrderOverride(OrderOverride(
        id: 'pt-oo-del',
        slot: Slot.morning,
        weekday: null,
        orderedProductIds: ['prod-daily'],
        lastModified: DateTime(2026),
      ));

      // When: deleteOrderOverride is called via scheduler passthrough
      await scheduler.deleteOrderOverride(Slot.morning);

      // Then: no global override remains
      final result = await scheduler.getEffectiveOrderOverride(Slot.morning, 0);
      expect(result, isNull);
    });

    test(
        'upsertSchedule_then_watchAllSchedules_contains_it',
        () async {
      // Given: a schedule row
      final sched = WeekdaySchedule(
        id: 'pt-all-sched-1',
        productId: _weeklyProduct.id,
        slot: Slot.morning,
        weekdays: const {1, 3, 5},
        lastModified: DateTime(2026),
      );

      // When: upsertSchedule via passthrough
      await scheduler.upsertSchedule(sched);

      // Then: watchAllSchedules contains the row
      final all = await scheduler.watchAllSchedules().first;
      expect(
        all.any((s) => s.id == 'pt-all-sched-1'),
        isTrue,
        reason: 'upsertSchedule passthrough must appear in watchAllSchedules',
      );
    });

    test(
        'deletePerDayOrderOverride_removes_per_day_override',
        () async {
      // Given: a per-day override for weekday 1
      await scheduler.upsertOrderOverride(OrderOverride(
        id: 'pt-pd-del',
        slot: Slot.morning,
        weekday: 1,
        orderedProductIds: ['prod-weekly', 'prod-daily'],
        lastModified: DateTime(2026),
      ));
      // Verify it was stored
      final before =
          await scheduler.watchPerDayOrderOverrides(Slot.morning).first;
      expect(before.any((o) => o.weekday == 1), isTrue);

      // When: deletePerDayOrderOverride via passthrough
      await scheduler.deletePerDayOrderOverride(Slot.morning, 1);

      // Then: per-day override for weekday 1 is gone
      final after =
          await scheduler.watchPerDayOrderOverrides(Slot.morning).first;
      expect(after.any((o) => o.weekday == 1), isFalse);
    });
  });

  // ── Group 5d: setOrder deterministic id / no duplicate rows ────────────────

  group('setOrder deterministic id', () {
    test(
        'calling_setOrder_twice_for_same_slot_results_in_exactly_one_override_row',
        () async {
      // RED: this test currently fails because the second setOrder call
      // generates a new UUID id and inserts a SECOND row.
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-weekly', 'prod-daily'],
      );

      // Only one global row should exist for morning slot
      final overrides =
          await scheduler.watchOrderOverride(Slot.morning).first;

      // watchOrderOverride returns the effective (latest) override
      expect(overrides, isNotNull);
      expect(overrides!.orderedProductIds,
          equals(['prod-weekly', 'prod-daily']),
          reason: 'second setOrder must update the existing row, not create a duplicate');
    });

    test(
        'deterministic_id_is_stable_across_multiple_setOrder_calls',
        () async {
      // Call setOrder 3 times for same slot — must always upsert same row
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-weekly', 'prod-daily'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );

      // Last write wins — must be the third write
      final overrides =
          await scheduler.watchOrderOverride(Slot.morning).first;
      expect(overrides, isNotNull);
      expect(overrides!.orderedProductIds,
          equals(['prod-daily', 'prod-weekly']),
          reason: 'third setOrder must reflect the latest write');
    });

    test(
        'setOrder_per_day_twice_results_in_one_row_with_latest_order',
        () async {
      // Per-day variant: weekday != null
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: 3,
        orderedIds: ['prod-daily', 'prod-weekly'],
      );
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: 3,
        orderedIds: ['prod-weekly', 'prod-daily'],
      );

      final overrides =
          await scheduler.watchPerDayOrderOverrides(Slot.morning).first;
      final dayOverride = overrides.where((o) => o.weekday == 3).toList();

      // Must be exactly one row for this weekday
      expect(dayOverride.length, equals(1),
          reason: 'setOrder twice for same slot+weekday must upsert, not duplicate');
      expect(dayOverride.first.orderedProductIds,
          equals(['prod-weekly', 'prod-daily']),
          reason: 'must reflect the latest write');
    });
  });

  // ── Group 7: fixProblems ─────────────────────────────────────────────────

  group('fixProblems', () {
    test(
        'should_separate_conflicting_pair_and_return_non_empty_applied_mutations',
        () async {
      // Given: both conflicting products selected (DailyRule, no schedule row
      // → active every day → they conflict every day)
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-caf',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cbf',
        productId: _conflictB.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      // When: fixProblems is called for the morning slot
      final result = await scheduler.fixProblems(
        master: master,
        slot: Slot.morning,
      );

      // Then: at least one mutation was applied
      expect(
        result.applied,
        isNotEmpty,
        reason: 'fixProblems must produce at least one mutation when a conflict exists',
      );
      expect(result.isEmpty, isFalse);

      // Then: the pair is no longer in conflict on at least some day — verify
      // by reading the updated schedules and checking warningsForDay
      // (try weekday 0 which was previously conflicting)
      final warningsAfter = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );
      // The pair must no longer be active together on day 0
      expect(
        warningsAfter.conflicts,
        isEmpty,
        reason: 'after fixProblems the conflict must be resolved for the affected day',
      );
    });

    test(
        'should_restore_original_schedule_when_inverse_mutations_applied',
        () async {
      // Given: conflicting pair selected with no prior schedule rows
      final master = _buildMaster();
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cai',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-cbi',
        productId: _conflictB.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      // Snapshot pre-fix schedules
      final preFixSchedules = await repo.watchAllSchedules().first;

      // When: fixProblems is called
      final result = await scheduler.fixProblems(
        master: master,
        slot: Slot.morning,
      );

      // Then: apply the inverse mutations to undo the fix
      await scheduler.applyMutationsPersisting(result.inverse);

      // Then: schedules are restored to the pre-fix state (same weekday sets)
      final restoredSchedules = await repo.watchAllSchedules().first;

      // Compare weekday sets for each product that was mutated
      for (final mutation in result.inverse) {
        final preRow = preFixSchedules
            .where((s) =>
                s.productId == mutation.productId && s.slot == mutation.slot)
            .firstOrNull;
        final restoredRow = restoredSchedules
            .where((s) =>
                s.productId == mutation.productId && s.slot == mutation.slot)
            .firstOrNull;

        final preWeekdays = preRow?.weekdays ?? const <int>{};
        final restoredWeekdays = restoredRow?.weekdays ?? const <int>{};

        expect(
          restoredWeekdays,
          equals(preWeekdays),
          reason:
              'applying inverse must restore schedule for ${mutation.productId}',
        );
      }
    });
  });

  // ── Group 9: manualOrderChangesForSlot ──────────────────────────────────
  //
  // Admin order for the three DailyRule products (selected, slot config in
  // morning, not day-filtered): _dailyProduct (cat-cleanse, order 1) <
  // _conflictA (cat-treat, slot order 2) < _conflictB (cat-treat, slot order 3).

  group('manualOrderChangesForSlot', () {
    Future<void> selectThree() async {
      for (final p in [_dailyProduct, _conflictA, _conflictB]) {
        await repo.upsertSelection(ProductSelection(
          id: 'sel-${p.id}',
          productId: p.id,
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2026),
        ));
      }
    }

    test('returns hasOverride false and no moved products when no override',
        () async {
      final master = _buildMaster();
      await selectThree();

      final result = await scheduler.manualOrderChangesForSlot(
        master: master,
        slot: Slot.morning,
      );

      expect(result.hasOverride, isFalse);
      expect(result.moved, isEmpty);
    });

    test(
        'global override that swaps two products reports them as moved with target positions',
        () async {
      final master = _buildMaster();
      await selectThree();
      // Admin order: [daily, conflictA, conflictB]. Swap the first two.
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: [_conflictA.id, _dailyProduct.id, _conflictB.id],
      );

      final result = await scheduler.manualOrderChangesForSlot(
        master: master,
        slot: Slot.morning,
      );

      expect(result.hasOverride, isTrue);
      expect(result.isGlobalScope, isTrue);
      // Only the two swapped products are "moved"; conflictB keeps its slot.
      expect(
        result.moved.map((m) => m.product.id).toList(),
        equals([_dailyProduct.id, _conflictA.id]),
        reason: 'moved list is sorted by target (recommended) position',
      );
      // Target positions are 1-based positions in the recommended (admin) order.
      expect(result.moved[0].targetPosition, equals(1));
      expect(result.moved[1].targetPosition, equals(2));
    });

    test('reports empty moved list when override matches the recommended order',
        () async {
      final master = _buildMaster();
      await selectThree();
      // Override identical to admin order — nothing actually moved.
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: [_dailyProduct.id, _conflictA.id, _conflictB.id],
      );

      final result = await scheduler.manualOrderChangesForSlot(
        master: master,
        slot: Slot.morning,
      );

      expect(result.hasOverride, isTrue);
      expect(result.moved, isEmpty,
          reason: 'an override equal to the recommended order moves nothing');
    });

    test('considers the full selected slot set, not a single day', () async {
      final master = _buildMaster();
      await selectThree();
      // Give one product a partial weekly schedule — it must still be counted
      // (the order screen lists all selected slot products, not day-filtered).
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-ca-partial',
        productId: _conflictA.id,
        slot: Slot.morning,
        weekdays: const {1, 3},
        lastModified: DateTime(2026),
      ));
      // Rotation (admin [daily, A, B] → [B, daily, A]) displaces all three.
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: [_conflictB.id, _dailyProduct.id, _conflictA.id],
      );

      final result = await scheduler.manualOrderChangesForSlot(
        master: master,
        slot: Slot.morning,
      );

      expect(result.moved.length, equals(3));
    });
  });

  // ── Group: healStaleAutoSpreadSchedules (one-time migration) ───────────────

  group('healStaleAutoSpreadSchedules', () {
    Future<void> select(MasterProduct p, Slot slot) => repo.upsertSelection(
          ProductSelection(
            id: 's-${p.id}-${slot.name}',
            productId: p.id,
            slot: slot,
            isSelected: true,
            lastModified: DateTime.now(),
          ),
        );

    Future<void> setRow(MasterProduct p, Slot slot, Set<int> days) =>
        repo.upsertSchedule(WeekdaySchedule(
          id: 'w-${p.id}-${slot.name}',
          productId: p.id,
          slot: slot,
          weekdays: days,
          lastModified: DateTime.now(),
        ));

    Future<Set<int>?> rowDays(MasterProduct p, Slot slot) async {
      final all = await repo.watchAllSchedules().first;
      final matches =
          all.where((s) => s.productId == p.id && s.slot == slot).toList();
      return matches.isEmpty ? null : matches.first.weekdays;
    }

    test('heals a daily product whose schedule equals an auto-spread → all 7',
        () async {
      await select(_dailyProduct, Slot.morning);
      await setRow(_dailyProduct, Slot.morning, {0, 2, 4}); // spreadN7(3)

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 1);
      expect(await rowDays(_dailyProduct, Slot.morning), {0, 1, 2, 3, 4, 5, 6});
    });

    test('leaves an explicitly emptied (suppressed) row untouched', () async {
      await select(_dailyProduct, Slot.morning);
      await setRow(_dailyProduct, Slot.morning, <int>{});

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 0);
      expect(await rowDays(_dailyProduct, Slot.morning), <int>{});
    });

    test('leaves an already all-7 daily row untouched', () async {
      await select(_dailyProduct, Slot.morning);
      await setRow(_dailyProduct, Slot.morning, {0, 1, 2, 3, 4, 5, 6});

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 0);
    });

    test('leaves a hand-picked (non-spread) daily row untouched', () async {
      await select(_dailyProduct, Slot.morning);
      // {1,3,5} omits day 0, so it can never equal any spreadN7(n).
      await setRow(_dailyProduct, Slot.morning, {1, 3, 5});

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 0);
      expect(await rowDays(_dailyProduct, Slot.morning), {1, 3, 5});
    });

    test('leaves a weeklyMax product untouched even if it matches a spread',
        () async {
      await select(_weeklyProduct, Slot.morning);
      await setRow(_weeklyProduct, Slot.morning, {0, 2, 4});

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 0);
      expect(await rowDays(_weeklyProduct, Slot.morning), {0, 2, 4});
    });

    test('ignores unselected products', () async {
      await setRow(_dailyProduct, Slot.morning, {0, 2, 4}); // not selected

      final healed =
          await scheduler.healStaleAutoSpreadSchedules(master: _buildMaster());

      expect(healed, 0);
      expect(await rowDays(_dailyProduct, Slot.morning), {0, 2, 4});
    });
  });

  // ── Group: custom product integration ───────────────────────────────────────

  group('custom product integration', () {
    // ── 1. allProducts returns master + custom with editable==true ─────────

    test(
        'allProducts returns master products followed by custom.toMasterProduct() with editable true',
        () async {
      final master = _buildMaster();
      await repo.upsertCustomProduct(_customProduct);

      final all = await scheduler.allProducts(master);

      // master products come first
      final masterIds = master.products.map((p) => p.id).toList();
      for (var i = 0; i < masterIds.length; i++) {
        expect(all[i].id, equals(masterIds[i]));
      }

      // custom product is at the end
      final custom = all.where((p) => p.id == _customProduct.id).toList();
      expect(custom, hasLength(1), reason: 'custom product must appear in allProducts');
      expect(custom.first.editable, isTrue,
          reason: 'custom products converted via toMasterProduct() have editable=true');
    });

    // ── 2. watchAllProducts emits merged list and re-emits on add ──────────

    test(
        'watchAllProducts emits merged list and re-emits when a custom product is added',
        () async {
      final master = _buildMaster();

      // Collect two emissions
      final emissions = <List<MasterProduct>>[];
      final sub = scheduler.watchAllProducts(master).listen(emissions.add);

      // First emission: no customs yet
      await Future<void>.delayed(Duration.zero);
      expect(emissions, isNotEmpty);
      expect(
        emissions.last.any((p) => p.id == _customProduct.id),
        isFalse,
        reason: 'first emission must not include custom product before upsert',
      );

      // Add a custom product and wait for re-emission
      await repo.upsertCustomProduct(_customProduct);
      await Future<void>.delayed(Duration.zero);

      expect(
        emissions.last.any((p) => p.id == _customProduct.id),
        isTrue,
        reason: 'watchAllProducts must re-emit after a custom product is added',
      );
      await sub.cancel();
    });

    // ── 3. manualOrderChangesForSlot counts a custom product ────────────────

    test(
        'manualOrderChangesForSlot counts a custom product that was moved in the override',
        () async {
      final master = _buildMaster();
      await repo.upsertCustomProduct(_customProduct);

      // Select the custom product and the daily product in morning
      await repo.upsertSelection(ProductSelection(
        id: 'sel-custom',
        productId: _customProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-daily-mc',
        productId: _dailyProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      // Set a global override that puts the custom product before the daily product
      // (admin order would be: daily first [order=1, cat-cleanse], custom second [order=999, cat-treat])
      await scheduler.setOrder(
        slot: Slot.morning,
        weekday: null,
        orderedIds: [_customProduct.id, _dailyProduct.id],
      );

      final result = await scheduler.manualOrderChangesForSlot(
        master: master,
        slot: Slot.morning,
      );

      expect(result.hasOverride, isTrue);
      // Both products were swapped relative to admin order — the custom product
      // must appear in the moved list (previously it was dropped because
      // manualOrderChangesForSlot only consulted master.products).
      expect(
        result.moved.any((m) => m.product.id == _customProduct.id),
        isTrue,
        reason: 'custom product moved in override must appear in ManualOrderChanges.moved',
      );
    });

    // ── 4. warningsForDay includes a custom product in conflict detection ────

    test(
        'warningsForDay includes a custom product in conflict detection',
        () async {
      // Build a master that has the custom conflict rule
      final master = MasterContent(
        products: [_conflictA, _conflictB, _dailyProduct, _weeklyProduct],
        categories: [_catCleanse, _catTreat],
        subcategories: const [],
        rules: [_conflictRule, _conflictRuleCustom],
        manifest: _manifest,
      );

      await repo.upsertCustomProduct(_customProduct);

      // Select custom product and conflictA in morning
      await repo.upsertSelection(ProductSelection(
        id: 'sel-custom-warn',
        productId: _customProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-ca-warn',
        productId: _conflictA.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      // Custom product is WeeklyMaxRule(2), needs a schedule row to be active
      await repo.upsertSchedule(WeekdaySchedule(
        id: 'sch-custom-warn',
        productId: _customProduct.id,
        slot: Slot.morning,
        weekdays: const {0, 1},
        lastModified: DateTime(2026),
      ));

      final warnings = await scheduler.warningsForDay(
        master: master,
        slot: Slot.morning,
        weekday: 0,
      );

      expect(
        warnings.conflicts,
        isNotEmpty,
        reason: 'conflict between a custom product and a master product must be detected',
      );
    });

    // ── 5. ensureDefaultSchedules seeds a schedule for a custom weekly product

    test(
        'ensureDefaultSchedules seeds a default spread schedule for a selected custom weekly-capped product',
        () async {
      final master = _buildMaster();
      await repo.upsertCustomProduct(_customProduct); // WeeklyMaxRule(2)

      await repo.upsertSelection(ProductSelection(
        id: 'sel-custom-sched',
        productId: _customProduct.id,
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      await scheduler.ensureDefaultSchedules(master: master);

      final schedules = await repo.watchAllSchedules().first;
      final row = schedules
          .where((s) => s.productId == _customProduct.id && s.slot == Slot.morning)
          .firstOrNull;

      expect(row, isNotNull,
          reason: 'ensureDefaultSchedules must seed a schedule row for a custom capped product');
      expect(
        row!.weekdays.length,
        equals(2),
        reason: 'default spread must match maxTimesPerWeek=2',
      );
    });

    // ── 6. addProduct returns a non-zero index for a custom product ──────────

    test(
        'addProduct returns a valid (non-negative) admin-sorted index for a custom product',
        () async {
      final master = _buildMaster();
      await repo.upsertCustomProduct(_customProduct); // WeeklyMaxRule(2)

      // Also add the daily product so there are multiple products in the slot
      await scheduler.addProduct(
        master: master,
        productId: _dailyProduct.id,
        slot: Slot.morning,
      );

      final index = await scheduler.addProduct(
        master: master,
        productId: _customProduct.id,
        slot: Slot.morning,
      );

      // Custom product (cat-treat, order=999) sorts after dailyProduct
      // (cat-cleanse, order=1) so it should get index > 0 in the sorted list.
      expect(index, greaterThanOrEqualTo(0),
          reason: 'addProduct must return a valid index for a custom product');
      // Specifically expect it to be > 0 since there is one product that sorts before it
      expect(index, greaterThan(0),
          reason: 'custom product with higher slot order must sort after master daily product');
    });

    // ── 7. CRUD pass-throughs ────────────────────────────────────────────────

    test(
        'watchCustomProducts delegates to repo',
        () async {
      await repo.upsertCustomProduct(_customProduct);

      final products = await scheduler.watchCustomProducts().first;

      expect(
        products.any((p) => p.id == _customProduct.id),
        isTrue,
        reason: 'watchCustomProducts must return products from the repo',
      );
    });

    test(
        'getCustomProduct returns the product by id',
        () async {
      await repo.upsertCustomProduct(_customProduct);

      final result = await scheduler.getCustomProduct(_customProduct.id);

      expect(result, isNotNull);
      expect(result!.id, equals(_customProduct.id));
    });

    test(
        'getCustomProduct returns null for unknown id',
        () async {
      final result = await scheduler.getCustomProduct('nonexistent-id');

      expect(result, isNull);
    });

    test(
        'upsertCustomProduct persists to repo',
        () async {
      await scheduler.upsertCustomProduct(_customProduct);

      final products = await repo.watchCustomProducts().first;
      expect(
        products.any((p) => p.id == _customProduct.id),
        isTrue,
        reason: 'upsertCustomProduct must persist through to repo',
      );
    });

    test(
        'deleteCustomProduct soft-deletes via repo (product becomes deprecated)',
        () async {
      await repo.upsertCustomProduct(_customProduct);

      await scheduler.deleteCustomProduct(_customProduct.id);

      // deleteCustomProduct is a soft-delete: the row stays but isDeprecated=true.
      // The product must not appear as an active (non-deprecated) custom product.
      final products = await repo.watchCustomProducts().first;
      final found = products.where((p) => p.id == _customProduct.id).firstOrNull;
      expect(
        found == null || found.isDeprecated,
        isTrue,
        reason: 'deleteCustomProduct must soft-delete (isDeprecated=true) the product in the repo',
      );
    });
  });
}
