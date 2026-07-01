import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/core/theme/app_colors.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
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
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/setup/schedule_setup_screen.dart';
import 'package:skincare_tracker/shared/widgets/weekday_picker.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> morningSelections;
  final List<ProductSelection> eveningSelections;
  final List<WeekdaySchedule> schedules;
  bool upsertScheduleCalled = false;

  _FakeUDR({
    this.morningSelections = const [],
    this.eveningSelections = const [],
    this.schedules = const [],
  });

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value(
        slot == Slot.morning ? morningSelections : eveningSelections,
      );

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value(schedules);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  final List<WeekdaySchedule> upsertedSchedules = [];

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {
    upsertScheduleCalled = true;
    upsertedSchedules.add(s);
  }

  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
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
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _weeklyProduct(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      morningConfig: const SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(3)),
    );

MasterProduct _dailyProduct(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _master(List<MasterProduct> products) => MasterContent(
      products: products,
      categories: [const Category(id: 'cat1', name: 'לחות', order: 1)],
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 's1',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

WeekdaySchedule _sched(String productId, Slot slot, Set<int> days) =>
    WeekdaySchedule(
      id: 'sched-$productId-${slot.name}',
      productId: productId,
      slot: slot,
      weekdays: days,
      lastModified: DateTime(2024, 1, 1),
    );

// Router wrapper — use for navigation-testing tests.
Widget _wrap({
  required MasterContent master,
  _FakeUDR? udr,
  bool fromSetup = false,
  bool fromProducts = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/schedule',
    routes: [
      GoRoute(
        path: '/setup/schedule',
        builder: (_, _) => ScheduleSetupScreen(
          fromSetup: fromSetup,
          fromProducts: fromProducts,
        ),
      ),
      GoRoute(
        path: '/setup/order',
        builder: (_, state) => Scaffold(
          body: Text(
            'order-from=${state.uri.queryParameters['from'] ?? 'none'}',
          ),
        ),
      ),
      GoRoute(
        path: '/routine-ready',
        builder: (_, _) => const Scaffold(body: Text('ROUTINE-READY')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr ?? _FakeUDR()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
    ),
  );
}

// Direct wrapper — use for interaction tests that don't need navigation.
// Uses fromProducts:true so no GlassBottomNav BackdropFilter is inserted.
Widget _wrapDirect({required MasterContent master, _FakeUDR? udr}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr ?? _FakeUDR()),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('he', 'MA'),
      home: ScheduleSetupScreen(fromProducts: true),
    ),
  );
}

void main() {
  group('ScheduleSetupScreen', () {
    testWidgets('WeeklyMax morning product shown when selected', (tester) async {
      final product = _weeklyProduct('p1', 'סרום ויטמין C');
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        schedules: [_sched('p1', Slot.morning, {0, 2, 4})],
      );

      await tester.pumpWidget(_wrap(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('סרום ויטמין C'), findsOneWidget);
    });

    testWidgets('DailyRule product shown under "כל יום" group', (tester) async {
      final product = _dailyProduct('p1', 'קרם לחות');
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );

      await tester.pumpWidget(_wrap(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      // Daily products are in the collapsed "כל יום" group — expand it first
      await tester.tap(find.textContaining('כל יום'));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
    });

    testWidgets('fromSetup: true → CTA label is המשך', (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);

      await tester.pumpWidget(
        _wrap(master: _master([product]), udr: udr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('המשך'), findsOneWidget);
    });

    testWidgets('fromSetup: false → CTA label is שמור', (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);

      await tester.pumpWidget(
        _wrap(master: _master([product]), udr: udr, fromSetup: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('שמור'), findsOneWidget);
    });

    testWidgets('fromSetup: true CTA navigates to /setup/order?from=setup',
        (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        schedules: [_sched('p1', Slot.morning, {0, 2, 4})],
      );

      await tester.pumpWidget(
        _wrap(master: _master([product]), udr: udr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.text('order-from=setup'), findsOneWidget);
    });

    testWidgets(
        'products flow CTA navigates to /routine-ready (auto-sorter summary)',
        (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        schedules: [_sched('p1', Slot.morning, {0, 2, 4})],
      );

      await tester.pumpWidget(
        _wrap(master: _master([product]), udr: udr, fromProducts: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('סיום ושמירת השגרה'));
      await tester.pumpAndSettle();

      expect(find.text('ROUTINE-READY'), findsOneWidget);
    });

    testWidgets('tapping weekday chip calls upsertSchedule', (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);

      // Use direct wrapper to avoid GoRouter's navigation barrier at scroll depth
      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      // V3 default mode is "days". Switch to products mode where _ListRow + WeekdayPicker live.
      await tester.tap(find.text('לפי מוצרים'));
      await tester.pumpAndSettle();

      // Weekly product is in the "לפי תדירות" list as a collapsed _ListRow.
      // Tap the tune icon (expand toggle) to expand it and reveal the WeekdayPicker.
      // (Tapping the product name now navigates to /collection/{id} instead.)
      await tester.tap(find.byIcon(Icons.tune_rounded));
      await tester.pumpAndSettle();

      // Tap the first GestureDetector inside the WeekdayPicker (Sunday chip)
      final pickerChip = find.descendant(
        of: find.byType(WeekdayPicker),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(pickerChip);
      await tester.pumpAndSettle();

      expect(udr.upsertScheduleCalled, isTrue);
    });

    testWidgets('V3 day summary card shows conflict info when products conflict on the same day',
        (tester) async {
      /// Given: Two morning products with a conflict rule, both scheduled on EVERY day
      /// (scheduling on all days ensures conflict is visible for whatever _selectedDay defaults to)
      final product1 = _dailyProduct('p1', 'סרום ויטמין C');
      final product2 = _dailyProduct('p2', 'נייר רך');

      const conflictRule = IncompatibilityRule(
        id: 'rule1',
        entityA: RuleTarget(type: RuleTargetType.product, id: 'p1'),
        entityB: RuleTarget(type: RuleTargetType.product, id: 'p2'),
        scope: RuleScope.withinSlot,
        reason: 'שני המוצרים לא יעבדו ביחד',
      );

      final master = MasterContent(
        products: [product1, product2],
        categories: [const Category(id: 'cat1', name: 'לחות', order: 1)],
        rules: [conflictRule],

        manifest: const MasterListManifest(
          contentVersion: '1.0.0',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );

      final udr = _FakeUDR(
        morningSelections: [
          _sel('p1', Slot.morning),
          _sel('p2', Slot.morning),
        ],
        schedules: [
          // Both products scheduled on ALL days — conflict visible regardless of today
          WeekdaySchedule(
            id: 's1',
            productId: 'p1',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6},
            lastModified: DateTime(2024, 1, 1),
          ),
          WeekdaySchedule(
            id: 's2',
            productId: 'p2',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6},
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      /// When: The screen loads (V3 days mode by default)
      await tester.pumpWidget(_wrapDirect(master: master, udr: udr));
      await tester.pumpAndSettle();

      /// Then: The day summary card shows conflict info for the currently selected day
      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;
      expect(find.text(l.daySummaryNoteSub), findsOneWidget);
      expect(find.text(l.issueActionReviewNotes), findsOneWidget);
    });

    testWidgets('V3 day summary card updates after switching slot',
        (tester) async {
      /// Given: Morning AND evening products each with a conflict rule, all scheduled every day

      const morningProd1 = MasterProduct(
        id: 'pm1',
        name: 'סרום ויטמין C',
        categoryId: 'cat1',
        isDeprecated: false,
        morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      const morningProd2 = MasterProduct(
        id: 'pm2',
        name: 'נייר רך',
        categoryId: 'cat1',
        isDeprecated: false,
        morningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
      );
      const eveningProd1 = MasterProduct(
        id: 'pe1',
        name: 'קרם לילה',
        categoryId: 'cat1',
        isDeprecated: false,
        eveningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      const eveningProd2 = MasterProduct(
        id: 'pe2',
        name: 'שמן',
        categoryId: 'cat1',
        isDeprecated: false,
        eveningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
      );

      const master = MasterContent(
        products: [morningProd1, morningProd2, eveningProd1, eveningProd2],
        categories: [Category(id: 'cat1', name: 'לחות', order: 1)],
        rules: [
          IncompatibilityRule(
            id: 'rule_morning',
            entityA: RuleTarget(type: RuleTargetType.product, id: 'pm1'),
            entityB: RuleTarget(type: RuleTargetType.product, id: 'pm2'),
            scope: RuleScope.withinSlot,
            reason: 'conflict in morning',
          ),
          IncompatibilityRule(
            id: 'rule_evening',
            entityA: RuleTarget(type: RuleTargetType.product, id: 'pe1'),
            entityB: RuleTarget(type: RuleTargetType.product, id: 'pe2'),
            scope: RuleScope.withinSlot,
            reason: 'conflict in evening',
          ),
        ],
        manifest: MasterListManifest(
          contentVersion: '1.0.0',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );

      final udr = _FakeUDR(
        morningSelections: [
          _sel('pm1', Slot.morning),
          _sel('pm2', Slot.morning),
        ],
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
        schedules: [
          // All products on every day so conflict is visible regardless of today
          WeekdaySchedule(id: 'spm1', productId: 'pm1', slot: Slot.morning,
              weekdays: {0, 1, 2, 3, 4, 5, 6}, lastModified: DateTime(2024)),
          WeekdaySchedule(id: 'spm2', productId: 'pm2', slot: Slot.morning,
              weekdays: {0, 1, 2, 3, 4, 5, 6}, lastModified: DateTime(2024)),
          WeekdaySchedule(id: 'spe1', productId: 'pe1', slot: Slot.evening,
              weekdays: {0, 1, 2, 3, 4, 5, 6}, lastModified: DateTime(2024)),
          WeekdaySchedule(id: 'spe2', productId: 'pe2', slot: Slot.evening,
              weekdays: {0, 1, 2, 3, 4, 5, 6}, lastModified: DateTime(2024)),
        ],
      );

      /// When: screen loads (morning slot, V3 days mode)
      await tester.pumpWidget(_wrapDirect(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Morning conflict visible in day summary card
      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;
      expect(find.text(l.daySummaryNoteSub), findsOneWidget);

      // Switch to evening slot
      await tester.tap(find.text(l.slotEvening));
      await tester.pumpAndSettle();

      /// Then: evening conflict info is now shown (card re-evaluates per slot)
      expect(find.text(l.daySummaryNoteSub), findsOneWidget);
    });

    testWidgets('day with overused product shows issue badge in day strip',
        (tester) async {
      /// Given: One weekly product (cap=2) scheduled on all 7 days (overuse).
      /// No conflicts. The overuse day should show a badge in the strip.
      const product = MasterProduct(
        id: 'p_over',
        name: 'סרום רטינול',
        categoryId: 'cat1',
        isDeprecated: false,
        morningConfig: SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(2)),
      );

      final udr = _FakeUDR(
        morningSelections: [_sel('p_over', Slot.morning)],
        schedules: [
          WeekdaySchedule(
            id: 's_over',
            productId: 'p_over',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6}, // 7 days > cap of 2
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      /// Then: the day strip should have a red issue badge (Container with error color)
      // The issue badge is a red circle with priority_high icon — find it
      final errorContainers = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final d = c.decoration;
        if (d is BoxDecoration) {
          return d.color == AppColors.error && d.shape == BoxShape.circle;
        }
        return false;
      });
      expect(errorContainers, isNotEmpty);
    });

    testWidgets('RoutineIssueSheet shows overuse section when product is overused',
        (tester) async {
      /// Given: One weekly product (cap=2) scheduled on all 7 days.
      /// No conflict rule. Day summary should show the combined note count.
      const product = MasterProduct(
        id: 'p_over2',
        name: 'סרום רטינול 2',
        categoryId: 'cat1',
        isDeprecated: false,
        morningConfig: SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(2)),
      );

      final udr = _FakeUDR(
        morningSelections: [_sel('p_over2', Slot.morning)],
        schedules: [
          WeekdaySchedule(
            id: 's_over2',
            productId: 'p_over2',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6},
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;

      // Open the issue sheet
      await tester.tap(find.text(l.issueActionReviewNotes));
      await tester.pumpAndSettle();

      // The overuse section header should appear
      expect(find.text(l.issueSheetOveruseSection), findsOneWidget);
      // The overuse body text (7 times, cap 2)
      expect(find.text(l.issueSheetOveruseBody(7, 2)), findsOneWidget);
    });

    testWidgets(
        'auto-fix applies a resolution by default and offers an Undo snackbar',
        (tester) async {
      /// Given: two daily morning products that conflict, both on every day.
      final product1 = _dailyProduct('p1', 'סרום ויטמין C');
      final product2 = _dailyProduct('p2', 'נייר רך');

      const conflictRule = IncompatibilityRule(
        id: 'rule1',
        entityA: RuleTarget(type: RuleTargetType.product, id: 'p1'),
        entityB: RuleTarget(type: RuleTargetType.product, id: 'p2'),
        scope: RuleScope.withinSlot,
        reason: 'שני המוצרים לא יעבדו ביחד',
      );

      final master = MasterContent(
        products: [product1, product2],
        categories: [const Category(id: 'cat1', name: 'לחות', order: 1)],
        rules: [conflictRule],
        manifest: const MasterListManifest(
          contentVersion: '1.0.0',
          appVersion: '1.0.0',
          changelog: [],
        ),
      );

      final udr = _FakeUDR(
        morningSelections: [
          _sel('p1', Slot.morning),
          _sel('p2', Slot.morning),
        ],
        schedules: [
          WeekdaySchedule(
            id: 's1',
            productId: 'p1',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6},
            lastModified: DateTime(2024, 1, 1),
          ),
          WeekdaySchedule(
            id: 's2',
            productId: 'p2',
            slot: Slot.morning,
            weekdays: {0, 1, 2, 3, 4, 5, 6},
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDirect(master: master, udr: udr));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(
          tester.element(find.byType(ScheduleSetupScreen)))!;

      /// When: tapping the inline auto-fix action (opt-out, applied by default).
      await tester.tap(find.text(l.issueActionAutoFix));
      await tester.pumpAndSettle();

      /// Then: schedules were mutated and an Undo affordance is shown.
      expect(udr.upsertScheduleCalled, isTrue);
      expect(find.text(l.autoFixUndo), findsOneWidget);
    });

    testWidgets('default selected day is the first issue day when one exists',
        (tester) async {
      /// Given: One weekly product (cap=1) scheduled on days 3 and 4 only (count=2 > cap=1).
      /// Today (0=Sun) has no product scheduled. Day 3 is the first issue day.
      const product = MasterProduct(
        id: 'p_def',
        name: 'פילינג',
        categoryId: 'cat1',
        isDeprecated: false,
        morningConfig: SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(1)),
      );

      final udr = _FakeUDR(
        morningSelections: [_sel('p_def', Slot.morning)],
        schedules: [
          WeekdaySchedule(
            id: 's_def',
            productId: 'p_def',
            slot: Slot.morning,
            weekdays: {3, 4}, // 2 days > cap of 1 → overuse on days 3 and 4
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;

      // Day 3 is Wednesday. The day summary card should show issue note count
      // for Wednesday (the first issue day), not today (Sunday with no products).
      expect(find.text(l.daySummaryNoteSub), findsOneWidget);
    });

    testWidgets(
        'WeeklyMax product with no schedule shows zero-day error and blocks continue',
        (tester) async {
      // A WeeklyMax morning product with NO schedule row → 0 effective days
      final product = _weeklyProduct('pz', 'חומצה');
      final udr = _FakeUDR(morningSelections: [_sel('pz', Slot.morning)]);

      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;

      // Error message is shown
      expect(
        find.text(l.scheduleZeroDayError(l.slotMorning)),
        findsOneWidget,
        reason: 'zero-day error must be visible when a WeeklyMax product has no schedule',
      );
    });

    testWidgets(
        'WeeklyMax product WITH schedule does not show zero-day error',
        (tester) async {
      final product = _weeklyProduct('pz', 'חומצה');
      final udr = _FakeUDR(
        morningSelections: [_sel('pz', Slot.morning)],
        schedules: [
          WeekdaySchedule(
            id: 's1',
            productId: 'pz',
            slot: Slot.morning,
            weekdays: {0, 2, 4},
            lastModified: DateTime(2024),
          ),
        ],
      );

      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;

      expect(
        find.text(l.scheduleZeroDayError(l.slotMorning)),
        findsNothing,
        reason: 'no zero-day error when product has a non-empty schedule',
      );
    });
  });
}
