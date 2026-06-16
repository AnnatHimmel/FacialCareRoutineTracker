import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/incompatibility_checker.dart';
import 'package:skincare_tracker/features/setup/schedule_setup_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterProduct _daily(String id, String name, {String catId = 'cat1'}) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterProduct _weekly(String id, String name, {String catId = 'cat1'}) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(3)),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 's-$productId',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

WeekdaySchedule _sched(String productId, Set<int> days) => WeekdaySchedule(
      id: 'sched-$productId',
      productId: productId,
      slot: Slot.morning,
      weekdays: days,
      lastModified: DateTime(2024, 1, 1),
    );

IncompatibilityRule _productRule(String a, String b, {String? reason}) =>
    IncompatibilityRule(
      id: 'rule-$a-$b',
      entityA: RuleTarget(type: RuleTargetType.product, id: a),
      entityB: RuleTarget(type: RuleTargetType.product, id: b),
      scope: RuleScope.withinSlot,
      reason: reason,
    );

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> morningSelections;
  List<WeekdaySchedule> schedules;
  final List<WeekdaySchedule> schedulesStore;

  _FakeUDR({
    this.morningSelections = const [],
    List<WeekdaySchedule>? schedules,
  })  : schedules = schedules ?? [],
        schedulesStore = schedules ?? [];

  WeekdaySchedule? lastUpserted;

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(slot == Slot.morning ? morningSelections : []);

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      Stream.value(schedules);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {
    lastUpserted = s;
    schedules = [
      ...schedules.where((e) => !(e.productId == s.productId && e.slot == s.slot)),
      s,
    ];
  }

  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) => throw UnimplementedError();
  @override Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) => throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
}

