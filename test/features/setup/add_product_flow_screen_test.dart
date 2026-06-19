import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
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
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/setup/add_product_flow_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> upserted = [];
  final List<WeekdaySchedule> schedulesUpserted = [];

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value([]);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) async =>
      upserted.add(s);

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async =>
      schedulesUpserted.add(s);

  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}

  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() =>
      throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) =>
      throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) =>
      throw UnimplementedError();

  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      Stream.value([]);
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      Stream.value(null);
  @override Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) =>
      throw UnimplementedError();

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
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
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test helpers ─────────────────────────────────────────────────────────────

MasterProduct _amProduct(String id, String name, String catId) => MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterProduct _pmProduct(String id, String name, String catId) => MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

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
}) {
  final router = GoRouter(
    initialLocation: '/add-product',
    routes: [
      GoRoute(
        path: '/add-product',
        builder: (_, __) => const AddProductFlowScreen(),
      ),
      GoRoute(
        path: '/today',
        builder: (_, __) => const Scaffold(body: Text('today')),
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
  final cat1 = const Category(id: 'cat-serum', name: 'סרום', order: 5);
  final cat2 = const Category(id: 'cat-moisturizer', name: 'לחות', order: 6);

  group('AddProductFlowScreen — step 1 (search)', () {
    testWidgets('renders step 1 with search field', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // Step 1 shows a search field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('products are listed in step 1', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'ג׳ל ניקוי', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
    });

    testWidgets('deprecated products are hidden in step 1', (tester) async {
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

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('קרם טוב'), findsOneWidget);
      expect(find.text('מוצר ישן'), findsNothing);
    });

    testWidgets('searching filters products by name', (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
        _amProduct('p2', 'ג׳ל ניקוי', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'קרם');
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsNothing);
    });
  });

  group('AddProductFlowScreen — wizard advancement', () {
    testWidgets('tapping a product advances to step 2 (category confirm)',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();

      // Step 2 shows the category confirmation title key
      expect(find.text('לאיזה שלב המוצר שייך?'), findsOneWidget);
    });

    testWidgets('step 2 shows category chip for the product category',
        (tester) async {
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();

      // Category name shown as chip
      expect(find.text('סרום'), findsWidgets);
    });

    testWidgets('advancing from step 2 reaches slot choice step',
        (tester) async {
      final master = _masterWith([
        _flexProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      // Step 1: pick product
      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();

      // Step 2: tap CTA to go to step 3
      final cta = find.byType(ElevatedButton).last;
      // Use the primary button which is the main CTA
      // In step 2 the bottom CTA advances the wizard
      await tester.tap(find.text('המשך'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Step 3: slot choice
      expect(find.text('מתי משתמשים במוצר?'), findsOneWidget);
    });
  });

  group('AddProductFlowScreen — slot step', () {
    Future<void> _navigateToSlotStep(
        WidgetTester tester, MasterContent master) async {
      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();
      // Step 1: select product
      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();
      // Step 2: advance
      await tester.tap(find.text('המשך'), warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    testWidgets('slot step shows morning and evening options for flex product',
        (tester) async {
      final master = _masterWith([
        _flexProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await _navigateToSlotStep(tester, master);

      expect(find.text('בוקר'), findsWidgets);
      expect(find.text('ערב'), findsWidgets);
      expect(find.text('שניהם'), findsOneWidget);
    });
  });

  group('AddProductFlowScreen — save flow', () {
    testWidgets('completing all steps calls upsertSelection and upsertSchedule',
        (tester) async {
      final udr = _FakeUDR();
      // Use AM-only product: slot step is auto-skipped (step 3 never shown).
      // Wizard path: search -> category -> days -> placement -> save.
      final master = _masterWith([
        _amProduct('p1', 'קרם לחות', 'cat-serum'),
      ], [cat1]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Step 1: select product
      await tester.tap(find.text('קרם לחות'));
      await tester.pumpAndSettle();

      // Step 2 (category): advance
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      // Step 3 (slot) is skipped for AM-only product; now on step 4 (days)
      expect(find.text('באילו ימים?'), findsOneWidget);
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      // Step 5: placement
      expect(find.text('המיקום המוצע'), findsOneWidget);
      await tester.tap(find.text('הוספה לשגרה'));
      await tester.pumpAndSettle();

      // Selection and schedule must have been persisted
      expect(udr.upserted, isNotEmpty,
          reason: 'upsertSelection should have been called');
      expect(udr.schedulesUpserted, isNotEmpty,
          reason: 'upsertSchedule should have been called');
    });
  });
}
