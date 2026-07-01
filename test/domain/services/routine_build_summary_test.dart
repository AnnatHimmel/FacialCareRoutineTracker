// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';
import 'package:skincare_tracker/data/repositories_impl/user_data_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/services/routine_build_summary.dart';
import 'package:skincare_tracker/domain/services/routine_service.dart';

// ── Fixtures ────────────────────────────────────────────────────────────────

const _manifest = MasterListManifest(
  contentVersion: '1.0.0',
  appVersion: '1.0.0',
  changelog: [],
);

const _cat = Category(id: 'cat-treat', name: 'טיפול', order: 1);

// Daily product, morning slot only.
const _dailyAm = MasterProduct(
  id: 'p-daily-am',
  name: 'Daily AM',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
  isDeprecated: false,
);

// Daily product present in BOTH slots (for the distinct-count check).
const _dailyBoth = MasterProduct(
  id: 'p-daily-both',
  name: 'Daily Both',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
  eveningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
  isDeprecated: false,
);

// Capped (3×/week) product, morning slot only.
const _capped3 = MasterProduct(
  id: 'p-capped-3',
  name: 'Capped Three',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 3, frequencyRule: WeeklyMaxRule(3)),
  isDeprecated: false,
);

// A second daily morning product, conflicting with _dailyAm.
const _dailyAm2 = MasterProduct(
  id: 'p-daily-am2',
  name: 'Daily AM Two',
  categoryId: 'cat-treat',
  morningConfig: SlotConfig(order: 4, frequencyRule: DailyRule()),
  isDeprecated: false,
);

IncompatibilityRule _rule(String id, String a, String b) => IncompatibilityRule(
      id: id,
      entityA: RuleTarget(type: RuleTargetType.product, id: a),
      entityB: RuleTarget(type: RuleTargetType.product, id: b),
      scope: RuleScope.withinSlot,
      reason: 'לא מומלצים יחד',
      reasonEn: 'Not recommended together',
    );

MasterContent _master(
  List<MasterProduct> products, {
  List<IncompatibilityRule> rules = const [],
}) =>
    MasterContent(
      products: products,
      categories: [_cat],
      subcategories: const [],
      rules: rules,
      manifest: _manifest,
    );

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

  Future<void> select(MasterProduct p, Slot slot) =>
      repo.upsertSelection(ProductSelection(
        id: 'sel-${p.id}-${slot.name}',
        productId: p.id,
        slot: slot,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

  group('buildRoutineSummary counts', () {
    test('counts distinct products in total but each slot separately',
        () async {
      final master = _master([_dailyAm, _dailyBoth]);
      await select(_dailyAm, Slot.morning);
      await select(_dailyBoth, Slot.morning);
      await select(_dailyBoth, Slot.evening);

      final summary = await scheduler.buildRoutineSummary(master: master);

      expect(summary.morningCount, 2);
      expect(summary.eveningCount, 1);
      // _dailyBoth counted once even though it is in both slots.
      expect(summary.totalProducts, 2);
    });
  });

  group('buildRoutineSummary changes', () {
    test('reduces a daily product against a capped one → reducedFrequency',
        () async {
      final master = _master(
        [_capped3, _dailyAm],
        rules: [_rule('r-cap-daily', _capped3.id, _dailyAm.id)],
      );
      await select(_capped3, Slot.morning);
      await select(_dailyAm, Slot.morning);

      final summary = await scheduler.buildRoutineSummary(master: master);

      expect(summary.changes, hasLength(1));
      final change = summary.changes.single;
      expect(change.slot, Slot.morning);
      expect(change.kind, RoutineChangeKind.reducedFrequency);
      expect(change.he, isNotEmpty);
      // A resolved pair must NOT also surface as an advisory.
      expect(summary.advisories, isEmpty);
      expect(summary.hasNothingToReport, isFalse);
    });
  });

  group('buildRoutineSummary advisories', () {
    test('muted daily↔daily pair surfaces as an advisory, not a change',
        () async {
      final master = _master(
        [_dailyAm, _dailyAm2],
        rules: [_rule('r-daily-daily', _dailyAm.id, _dailyAm2.id)],
      );
      await select(_dailyAm, Slot.morning);
      await select(_dailyAm2, Slot.morning);
      // User chose to keep them together.
      await repo.muteConflict(MutedConflict(
        id: 'm1',
        ruleId: 'r-daily-daily',
        mutedAt: DateTime(2026),
      ));

      final summary = await scheduler.buildRoutineSummary(master: master);

      expect(summary.changes, isEmpty);
      expect(summary.advisories, hasLength(1));
      final advisory = summary.advisories.single;
      expect(advisory.slot, Slot.morning);
      expect(advisory.he, 'לא מומלצים יחד');
      expect(summary.hasNothingToReport, isFalse);
    });
  });

  group('buildRoutineSummary empty', () {
    test('no conflicts → nothing to report, counts still correct', () async {
      final master = _master([_dailyAm]);
      await select(_dailyAm, Slot.morning);

      final summary = await scheduler.buildRoutineSummary(master: master);

      expect(summary.changes, isEmpty);
      expect(summary.advisories, isEmpty);
      expect(summary.morningCount, 1);
      expect(summary.eveningCount, 0);
      expect(summary.totalProducts, 1);
      expect(summary.hasNothingToReport, isTrue);
    });
  });
}
