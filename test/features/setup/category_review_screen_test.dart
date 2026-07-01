import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/core/theme/app_colors.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';
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
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/setup/category_review_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';
import 'package:skincare_tracker/shared/widgets/primary_button.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  List<ProductSelection> morning;
  List<ProductSelection> evening;

  _FakeUDR({this.morning = const [], this.evening = const []});

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(slot == Slot.morning ? morning : evening);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override
  Future<void> upsertSelection(ProductSelection s) async {
    morning = morning.map((e) => e.id == s.id ? s : e).toList();
    evening = evening.map((e) => e.id == s.id ? s : e).toList();
  }
  @override
  Future<void> muteConflict(MutedConflict m) async {}
  @override
  Future<void> unmuteConflict(String ruleId) async {}
  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override
  Future<void> deleteCustomProduct(String id) async {}
  @override
  Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override
  Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override
  Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override
  Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => throw UnimplementedError();
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override
  Stream<OrderOverride?> watchOrderOverride(Slot s) => throw UnimplementedError();
  @override
  Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override
  Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override
  Stream<DayRecord?> watchDayRecord(String d, Slot s) => throw UnimplementedError();
  @override
  Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override
  Future<void> updateDayRecord(DayRecord r) async {}
  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) async {}
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) async {}
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test data ─────────────────────────────────────────────────────────────────

const _cat1 = Category(id: 'cat1', name: 'ניקוי', order: 1);
const _cat2 = Category(id: 'cat2', name: 'לחות', order: 2);
const _sub1 =
    SubCategory(id: 'sub1', name: 'ניקוי עמוק', categoryId: 'cat1', order: 1);
const _sub2 =
    SubCategory(id: 'sub2', name: 'ניקוי עדין', categoryId: 'cat1', order: 2);

MasterProduct _product(String id, String name, String catId,
        {String? subCatId}) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: catId,
      subCategoryId: subCatId,
      isDeprecated: false,
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 'sel_$productId',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024),
    );

