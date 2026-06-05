import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
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
  });
}
