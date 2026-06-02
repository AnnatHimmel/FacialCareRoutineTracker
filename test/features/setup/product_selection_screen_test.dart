import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/shared/widgets/glass_bottom_nav.dart';
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
import 'package:skincare_tracker/features/setup/product_selection_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  bool upsertCalled = false;
  ProductSelection? lastUpserted;

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value([]);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) async {
    upsertCalled = true;
    lastUpserted = s;
  }

  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}

  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}

  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) =>
      throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      throw UnimplementedError();
  @override Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) =>
      throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override Stream<List<DayRecord>> watchAllDayRecords() =>
      throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) =>
      throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) =>
      throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() =>
      throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() =>
      throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) =>
      throw UnimplementedError();
}

// Fake that pre-loads specific selections and captures all upsert calls.
class _CapturingUDR implements UserDataRepository {
  final Map<Slot, List<ProductSelection>> _initial;
  final List<ProductSelection> captured = [];

  _CapturingUDR(this._initial);

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(_initial[slot] ?? []);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) async => captured.add(s);

  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}

  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}

  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) =>
      throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      throw UnimplementedError();
  @override Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) =>
      throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override Stream<List<DayRecord>> watchAllDayRecords() =>
      throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) =>
      throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) =>
      throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() =>
      throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() =>
      throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) =>
      throw UnimplementedError();
}

// ── Test data helpers ─────────────────────────────────────────────────────────

// Morning-only product (fixed to AM)
MasterProduct _amProduct(String id, String name, String catId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

// Evening-only product (fixed to PM)
MasterProduct _pmProduct(String id, String name, String catId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

// Flexible product (usable AM and PM)
MasterProduct _flexProduct(String id, String name, String catId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _masterWith(
        List<MasterProduct> products, List<Category> cats) =>
    MasterContent(
      products: products,
      categories: cats,
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({
  required MasterContent master,
  UserDataRepository? udr,
  bool fromSetup = false,
  bool isTabDestination = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/selection',
    routes: [
      GoRoute(
        path: '/setup/selection',
        builder: (_, __) => ProductSelectionScreen(
          fromSetup: fromSetup,
          isTabDestination: isTabDestination,
        ),
      ),
      GoRoute(
        path: '/setup/schedule',
        builder: (_, state) => Scaffold(
          body: Text(
            'schedule-from=${state.uri.queryParameters['from'] ?? 'none'}',
          ),
        ),
      ),
      GoRoute(
        path: '/products/schedule',
        builder: (_, __) => const Scaffold(body: Text('products-schedule')),
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
      locale: const Locale('he'),
    ),
  );
}

void main() {
  // Categories for tests
  final cat1 = const Category(id: 'cat-serum', name: 'סרום', order: 5);
  final cat2 = const Category(id: 'cat-spf', name: 'הגנה', order: 8);

  group('ProductSelectionScreen — guided step', () {
    testWidgets('shows products for current category only', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'ג׳ל ניקוי', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // Step 0 = cat-serum (order 5) shown first
      expect(find.text('קרם לחות'), findsOneWidget);
      // cat-spf products are not shown yet (different step)
      expect(find.text('ג׳ל ניקוי'), findsNothing);
    });

    testWidgets('"דלג לסיכום" button is visible and navigates to summary',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('דלגי לסיכום'), findsOneWidget);
      await tester.tap(find.text('דלגי לסיכום'));
      await tester.pumpAndSettle();

      // Summary shows "סיכום · הארון שלך"
      expect(find.text('סיכום · הארון שלך'), findsOneWidget);
    });

    testWidgets('"המשך" advances to next category', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // Initially cat-serum step
      expect(find.text('קרם'), findsOneWidget);
      expect(find.text('קרם הגנה'), findsNothing);

      // "דלג על השלב" because no selection yet
      await tester.tap(find.text('דלגי על השלב'));
      await tester.pumpAndSettle();

      // Now cat-spf step
      expect(find.text('קרם הגנה'), findsOneWidget);
      expect(find.text('קרם'), findsNothing);
    });

    testWidgets('tapping product row calls upsertSelection', (tester) async {
      final udr = _FakeUDR();
      final master =
          _masterWith([_amProduct('p1', 'קרם לחות', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Tap the product row (identified by its text)
      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();

      expect(udr.upsertCalled, isTrue);
    });

    testWidgets('fixed AM product shows "בוקר בלבד" chip', (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'VC סרום', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('בוקר בלבד'), findsOneWidget);
    });

    testWidgets('fixed PM product shows "ערב בלבד" chip', (tester) async {
      final master =
          _masterWith([_pmProduct('p1', 'שמן לילה', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('ערב בלבד'), findsOneWidget);
    });

    testWidgets('flexible product shows no fixed-slot chip', (tester) async {
      final master =
          _masterWith([_flexProduct('p1', 'קרם לחות', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('בוקר בלבד'), findsNothing);
      expect(find.text('ערב בלבד'), findsNothing);
    });
  });

  group('ProductSelectionScreen — summary view', () {
    testWidgets('"המשך לתזמון" visible in summary after navigating there',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: true));
      await tester.pumpAndSettle();

      // Navigate to summary
      await tester.tap(find.text('דלגי לסיכום'));
      await tester.pumpAndSettle();

      expect(find.text('המשיכי לתזמון'), findsOneWidget);
    });

    testWidgets(
        '"המשך לתזמון" from summary with fromSetup navigates to /setup/schedule?from=setup',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('דלגי לסיכום'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי לתזמון'));
      await tester.pumpAndSettle();

      expect(find.text('schedule-from=setup'), findsOneWidget);
    });

    testWidgets('guided step does NOT show "המשך לתזמון" initially',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: false));
      await tester.pumpAndSettle();

      expect(find.text('המשיכי לתזמון'), findsNothing);
    });
  });

  group('ProductSelectionScreen — duplicate-record deselection', () {
    // Regression: if the DB somehow holds two isSelected:true rows for the
    // same product+slot, tapping to deselect must update BOTH rows, not just
    // the first one (which would leave the product appearing selected).
    testWidgets('deselecting updates every duplicate record', (tester) async {
      final t = DateTime(2025);
      final dup1 = ProductSelection(
          id: 'uuid-1', productId: 'p1', slot: Slot.evening,
          isSelected: true, lastModified: t);
      final dup2 = ProductSelection(
          id: 'uuid-2', productId: 'p1', slot: Slot.evening,
          isSelected: true, lastModified: t);

      final udr = _CapturingUDR({Slot.evening: [dup1, dup2], Slot.morning: []});
      final product = _pmProduct('p1', 'שמן לילה', 'cat-serum');
      final master = _masterWith([product], [cat1]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Tap the product row in the guided view — it should be shown selected
      // (both duplicates contribute isSelected:true to selMap)
      await tester.tap(find.text('שמן לילה'));
      await tester.pumpAndSettle();

      // Both duplicate records must have been deselected
      final deselected = udr.captured.where((s) => !s.isSelected).toList();
      expect(deselected.length, 2,
          reason: 'both duplicate rows must be set to isSelected:false');
      expect(deselected.map((s) => s.id).toSet(), {'uuid-1', 'uuid-2'});
    });
  });

  group('ProductSelectionScreen — shell integration', () {
    testWidgets('isTabDestination: true → no standalone GlassBottomNav',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomNav), findsNothing);
    });

    testWidgets('isTabDestination: false → no standalone GlassBottomNav',
        (tester) async {
      // The screen itself no longer owns a bottom nav —
      // that is provided by the shell. Either way, no GlassBottomNav here.
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: false));
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomNav), findsNothing);
    });
  });
}