MasterContent _masterWith(
  List<MasterProduct> products,
  List<Category> cats, {
  List<SubCategory> subcats = const [],
}) =>
    MasterContent(
      products: products,
      categories: cats,
      subcategories: subcats,
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({
  required MasterContent master,
  List<ProductSelection> morning = const [],
  List<ProductSelection> evening = const [],
  VoidCallback? onBack,
  VoidCallback? onNext,
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(
        _FakeUDR(morning: morning, evening: evening),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: CategoryReviewScreen(
        onBack: onBack ?? () {},
        onNext: onNext ?? () {},
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  final p1 = _product('p1', 'קרם לחות', 'cat2');
  final p2 = _product('p2', 'ג׳ל ניקוי', 'cat1');
  final master = _masterWith([p1, p2], [_cat1, _cat2]);

  group('CategoryReviewScreen', () {
    testWidgets('shows title "סידרנו את המוצרים לפי שלבים"', (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('סידרנו את המוצרים לפי שלבים'), findsOneWidget);
    });

    testWidgets('shows each selected product name', (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning), _sel('p2', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
    });

    testWidgets('does not show unselected products', (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
        // p2 not selected
      ));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsNothing);
    });

    testWidgets('category chip uses calm background — AppColors.surfaceLow',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      final calmChip = find.byWidgetPredicate((w) {
        if (w is Container && w.decoration is BoxDecoration) {
          final dec = w.decoration as BoxDecoration;
          return dec.color == AppColors.surfaceLow;
        }
        return false;
      });
      expect(calmChip, findsWidgets,
          reason: 'Category chip must use AppColors.surfaceLow background');
    });

    testWidgets(
        'change-category button sits below the product name (not squeezing it)',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const longCat = Category(
          id: 'catLong', name: 'קטגוריה עם שם ארוך מאוד לבדיקה', order: 1);
      final longProduct = _product('pLong',
          'מוצר עם שם ארוך מאוד שאמור למלא את כל השורה', 'catLong');
      final longMaster = _masterWith([longProduct], [longCat]);

      await tester.pumpWidget(_wrap(
        master: longMaster,
        morning: [_sel('pLong', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      // No layout overflow with long product + category names.
      expect(tester.takeException(), isNull,
          reason: 'Product review card must not overflow with long names');

      // The change-category control must be on a line below the product name,
      // so the name can use the full row width.
      final nameRect = tester.getRect(find.text('מוצר עם שם ארוך מאוד שאמור למלא את כל השורה'));
      final buttonRect = tester.getRect(find.byIcon(Icons.edit_rounded));
      expect(buttonRect.top, greaterThan(nameRect.bottom),
          reason: 'Change-category button should sit below the product name');
    });

    testWidgets('"שינוי קטגוריה" button is present for each product card',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning), _sel('p2', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.edit_rounded), findsNWidgets(2));
    });

    testWidgets('tapping "שינוי קטגוריה" expands the category picker',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      // Before expand — category picker items not visible
      expect(find.text('ניקוי'), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      // After expand — category options are shown
      expect(find.text('ניקוי'), findsWidgets);
    });

    testWidgets('CTA "המשיכי לבחירת ימים" calls onNext', (tester) async {
      bool nextCalled = false;
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
        onNext: () => nextCalled = true,
      ));
      await tester.pumpAndSettle();

      // Use PrimaryButton to find CTA — text may be off-screen in test viewport
      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
    });

    testWidgets('"הוספת מוצרים נוספים" button calls onBack', (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('הוספת מוצרים נוספים'));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });

    testWidgets('products shown in category order (lower order cat first)',
        (tester) async {
      // cat1 has order=1 (ניקוי), cat2 has order=2 (לחות)
      // p2 is cat1 (ניקוי order=1), p1 is cat2 (לחות order=2)
      // So p2 (ניקוי) should appear before p1 (לחות) in the list
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning), _sel('p2', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      final p1Pos = tester.getTopLeft(find.text('קרם לחות')).dy;
      final p2Pos = tester.getTopLeft(find.text('ג׳ל ניקוי')).dy;
      // p2 (ניקוי, order=1) should appear higher (smaller dy) than p1 (לחות, order=2)
      expect(p2Pos, lessThan(p1Pos),
          reason: 'Products should be sorted by category order');
    });

    // ── Empty-state tests ──────────────────────────────────────────────────────
    // Product removal is no longer available on this screen — the empty path is
    // reached when no products were selected upstream.

    testWidgets('no "הסרה" remove control is rendered on product cards',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning), _sel('p2', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('הסרה'), findsNothing);
    });

    testWidgets('when no products selected, empty state text appears',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        // No selections at all
      ));
      await tester.pumpAndSettle();

      expect(find.text('אין מוצרים במדף עדיין'), findsOneWidget);
    });

    testWidgets(
        'when no products selected, CTA is wrapped in IgnorePointer with ignoring=true',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
      ));
      await tester.pumpAndSettle();

      // At least one IgnorePointer wrapping PrimaryButton must be ignoring
      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(PrimaryButton),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignorePointers.any((ip) => ip.ignoring), isTrue,
          reason: 'CTA should be disabled (IgnorePointer.ignoring=true) when no products');
    });

    testWidgets(
        'when products present, CTA is not disabled (IgnorePointer ignoring=false or absent)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      // Find IgnorePointer ancestors of the PrimaryButton (CTA)
      final ignorePointers = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(PrimaryButton),
          matching: find.byType(IgnorePointer),
        ),
      );
      // No IgnorePointer should be ignoring when products exist
      expect(ignorePointers.every((ip) => !ip.ignoring), isTrue);
    });

    testWidgets(
        'when no products selected, "הוספת מוצרים נוספים" button still reachable',
        (tester) async {
      bool backCalled = false;
      await tester.pumpWidget(_wrap(
        master: master,
        onBack: () => backCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('הוספת מוצרים נוספים'), findsOneWidget);
      await tester.tap(find.text('הוספת מוצרים נוספים'));
      await tester.pumpAndSettle();

      expect(backCalled, isTrue);
    });

    // ── Sub-category display ───────────────────────────────────────────────────

    testWidgets('subcategory chip shown when product has a subCategoryId',
        (tester) async {
      final pWithSub = _product('pSub', 'מוצר עם תת-קטגוריה', 'cat1',
          subCatId: 'sub1');
      final masterWithSub =
          _masterWith([pWithSub], [_cat1], subcats: [_sub1, _sub2]);

      await tester.pumpWidget(_wrap(
        master: masterWithSub,
        morning: [_sel('pSub', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('ניקוי עמוק'), findsOneWidget,
          reason: 'SubCategory name should appear as a chip on the card');
    });

    testWidgets('subcategory chip not shown when product has no subCategoryId',
        (tester) async {
      final pNoSub = _product('pNoSub', 'מוצר ללא תת-קטגוריה', 'cat1');
      final masterNoSub =
          _masterWith([pNoSub], [_cat1], subcats: [_sub1, _sub2]);

      await tester.pumpWidget(_wrap(
        master: masterNoSub,
        morning: [_sel('pNoSub', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      expect(find.text('ניקוי עמוק'), findsNothing);
      expect(find.text('ניקוי עדין'), findsNothing);
    });

    // ── Edit panel: save button ────────────────────────────────────────────────

    testWidgets('save button appears in edit panel when card is expanded',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      // Save button not present before editing
      expect(find.text('שמור'), findsNothing);

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      expect(find.text('שמור'), findsOneWidget);
    });

    testWidgets(
        'tapping save closes the edit panel without navigating away',
        (tester) async {
      await tester.pumpWidget(_wrap(
        master: master,
        morning: [_sel('p1', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      // Panel is open — save button visible
      expect(find.text('שמור'), findsOneWidget);

      await tester.tap(find.text('שמור'));
      await tester.pumpAndSettle();

      // Panel closed — save button gone, card still visible
      expect(find.text('שמור'), findsNothing);
      expect(find.text('קרם לחות'), findsOneWidget);
    });

    // ── Edit panel: subcategory picker ─────────────────────────────────────────

    testWidgets('edit panel shows subcategory picker when category has subcats',
        (tester) async {
      final pSub = _product('pSub', 'ג׳ל ניקוי', 'cat1', subCatId: 'sub1');
      final masterSub =
          _masterWith([pSub], [_cat1, _cat2], subcats: [_sub1, _sub2]);

      await tester.pumpWidget(_wrap(
        master: masterSub,
        morning: [_sel('pSub', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      // Both sub-category options should appear in the picker
      expect(find.text('ניקוי עמוק'), findsWidgets);
      expect(find.text('ניקוי עדין'), findsWidgets);
    });

    testWidgets(
        'changing category in edit panel resets subcategory draft to null',
        (tester) async {
      final pSub = _product('pSub', 'ג׳ל ניקוי', 'cat1', subCatId: 'sub1');
      final masterSub =
          _masterWith([pSub], [_cat1, _cat2], subcats: [_sub1, _sub2]);

      await tester.pumpWidget(_wrap(
        master: masterSub,
        morning: [_sel('pSub', Slot.morning)],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_rounded).first);
      await tester.pumpAndSettle();

      // Subcategory picker is visible (cat1 has subcats)
      expect(find.text('ניקוי עמוק'), findsWidgets);

      // Tap cat2 (which has no subcategories in test data)
      await tester.tap(find.text('לחות'));
      await tester.pumpAndSettle();

      // Subcategory picker should be gone (cat2 has no subcats)
      expect(find.text('ניקוי עמוק'), findsNothing);
    });
  });
}
