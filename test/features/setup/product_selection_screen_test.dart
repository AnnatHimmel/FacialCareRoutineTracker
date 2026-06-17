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
import 'package:skincare_tracker/domain/entities/collection_item.dart';
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
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();

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
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();

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
    testWidgets('shows all products in guided step (V3 unified view)',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'ג׳ל ניקוי', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // V3 shows all products in the unified popular list (not per-category)
      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
    });

    testWidgets('search tab is active by default with tab toggle visible',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // Both products visible in default popular list
      expect(find.text('קרם'), findsOneWidget);
      expect(find.text('קרם הגנה'), findsOneWidget);
      // Tab toggle is present
      expect(find.text('חיפוש'), findsOneWidget);
      expect(find.text('סריקה'), findsOneWidget);
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

    testWidgets('fixed AM product shows "בוקר בלבד" chip in browse mode',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'VC סרום', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.text('בוקר בלבד'), findsOneWidget);
    });

    testWidgets('fixed PM product shows "ערב בלבד" chip in browse mode',
        (tester) async {
      final master =
          _masterWith([_pmProduct('p1', 'שמן לילה', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.text('ערב בלבד'), findsOneWidget);
    });

    testWidgets('flexible product shows no fixed-slot chip', (tester) async {
      final master =
          _masterWith([_flexProduct('p1', 'קרם לחות', 'cat-serum')], [cat1]);

      // V3 guided mode: no slot chips at all (simplified finder row)
      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('בוקר בלבד'), findsNothing);
      expect(find.text('ערב בלבד'), findsNothing);
    });
  });

  group('ProductSelectionScreen — last step navigation', () {
    testWidgets('"סידור המדף שלי" is the CTA in guided step view',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: true));
      await tester.pumpAndSettle();

      expect(find.text('סידור המדף שלי'), findsOneWidget);
    });

    testWidgets(
        'tapping "סידור המדף שלי" with fromSetup navigates to /setup/schedule?from=setup',
        (tester) async {
      final t = DateTime(2025);
      final preSel = ProductSelection(
        id: 's1',
        productId: 'p1',
        slot: Slot.morning,
        isSelected: true,
        lastModified: t,
      );
      final udr = _CapturingUDR({Slot.morning: [preSel], Slot.evening: []});
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, udr: udr, fromSetup: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      expect(find.text('schedule-from=setup'), findsOneWidget);
    });

    testWidgets('first step of multi-category flow does NOT show "המשיכי לתזמון"',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
      ], [cat1, cat2]);

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

  group('ProductSelectionScreen — add custom product CTA', () {
    testWidgets('add manual link is visible in guided step view', (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם לחות', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('לא מצאתם? הוסיפו ידנית'), findsOneWidget);
    });

    testWidgets('old small icon-only add button is NOT in guided bottom bar',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם לחות', 'cat-serum')], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // The old button was a 52×52 circle with Icons.add_rounded
      // After the change there should only be ONE add_rounded icon
      // (inside the CTA card itself), not two
      final addIcons = find.byIcon(Icons.add_rounded);
      expect(addIcons, findsOneWidget,
          reason: 'Only the CTA card icon should remain; old bottom-bar button removed');
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

  // ── Browse mode (isTabDestination: true) ─────────────────────────────────────

  group('ProductSelectionScreen — browse mode renders', () {
    testWidgets('shows search field when isTabDestination', (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows slot filter chips in browse mode', (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      // All three chips should be present
      expect(find.text('הכל'), findsOneWidget);
      expect(find.text('בוקר'), findsOneWidget);
      expect(find.text('ערב'), findsOneWidget);
    });

    testWidgets('all products across multiple categories visible at once',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      // Both products visible at once (no step-by-step)
      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('קרם הגנה'), findsOneWidget);
    });

    testWidgets('guided step-by-step view is NOT shown when isTabDestination',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם', 'cat-serum'),
        _amProduct('p2', 'הגנה', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      // Progress bar is only rendered in guided mode — should be absent
      expect(find.text('המשיכי לתזמון'), findsNothing);
      expect(find.text('דלגי על השלב'), findsNothing);
    });

    testWidgets('add custom product CTA is visible in browse mode',
        (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.text('הוסיפי מוצר חדש'), findsOneWidget);
    });
  });

  group('ProductSelectionScreen — browse mode search', () {
    testWidgets('search query filters products by name', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
        _amProduct('p3', 'שמן ורדים', 'cat-serum'),
      ], [cat1, cat2]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'קרם');
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('קרם הגנה'), findsOneWidget);
      expect(find.text('שמן ורדים'), findsNothing);
    });

    testWidgets('search is case-insensitive for Latin brand names',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'CeraVe Cleanser', 'cat-serum'),
        _amProduct('p2', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'cerave');
      await tester.pumpAndSettle();

      expect(find.text('CeraVe Cleanser'), findsOneWidget);
      expect(find.text('קרם לחות'), findsNothing);
    });

    testWidgets('empty search shows all products', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'קרם הגנה', 'cat-spf'),
      ], [cat1, cat2]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'קרם');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('קרם הגנה'), findsOneWidget);
    });

    testWidgets('no-match search shows empty state', (tester) async {
      final master =
          _masterWith([_amProduct('p1', 'קרם', 'cat-serum')], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xxxxxx');
      await tester.pumpAndSettle();

      expect(find.text('קרם'), findsNothing);
    });
  });

  group('ProductSelectionScreen — browse mode slot filter', () {
    testWidgets('morning filter hides evening-only products', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם בוקר', 'cat-serum'),   // morning only
        _pmProduct('p2', 'קרם לילה', 'cat-serum'),   // evening only
        _flexProduct('p3', 'קרם גמיש', 'cat-serum'), // both slots
      ], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      // Tap the "בוקר" chip
      await tester.tap(find.text('בוקר'));
      await tester.pumpAndSettle();

      expect(find.text('קרם בוקר'), findsOneWidget);
      expect(find.text('קרם גמיש'), findsOneWidget);
      expect(find.text('קרם לילה'), findsNothing);
    });

    testWidgets('evening filter hides morning-only products', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם בוקר', 'cat-serum'),
        _pmProduct('p2', 'קרם לילה', 'cat-serum'),
        _flexProduct('p3', 'קרם גמיש', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ערב'));
      await tester.pumpAndSettle();

      expect(find.text('קרם לילה'), findsOneWidget);
      expect(find.text('קרם גמיש'), findsOneWidget);
      expect(find.text('קרם בוקר'), findsNothing);
    });

    testWidgets('tapping active morning chip again returns to "all"',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם בוקר', 'cat-serum'),
        _pmProduct('p2', 'קרם לילה', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בוקר'));
      await tester.pumpAndSettle();
      expect(find.text('קרם לילה'), findsNothing);

      // Tap "בוקר" again → toggle off → back to all
      await tester.tap(find.text('בוקר'));
      await tester.pumpAndSettle();
      expect(find.text('קרם לילה'), findsOneWidget);
    });

    testWidgets('deprecated products are hidden in browse mode', (tester) async {
      final deprecated = MasterProduct(
        id: 'p_old',
        name: 'מוצר ישן',
        categoryId: 'cat-serum',
        isDeprecated: true,
        addedInVersion: '1.0.0',
        morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      final master = _masterWith([
        _amProduct('p1', 'קרם טוב', 'cat-serum'),
        deprecated,
      ], [cat1]);

      await tester.pumpWidget(
          _wrap(master: master, isTabDestination: true));
      await tester.pumpAndSettle();

      expect(find.text('קרם טוב'), findsOneWidget);
      expect(find.text('מוצר ישן'), findsNothing);
    });
  });
}