MasterContent _master(
  List<MasterProduct> products, {
  List<IncompatibilityRule> rules = const [],
  List<Category>? categories,
}) =>
    MasterContent(
      products: products,
      categories: categories ??
          [const Category(id: 'cat1', name: 'לחות', order: 1, icon: 'opacity')],
      rules: rules,
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrapDirect({required MasterContent master, _FakeUDR? udr}) =>
    ProviderScope(
      overrides: [
        masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
        userDataRepositoryProvider.overrideWithValue(udr ?? _FakeUDR()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he', 'MA'),
        home: const ScheduleSetupScreen(fromProducts: true),
      ),
    );

// ── Logic unit tests ──────────────────────────────────────────────────────────

void main() {
  group('ConflictInfo.reason propagation', () {
    test('reason from rule is propagated to ConflictInfo', () {
      final checker = IncompatibilityChecker();
      final pa = _daily('pa', 'Product A');
      final pb = _daily('pb', 'Product B');
      final rule = _productRule('pa', 'pb', reason: 'הסבר לגבי השילוב');

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [pa, pb],
        otherSlotProducts: [],
        rules: [rule],
        categories: [],
        mutedRuleIds: {},
      );

      expect(conflicts, hasLength(1));
      expect(conflicts.first.reason, equals('הסבר לגבי השילוב'));
    });

    test('reason is null when rule has no reason', () {
      final checker = IncompatibilityChecker();
      final pa = _daily('pa', 'A');
      final pb = _daily('pb', 'B');
      final rule = _productRule('pa', 'pb');

      final conflicts = checker.getConflictsForSelection(
        activeSlot: Slot.morning,
        slotProducts: [pa, pb],
        otherSlotProducts: [],
        rules: [rule],
        categories: [],
        mutedRuleIds: {},
      );

      expect(conflicts.first.reason, isNull);
    });
  });

  group('Category.icon', () {
    test('Category stores icon string', () {
      const cat = Category(id: 'cat1', name: 'לחות', order: 1, icon: 'opacity');
      expect(cat.icon, equals('opacity'));
    });

    test('Category icon defaults to null', () {
      const cat = Category(id: 'cat1', name: 'לחות', order: 1);
      expect(cat.icon, isNull);
    });
  });

  // ── UI integration tests ─────────────────────────────────────────────────────

  group('IssuesPanel UI', () {
    testWidgets('issues panel is visible and expanded by default when there are conflicts', (tester) async {
      final pa = _daily('pa', 'מוצר א׳');
      final pb = _daily('pb', 'מוצר ב׳');
      final rule = _productRule('pa', 'pb', reason: 'סיבת ההתנגשות');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Issues panel header is always visible — conflict count shown
      expect(find.textContaining('התראות'), findsWidgets);
      // Panel starts expanded by default — shows collapse chevron
      expect(find.byIcon(Icons.expand_less_rounded), findsWidgets);
      // Content visible without needing to expand
      expect(find.textContaining('כל ההתראות הן רכות'), findsOneWidget);
    });

    testWidgets('issues panel shows product names by default', (tester) async {
      final pa = _daily('pa', 'מוצר א׳');
      final pb = _daily('pb', 'מוצר ב׳');
      final rule = _productRule('pa', 'pb', reason: 'סיבה');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel starts expanded — product names visible without needing to expand
      expect(find.text('מוצר א׳'), findsWidgets);
      expect(find.text('מוצר ב׳'), findsWidgets);
    });

    testWidgets('issues panel shows reason text by default', (tester) async {
      final pa = _daily('pa', 'A');
      final pb = _daily('pb', 'B');
      final rule = _productRule('pa', 'pb', reason: 'סיבת ההתנגשות');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel starts expanded — reason visible without needing to expand
      expect(find.text('סיבת ההתנגשות'), findsWidgets);
    });

    testWidgets('tapping panel header collapses and re-expands the content', (tester) async {
      final pa = _daily('pa', 'A');
      final pb = _daily('pb', 'B');
      final rule = _productRule('pa', 'pb', reason: 'סיבה');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel is expanded by default: soft note visible
      expect(find.textContaining('כל ההתראות הן רכות'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less_rounded), findsWidgets);

      // Tap header to collapse
      await tester.tap(find.byIcon(Icons.expand_less_rounded).first);
      await tester.pumpAndSettle();

      // Panel body now hidden
      expect(find.textContaining('כל ההתראות הן רכות'), findsNothing);
      expect(find.byIcon(Icons.expand_more_rounded), findsWidgets);

      // Tap again to re-expand
      await tester.tap(find.byIcon(Icons.expand_more_rounded).first);
      await tester.pumpAndSettle();

      // Panel body visible again
      expect(find.textContaining('כל ההתראות הן רכות'), findsOneWidget);
    });

    testWidgets('fix button removes weekly product from its conflict day', (tester) async {
      final pa = _weekly('pa', 'מוצר א׳');
      final pb = _weekly('pb', 'מוצר ב׳');
      final rule = _productRule('pa', 'pb', reason: 'סיבה');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
        schedules: [_sched('pa', {0, 1}), _sched('pb', {0, 1})],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel is already expanded by default — tap remove button directly
      final fixButtonIcon = find.byIcon(Icons.event_busy_rounded).first;
      final fixButton = find.ancestor(
        of: fixButtonIcon,
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(fixButton);
      await tester.pumpAndSettle();

      expect(udr.lastUpserted, isNotNull);
      // The upserted schedule must NOT include day 0 (Sunday)
      expect(udr.lastUpserted!.weekdays.contains(0), isFalse);
    });

    testWidgets('fix button for daily product creates schedule excluding that day', (tester) async {
      final pa = _daily('pa', 'מוצר א׳');
      final pb = _daily('pb', 'מוצר ב׳');
      final rule = _productRule('pa', 'pb', reason: 'סיבה');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel is already expanded by default — tap remove button directly
      final fixButtonIcon = find.byIcon(Icons.event_busy_rounded).first;
      final fixButton = find.ancestor(
        of: fixButtonIcon,
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(fixButton);
      await tester.pumpAndSettle();

      expect(udr.lastUpserted, isNotNull);
      // Daily product has no schedule → all 7 days active → remove day 0 → 6 remain
      expect(udr.lastUpserted!.weekdays.length, equals(6));
      expect(udr.lastUpserted!.weekdays.contains(0), isFalse);
    });

    testWidgets('panel shows soft alerts footer note by default', (tester) async {
      final pa = _daily('pa', 'A');
      final pb = _daily('pb', 'B');
      final rule = _productRule('pa', 'pb');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([pa, pb], rules: [rule]), udr: udr));
      await tester.pumpAndSettle();

      // Panel starts expanded — footer note visible without needing to expand
      expect(find.textContaining('כל ההתראות הן רכות'), findsOneWidget);
    });

    testWidgets('category name shows inside the panel by default', (tester) async {
      final pa = _daily('pa', 'A', catId: 'cat-moisturizer');
      final pb = _daily('pb', 'B', catId: 'cat-moisturizer');
      final rule = _productRule('pa', 'pb');
      final udr = _FakeUDR(
        morningSelections: [_sel('pa', Slot.morning), _sel('pb', Slot.morning)],
      );
      final cats = [
        const Category(id: 'cat-moisturizer', name: 'לחות', order: 6, icon: 'opacity')
      ];

      await tester.pumpWidget(
        _wrapDirect(master: _master([pa, pb], rules: [rule], categories: cats), udr: udr),
      );
      await tester.pumpAndSettle();

      // Panel starts expanded — category name visible without needing to expand
      expect(find.text('לחות'), findsWidgets);
    });
  });
}
