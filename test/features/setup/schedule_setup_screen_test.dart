import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
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

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {
    upsertScheduleCalled = true;
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

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _weeklyProduct(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: WeeklyMaxRule(3)),
    );

MasterProduct _dailyProduct(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
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

// Router wrapper — use for navigation-testing tests.
Widget _wrap({
  required MasterContent master,
  _FakeUDR? udr,
  bool fromSetup = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/schedule',
    routes: [
      GoRoute(
        path: '/setup/schedule',
        builder: (_, __) => ScheduleSetupScreen(fromSetup: fromSetup),
      ),
      GoRoute(
        path: '/setup/order',
        builder: (_, state) => Scaffold(
          body: Text(
            'order-from=${state.uri.queryParameters['from'] ?? 'none'}',
          ),
        ),
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
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
      home: const ScheduleSetupScreen(fromProducts: true),
    ),
  );
}

void main() {
  group('ScheduleSetupScreen', () {
    testWidgets('WeeklyMax morning product shown when selected', (tester) async {
      final product = _weeklyProduct('p1', 'סרום ויטמין C');
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
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
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);

      await tester.pumpWidget(
        _wrap(master: _master([product]), udr: udr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      expect(find.text('order-from=setup'), findsOneWidget);
    });

    testWidgets('tapping weekday chip calls upsertSchedule', (tester) async {
      final product = _weeklyProduct('p1', 'סרום');
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);

      // Use direct wrapper to avoid GoRouter's navigation barrier at scroll depth
      await tester.pumpWidget(_wrapDirect(master: _master([product]), udr: udr));
      await tester.pumpAndSettle();

      // Weekly product is in the "לפי תדירות" list as a collapsed _ListRow.
      // Tap the row to expand it and reveal the WeekdayPicker.
      await tester.tap(find.text('סרום'));
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

    testWidgets('issues panel is expanded by default when conflicts exist',
        (tester) async {
      /// Given: Two morning products with a conflict rule, both scheduled on Sunday
      final product1 = _dailyProduct('p1', 'סרום ויטמין C');
      final product2 = _dailyProduct('p2', 'נייר רך');

      final conflictRule = IncompatibilityRule(
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
          // Both products scheduled on Sunday (day 0)
          WeekdaySchedule(
            id: 's1',
            productId: 'p1',
            slot: Slot.morning,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
          WeekdaySchedule(
            id: 's2',
            productId: 'p2',
            slot: Slot.morning,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      /// When: The screen loads with conflicting products
      await tester.pumpWidget(_wrapDirect(master: master, udr: udr));
      await tester.pumpAndSettle();

      /// Then: The issues panel should be VISIBLE (expanded) by default
      // The issues panel header shows "התראה אחת" (one alert) when there's 1 issue
      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;
      expect(find.text(l.scheduleAlertsOne), findsOneWidget);

      // When expanded, the conflict section header should be visible
      expect(find.text(l.scheduleConflictsSection), findsOneWidget);
    });

    testWidgets('issues panel re-opens after switching slot',
        (tester) async {
      /// Given: Morning products with a conflict, and evening products with a
      /// different conflict, both scheduled
      final morningProduct1 = _dailyProduct('pm1', 'סרום ויטמין C');
      final morningProduct2 = _dailyProduct('pm2', 'נייר רך');
      final eveningProduct1 = _dailyProduct('pe1', 'קרם לילה');
      final eveningProduct2 = _dailyProduct('pe2', 'שמן');

      // Setup morning products with morning config
      final morningProd1 = MasterProduct(
        id: 'pm1',
        name: 'סרום ויטמין C',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      final morningProd2 = MasterProduct(
        id: 'pm2',
        name: 'נייר רך',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        morningConfig: const SlotConfig(order: 2, frequencyRule: DailyRule()),
      );

      // Setup evening products with evening config
      final eveningProd1 = MasterProduct(
        id: 'pe1',
        name: 'קרם לילה',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      final eveningProd2 = MasterProduct(
        id: 'pe2',
        name: 'שמן',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        eveningConfig: const SlotConfig(order: 2, frequencyRule: DailyRule()),
      );

      final morningConflict = IncompatibilityRule(
        id: 'rule_morning',
        entityA: RuleTarget(type: RuleTargetType.product, id: 'pm1'),
        entityB: RuleTarget(type: RuleTargetType.product, id: 'pm2'),
        scope: RuleScope.withinSlot,
        reason: 'conflict in morning',
      );

      final eveningConflict = IncompatibilityRule(
        id: 'rule_evening',
        entityA: RuleTarget(type: RuleTargetType.product, id: 'pe1'),
        entityB: RuleTarget(type: RuleTargetType.product, id: 'pe2'),
        scope: RuleScope.withinSlot,
        reason: 'conflict in evening',
      );

      final master = MasterContent(
        products: [morningProd1, morningProd2, eveningProd1, eveningProd2],
        categories: [const Category(id: 'cat1', name: 'לחות', order: 1)],
        rules: [morningConflict, eveningConflict],
        manifest: const MasterListManifest(
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
          // Morning products both on Sunday
          WeekdaySchedule(
            id: 'sched_pm1',
            productId: 'pm1',
            slot: Slot.morning,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
          WeekdaySchedule(
            id: 'sched_pm2',
            productId: 'pm2',
            slot: Slot.morning,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
          // Evening products both on Sunday
          WeekdaySchedule(
            id: 'sched_pe1',
            productId: 'pe1',
            slot: Slot.evening,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
          WeekdaySchedule(
            id: 'sched_pe2',
            productId: 'pe2',
            slot: Slot.evening,
            weekdays: {0},
            lastModified: DateTime(2024, 1, 1),
          ),
        ],
      );

      /// When: The screen loads (starts on morning with conflict)
      await tester.pumpWidget(_wrapDirect(master: master, udr: udr));
      await tester.pumpAndSettle();

      // First, verify morning issues panel is visible/open initially
      final l = AppLocalizations.of(tester.element(find.byType(ScheduleSetupScreen)))!;
      expect(find.text(l.scheduleAlertsOne), findsOneWidget);

      // Tap the evening slot tab to switch to evening
      // The tab switcher should have buttons for morning and evening
      await tester.tap(find.text(l.slotEvening));
      await tester.pumpAndSettle();

      /// Then: The issues panel should re-open (be visible) after switching to evening
      // After switching, the evening issues should be visible (same structure)
      expect(find.text(l.scheduleAlertsOne), findsOneWidget);

      // When expanded, the conflict section header should be visible in evening
      expect(find.text(l.scheduleConflictsSection), findsOneWidget);
    });
  });
}
