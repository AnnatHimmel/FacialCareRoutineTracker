import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/scanned_product_info.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/sub_category.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/product_classifier.dart';
import 'package:skincare_tracker/features/setup/add_custom_product_sheet.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> selectionsUpserted = [];
  final List<WeekdaySchedule> schedulesUpserted = [];
  final List<UserCustomProduct> customUpserted = [];

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value([]);
  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override
  Future<void> upsertSelection(ProductSelection s) async =>
      selectionsUpserted.add(s);
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async =>
      schedulesUpserted.add(s);
  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async =>
      customUpserted.add(p);
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
  @override Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);
  @override Future<OrderOverride?> getEffectiveOrderOverride(
          Slot slot, int weekday) async =>
      null;
  @override Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
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
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test helpers ─────────────────────────────────────────────────────────────

MasterContent _masterWith(
        List<Category> cats, List<SubCategory> subs) =>
    MasterContent(
      products: const [],
      categories: cats,
      subcategories: subs,
      rules: const [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

// A classifier that maps any product mentioning "salicylic" to a salicylic-acid
// exfoliant sub-category under cat-exfoliate.
ProductClassifier _exfoliateClassifier() => ProductClassifier.fromSubcategories([
      {
        'id': 'sub-bha-salicylic',
        'keywords': ['salicylic', 'salicylic acid', 'bha'],
      },
    ]);

// A classifier that classifies nothing — used for tests where we want the
// category-hint fallback path to activate.
ProductClassifier _emptyClassifier() => ProductClassifier.fromSubcategories([]);

Widget _wrap({
  required MasterContent master,
  required UserDataRepository udr,
  required ProductClassifier classifier,
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
      productClassifierProvider.overrideWith((ref) async => classifier),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: const Scaffold(
        body: AddCustomProductSheet(),
      ),
    ),
  );
}

/// Mirror of [_wrap] but opens the sheet pre-filled from a barcode scan.
Widget _wrapScan({
  required MasterContent master,
  required UserDataRepository udr,
  required ProductClassifier classifier,
  required ScannedProductInfo scanInfo,
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
      productClassifierProvider.overrideWith((ref) async => classifier),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: Scaffold(
        body: AddCustomProductSheet(prefillFromScan: scanInfo),
      ),
    ),
  );
}

void main() {
  const exfoliateCat = Category(id: 'cat-exfoliate', name: 'פילינג', order: 3);
  const serumCat = Category(id: 'cat-serum', name: 'סרום', order: 5);
  const spfCat = Category(id: 'cat-spf', name: 'קרם הגנה', order: 9);
  const salicylicSub = SubCategory(
    id: 'sub-bha-salicylic',
    name: 'חומצה סליצילית',
    categoryId: 'cat-exfoliate',
    order: 5,
  );

  // ── Existing test (updated: save button label changed to 'הוספה למדף') ────

  testWidgets(
      'adding a classified exfoliant assigns subCategoryId and seeds a spread schedule',
      (tester) async {
    final udr = _FakeUDR();
    final master = _masterWith(
      [exfoliateCat, serumCat],
      [salicylicSub],
    );

    await tester.pumpWidget(_wrap(
      master: master,
      udr: udr,
      classifier: _exfoliateClassifier(),
    ));
    await tester.pumpAndSettle();

    // Type a name that the classifier resolves to the salicylic sub-category.
    await tester.enterText(
        find.byType(TextField).first, 'Paula\'s Choice 2% BHA Salicylic');
    await tester.pumpAndSettle();

    // Save the product (scroll the sheet up so the CTA is built/visible).
    // NOTE: label was renamed from 'הוספה לשגרה שלי' → 'הוספה למדף'.
    await tester.scrollUntilVisible(
      find.text('הוספה למדף'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('הוספה למדף'));
    await tester.pumpAndSettle();

    // The custom product persisted with the classified sub-category id.
    expect(udr.customUpserted, isNotEmpty,
        reason: 'upsertCustomProduct should have been called');
    final saved = udr.customUpserted.single;
    expect(saved.subCategoryId, 'sub-bha-salicylic');
    expect(saved.categoryId, 'cat-exfoliate');
    // Exfoliants default to weekly-max (capped), not daily.
    expect(saved.isDaily, isFalse);

    // A spread schedule was seeded for the capped product.
    expect(udr.schedulesUpserted, isNotEmpty,
        reason: 'a capped product should seed a default spread schedule');
    final schedule = udr.schedulesUpserted.first;
    expect(schedule.productId, saved.id);
    expect(schedule.weekdays, isNotEmpty);
    // Days must be valid weekday indices.
    for (final d in schedule.weekdays) {
      expect(d, inInclusiveRange(0, 6));
    }
  });

  // ── Group: brand field ─────────────────────────────────────────────────────

  group('brand field', () {
    testWidgets(
        'should save brand when user enters text in the brand field',
        (tester) async {
      // Given: a manual add sheet with exfoliate category available
      // (the exfoliate classifier auto-fills the category so the save button is
      // enabled without manually opening the dropdown).
      final udr = _FakeUDR();
      final master = _masterWith([exfoliateCat, serumCat], [salicylicSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _exfoliateClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types a product name (classifier auto-picks the category)
      await tester.enterText(
          find.byType(TextField).first, 'BHA Salicylic Serum');
      await tester.pumpAndSettle();

      // And: the user types a brand in the brand field (found by its label)
      final brandField = find.descendant(
        of: find.ancestor(
          of: find.text('מותג'),
          matching: find.byType(Column),
        ),
        matching: find.byType(TextField),
      );
      await tester.enterText(brandField, 'The Ordinary');
      await tester.pumpAndSettle();

      // And: the user taps save
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: the saved product has brand == 'The Ordinary'
      expect(udr.customUpserted, isNotEmpty,
          reason: 'upsertCustomProduct should have been called');
      expect(udr.customUpserted.single.brand, 'The Ordinary');
    });

    testWidgets(
        'should save brand as null when user leaves the brand field empty',
        (tester) async {
      // Given: a manual add sheet
      final udr = _FakeUDR();
      final master = _masterWith([exfoliateCat, serumCat], [salicylicSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _exfoliateClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types only a product name (no brand)
      await tester.enterText(
          find.byType(TextField).first, 'BHA Salicylic Serum');
      await tester.pumpAndSettle();
      // Brand field is intentionally left empty.

      // And: the user taps save
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: the saved product has brand == null
      expect(udr.customUpserted, isNotEmpty,
          reason: 'upsertCustomProduct should have been called');
      expect(udr.customUpserted.single.brand, isNull);
    });
  });

  // ── Group: scan prefill variant ───────────────────────────────────────────

  group('scan prefill variant', () {
    // Scan info used across several tests in this group.
    const reliefSunScan = ScannedProductInfo(
      barcode: 'x',
      name: 'Relief Sun: Rice + Probiotics',
      brand: 'Beauty of Joseon',
      imageUrls: ['https://e/x.jpg'],
      ingredients: 'aqua',
    );

    testWidgets(
        'should show scan title and autofill banner and split name/brand into '
        'separate fields', (tester) async {
      // Given: a scan-prefill sheet with a known product
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: reliefSunScan,
      ));
      await tester.pumpAndSettle();

      // Then: the scan-variant title is visible
      expect(
        find.text('מצאנו את המוצר!'),
        findsOneWidget,
        reason: 'scan-variant title should be shown',
      );

      // Then: the autofill banner is visible
      expect(
        find.text('מולא אוטומטית מהסריקה'),
        findsOneWidget,
        reason: 'autofill banner should be shown',
      );

      // Then: the NAME field contains only the product name (NOT brand-prefixed)
      expect(
        find.widgetWithText(TextField, 'Relief Sun: Rice + Probiotics'),
        findsOneWidget,
        reason: 'name field should contain only the name, not brand-prefixed',
      );

      // Then: the BRAND field contains the brand
      expect(
        find.widgetWithText(TextField, 'Beauty of Joseon'),
        findsOneWidget,
        reason: 'brand field should be prefilled with the brand',
      );
    });

    testWidgets(
        'should show replace-photo and remove-photo actions when scan has image',
        (tester) async {
      // Given: a scan with an image URL
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: reliefSunScan, // has imageUrl
      ));
      await tester.pumpAndSettle();

      // Then: the replace-photo action is visible
      expect(
        find.text('החלפת תמונה'),
        findsOneWidget,
        reason: '"החלפת תמונה" action should be shown when scan has an image',
      );

      // Then: the remove-photo action is visible
      expect(
        find.text('הסרה'),
        findsOneWidget,
        reason: '"הסרה" action should be shown when scan has an image',
      );
    });

    testWidgets(
        'should auto-fill category from categoryHint when classifier returns nothing',
        (tester) async {
      // Given: a scan with categoryHint 'sunscreen', master has cat-spf,
      // and a classifier that classifies nothing.
      final udr = _FakeUDR();
      final master = _masterWith([spfCat], []);

      const spfScan = ScannedProductInfo(
        barcode: 'x',
        name: 'Generic SPF',
        brand: null,
        categoryHint: 'sunscreen',
      );

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: spfScan,
      ));
      await tester.pumpAndSettle();

      // When: the user saves without touching the category dropdown
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: the saved product has categoryId == 'cat-spf' (resolved from hint)
      expect(udr.customUpserted, isNotEmpty,
          reason: 'upsertCustomProduct should have been called');
      expect(
        udr.customUpserted.single.categoryId,
        'cat-spf',
        reason: 'category should be auto-filled from categoryHint via '
            'categoryIdFromHint',
      );
    });
  });

  // ── Group: scan multiple-image selection grid ─────────────────────────────

  group('scan multiple images', () {
    const multiImageScan = ScannedProductInfo(
      barcode: 'multi',
      name: 'Multi Image Product',
      brand: 'BrandX',
      imageUrls: [
        'https://e/1.jpg',
        'https://e/2.jpg',
        'https://e/3.jpg',
      ],
    );

    testWidgets(
        'renders the selection heading, every candidate tile, and the '
        '"my own photo" tile when more than one image is found', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: multiImageScan,
      ));
      await tester.pumpAndSettle();

      expect(find.text('נמצאו 3 תמונות לבחירה — בחרו אחת לשמירה'), findsOneWidget,
          reason: 'grid heading with the candidate count must be shown');
      expect(find.text('תמונה משלי'), findsOneWidget,
          reason: 'the "upload my own photo" tile must be present');
      expect(find.byType(CachedNetworkImage), findsNWidgets(3),
          reason: 'one thumbnail per candidate image');
      // The single-image replace control must NOT appear in grid mode.
      expect(find.text('החלפת תמונה'), findsNothing,
          reason: 'single-image controls are replaced by the grid');
    });

    testWidgets(
        'first candidate is selected by default and selecting another keeps '
        'exactly one selected', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: multiImageScan,
      ));
      await tester.pumpAndSettle();

      // Exactly one tile is marked selected initially (the first).
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget,
          reason: 'the first candidate should be selected by default');

      // Tapping a different candidate moves the selection — still exactly one.
      await tester.tap(find.byKey(const ValueKey('scan-image-tile-2')));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget,
          reason: 'selection is single — only one tile is checked at a time');
    });

    testWidgets(
        'a single candidate image shows the single-image preview, not the grid',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);
      const singleScan = ScannedProductInfo(
        barcode: 'one',
        name: 'One Image Product',
        imageUrls: ['https://e/only.jpg'],
      );

      await tester.pumpWidget(_wrapScan(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: singleScan,
      ));
      await tester.pumpAndSettle();

      expect(find.text('החלפת תמונה'), findsOneWidget,
          reason: 'single image keeps the replace/remove preview');
      expect(find.textContaining('תמונות לבחירה'), findsNothing,
          reason: 'the multi-image grid heading must not be shown for one image');
    });
  });

  // ── Group: category / sub-category dropdown order ─────────────────────────

  group('category/sub-category order', () {
    testWidgets(
        'category dropdown is to the right of sub-category in RTL',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      final catX = tester.getCenter(find.text('קטגוריה')).dx;
      final subX = tester.getCenter(find.text('תת־קטגוריה')).dx;
      expect(catX, greaterThan(subX),
          reason: 'Category must render to the right of Sub-category in RTL');
    });
  });

  // ── Group: more details section ────────────────────────────────────────────

  group('more details section', () {
    testWidgets(
        'should show collapsible section header, hide comment field by default, '
        'and reveal it after tapping the header', (tester) async {
      // Given: a plain manual sheet
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      // Then: the collapsible section header is present
      expect(
        find.text('פרטים נוספים (רשות)'),
        findsOneWidget,
        reason: 'collapsible section header should be visible',
      );

      // Then: the comment hint text is NOT visible (section is collapsed)
      // The hint 'הערה אישית על המוצר (לא חובה)' is from customProductCommentHint.
      expect(
        find.text('הערה אישית על המוצר (לא חובה)'),
        findsNothing,
        reason: 'comment field should be hidden when section is collapsed',
      );

      // When: the user taps the section header to expand it
      // (it now lives at the bottom of the form, so bring it into view first).
      await tester.ensureVisible(find.text('פרטים נוספים (רשות)'));
      await tester.tap(find.text('פרטים נוספים (רשות)'));
      await tester.pumpAndSettle();

      // Then: the comment hint text is now visible
      expect(
        find.text('הערה אישית על המוצר (לא חובה)'),
        findsOneWidget,
        reason: 'comment field should appear after expanding the section',
      );
    });
  });

  // ── Group: sub-category dropdown ──────────────────────────────────────────

  group('sub-category dropdown', () {
    const vitcSub = SubCategory(
      id: 'sub-vitc',
      name: 'ויטמין C',
      categoryId: 'cat-serum',
      order: 1,
    );
    const niacinamideSub = SubCategory(
      id: 'sub-niacinamide',
      name: 'ניאצינמיד',
      categoryId: 'cat-serum',
      order: 2,
    );

    testWidgets(
        'sub-category dropdown is always visible — disabled with '
        '"בחרו קטגוריה תחילה" when no category chosen', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], [vitcSub, niacinamideSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      // No category chosen yet → sub-category dropdown is still visible but disabled.
      expect(find.text('תת־קטגוריה'), findsOneWidget,
          reason: 'sub-category label should always be visible');
      expect(find.text('בחרו קטגוריה תחילה'), findsOneWidget,
          reason:
              'disabled hint must be shown when no category selected');

      // Choose the serum category from the dropdown.
      await tester.tap(find.text('בחרו קטגוריה...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('סרום').last);
      await tester.pumpAndSettle();

      // Now the sub-category dropdown shows the "choose sub-category" hint.
      expect(find.text('בחרו תת־קטגוריה...'), findsOneWidget);
    });

    testWidgets(
        'choosing a sub-category persists subCategoryId on save', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], [vitcSub, niacinamideSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'My Serum');
      await tester.pumpAndSettle();

      // Choose category.
      await tester.ensureVisible(find.text('בחרו קטגוריה...'));
      await tester.tap(find.text('בחרו קטגוריה...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('סרום').last);
      await tester.pumpAndSettle();

      // Choose sub-category.
      await tester.ensureVisible(find.text('בחרו תת־קטגוריה...'));
      await tester.tap(find.text('בחרו תת־קטגוריה...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ויטמין C').last);
      await tester.pumpAndSettle();

      // Save.
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.categoryId, 'cat-serum');
      expect(udr.customUpserted.single.subCategoryId, 'sub-vitc');
    });
  });

  // ── Group: slot auto-defaults from classification ─────────────────────────

  group('slot auto-defaults from classification', () {
    const spfSub = SubCategory(
      id: 'sub-spf',
      name: 'הגנה',
      categoryId: 'cat-spf',
      order: 1,
    );
    const retinoidCat = Category(id: 'cat-retinoid', name: 'רטינואיד', order: 4);
    const retinoidSub = SubCategory(
      id: 'sub-retinoid',
      name: 'רטינואיד',
      categoryId: 'cat-retinoid',
      order: 1,
    );
    const cleanserCat = Category(id: 'cat-cleanser', name: 'ניקוי', order: 1);
    const waterCleanserSub = SubCategory(
      id: 'sub-second-cleanser',
      name: 'ניקוי מים',
      categoryId: 'cat-cleanser',
      order: 2,
    );
    const moisturizerCat =
        Category(id: 'cat-moisturizer', name: 'לחות', order: 6);
    const moisturizerSub = SubCategory(
      id: 'sub-moisturizer',
      name: 'לחות',
      categoryId: 'cat-moisturizer',
      order: 1,
    );

    ProductClassifier _spfClassifier() => ProductClassifier.fromSubcategories([
          {'id': 'sub-spf', 'keywords': ['sunscreen', 'spf']},
        ]);
    ProductClassifier _retinoidClassifier() =>
        ProductClassifier.fromSubcategories([
          {'id': 'sub-retinoid', 'keywords': ['retinol', 'retinoid']},
        ]);
    ProductClassifier _cleanserClassifier() =>
        ProductClassifier.fromSubcategories([
          {'id': 'sub-second-cleanser', 'keywords': ['face wash', 'cleanser']},
        ]);
    ProductClassifier _moisturizerClassifier() =>
        ProductClassifier.fromSubcategories([
          {
            'id': 'sub-moisturizer',
            'keywords': ['moisturizer', 'cream', 'lotion']
          },
        ]);

    testWidgets(
        'SPF product auto-defaults to morning-only when classified as cat-spf',
        (tester) async {
      // Given: a manual add sheet with cat-spf and an SPF classifier
      final udr = _FakeUDR();
      final master = _masterWith([spfCat], [spfSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _spfClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types an SPF product name
      await tester.enterText(
          find.byType(TextField).first, 'Daily SPF 50 Sunscreen');
      await tester.pumpAndSettle();

      // And: saves without touching slots
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: saved product is morning-only
      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.inMorning, isTrue,
          reason: 'SPF should default to morning');
      expect(udr.customUpserted.single.inEvening, isFalse,
          reason: 'SPF should NOT default to evening');
    });

    testWidgets(
        'retinoid product auto-defaults to evening-only when classified as cat-retinoid',
        (tester) async {
      // Given: a manual add sheet with cat-retinoid and a retinoid classifier
      final udr = _FakeUDR();
      final master = _masterWith([retinoidCat], [retinoidSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _retinoidClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types a retinoid product name and saves
      await tester.enterText(
          find.byType(TextField).first, 'Retinol 0.1% Serum');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: saved product is evening-only, daily
      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.inMorning, isFalse,
          reason: 'Retinoid should NOT default to morning');
      expect(udr.customUpserted.single.inEvening, isTrue,
          reason: 'Retinoid should default to evening');
      expect(udr.customUpserted.single.isDaily, isTrue,
          reason: 'Retinoid should default to daily');
    });

    testWidgets(
        'cleanser product auto-defaults to evening-only when classified as cat-cleanser',
        (tester) async {
      // Given: a manual add sheet with cat-cleanser and a cleanser classifier
      final udr = _FakeUDR();
      final master = _masterWith([cleanserCat], [waterCleanserSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _cleanserClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types a cleanser product name and saves
      await tester.enterText(find.byType(TextField).first, 'Gentle Face Wash');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: saved product is evening-only, daily
      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.inMorning, isFalse,
          reason: 'Cleanser should NOT default to morning');
      expect(udr.customUpserted.single.inEvening, isTrue,
          reason: 'Cleanser should default to evening');
    });

    testWidgets(
        'moisturizer product auto-defaults to both morning and evening',
        (tester) async {
      // Given: a manual add sheet with cat-moisturizer and a moisturizer classifier
      final udr = _FakeUDR();
      final master = _masterWith([moisturizerCat], [moisturizerSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _moisturizerClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types a moisturizer product name and saves
      await tester.enterText(
          find.byType(TextField).first, 'Daily Moisturizer Cream');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: saved product is both morning and evening
      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.inMorning, isTrue,
          reason: 'Moisturizer should default to morning');
      expect(udr.customUpserted.single.inEvening, isTrue,
          reason: 'Moisturizer should default to evening');
    });

    testWidgets(
        'manual morning toggle on a cleanser is preserved at save',
        (tester) async {
      // Given: a cleanser sheet that auto-classifies to evening-only
      final udr = _FakeUDR();
      final master = _masterWith([cleanserCat], [waterCleanserSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _cleanserClassifier(),
      ));
      await tester.pumpAndSettle();

      // When: the user types a cleanser name (auto-sets evening only)
      await tester.enterText(find.byType(TextField).first, 'Gentle Face Wash');
      await tester.pumpAndSettle();

      // And: the user manually toggles morning on
      await tester.ensureVisible(find.text('שגרת בוקר'));
      await tester.tap(find.text('שגרת בוקר'));
      await tester.pumpAndSettle();

      // And: saves
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      // Then: both morning and evening are on — manual tap preserved, auto-default kept
      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.inMorning, isTrue,
          reason: 'morning should be on after manual toggle');
      expect(udr.customUpserted.single.inEvening, isTrue,
          reason: 'evening should still be on from auto-default');
    });
  });

  // ── Group: more-details section position ──────────────────────────────────

  group('more-details section position', () {
    testWidgets(
        '"more details" header sits below the frequency section and above the '
        'save button', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      final freqY = tester.getTopLeft(find.text('תדירות שימוש')).dy;
      final detailsY =
          tester.getTopLeft(find.text('פרטים נוספים (רשות)')).dy;
      final saveY = tester.getTopLeft(find.text('הוספה למדף')).dy;

      expect(detailsY, greaterThan(freqY),
          reason: 'advanced section must come after frequency');
      expect(detailsY, lessThan(saveY),
          reason: 'advanced section must be just before the add button');
    });
  });

  // ── Group: category hint l10n ─────────────────────────────────────────────

  group('category hint l10n', () {
    testWidgets(
        'should show the updated category dropdown hint and not the old one',
        (tester) async {
      // Given: a fresh manual sheet with categories available
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      // Then: the new hint 'בחרו קטגוריה...' is visible
      expect(
        find.text('בחרו קטגוריה...'),
        findsOneWidget,
        reason: 'category dropdown should show updated Hebrew hint',
      );

      // Then: the old hint 'בחר...' is NOT visible
      expect(
        find.text('בחר...'),
        findsNothing,
        reason: 'old hardcoded hint should be replaced',
      );
    });
  });

  // ── Group: new UI — non-scan subtitle, labels, INCI field ────────────────

  group('non-scan subtitle and required labels', () {
    testWidgets('non-scan mode shows the form subtitle', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('מלאו את פרטי המוצר. שדות עם * הם חובה.'),
        findsOneWidget,
        reason: 'non-scan subtitle must be shown in plain manual mode',
      );
    });

    testWidgets('slot label shows "מתי משתמשים בו?"', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('מתי משתמשים בו?'), findsOneWidget,
          reason: 'slot label should read "מתי משתמשים בו?"');
    });

    testWidgets('frequency label shows "תדירות שימוש"', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('תדירות שימוש'), findsOneWidget,
          reason: 'frequency label should read "תדירות שימוש"');
    });

    testWidgets(
        'frequency pills show "כל יום" and "שבועי"', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('כל יום'), findsOneWidget,
          reason: 'daily frequency pill should show "כל יום"');
      expect(find.text('שבועי'), findsOneWidget,
          reason: 'weekly frequency pill should show "שבועי"');
    });

    testWidgets('slot pills show "שגרת בוקר" and "שגרת ערב"',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('שגרת בוקר'), findsOneWidget,
          reason: 'morning slot pill should show "שגרת בוקר"');
      expect(find.text('שגרת ערב'), findsOneWidget,
          reason: 'evening slot pill should show "שגרת ערב"');
    });
  });

  group('INCI ingredients field', () {
    testWidgets(
        'INCI field is present inside more-details when expanded',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      // Expand more-details section.
      await tester.ensureVisible(find.text('פרטים נוספים (רשות)'));
      await tester.tap(find.text('פרטים נוספים (רשות)'));
      await tester.pumpAndSettle();

      expect(find.text('רכיבים (INCI)'), findsOneWidget,
          reason: 'INCI label must appear inside the expanded more-details');
      expect(find.text('מפרידים בפסיקים בין הרכיבים'), findsOneWidget,
          reason: 'INCI helper text must appear');
    });

    testWidgets(
        'INCI value is persisted on save when the user types ingredients',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([exfoliateCat, serumCat], [salicylicSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _exfoliateClassifier(),
      ));
      await tester.pumpAndSettle();

      // Type a name (classifier auto-picks category so save is enabled).
      await tester.enterText(
          find.byType(TextField).first, 'Paula\'s Choice BHA Salicylic');
      await tester.pumpAndSettle();

      // Expand more-details and fill INCI field.
      await tester.ensureVisible(find.text('פרטים נוספים (רשות)'));
      await tester.tap(find.text('פרטים נוספים (רשות)'));
      await tester.pumpAndSettle();

      // Find the INCI text field by its hint text.
      final inciField = find.widgetWithText(TextField, 'Aqua, Glycerin, Niacinamide...');
      expect(inciField, findsOneWidget,
          reason: 'INCI hint should identify the field');
      await tester.enterText(inciField, 'Aqua, Salicylic Acid, Niacinamide');
      await tester.pumpAndSettle();

      // Save.
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      expect(udr.customUpserted, isNotEmpty,
          reason: 'upsertCustomProduct should have been called');
      expect(udr.customUpserted.single.ingredients,
          'Aqua, Salicylic Acid, Niacinamide',
          reason: 'ingredients should be persisted on the saved product');
    });

    testWidgets(
        'INCI value is null when user leaves the field empty',
        (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([exfoliateCat, serumCat], [salicylicSub]);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _exfoliateClassifier(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byType(TextField).first, 'Paula\'s Choice BHA Salicylic');
      await tester.pumpAndSettle();

      // Save without entering ingredients.
      await tester.scrollUntilVisible(
        find.text('הוספה למדף'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('הוספה למדף'));
      await tester.pumpAndSettle();

      expect(udr.customUpserted, isNotEmpty);
      expect(udr.customUpserted.single.ingredients, isNull,
          reason: 'empty INCI field should save as null');
    });
  });

  // ── Group: scan variant — scan again ─────────────────────────────────────
  //
  // These tests exercise the NEW `onScanAgain` parameter on AddCustomProductSheet.
  // The parameter does NOT exist yet — this file will not compile until the
  // coder adds:
  //   final VoidCallback? onScanAgain;
  // to AddCustomProductSheet and wires up the "סריקה נוספת" action so it is
  // shown only when prefillFromScan != null && onScanAgain != null.

  group('scan variant — scan again', () {
    // Scan info shared across the tests in this group.
    const _reliefSunScan = ScannedProductInfo(
      barcode: 'scan-again-barcode',
      name: 'Relief Sun: Rice + Probiotics',
      brand: 'Beauty of Joseon',
    );

    /// Builds a scan-prefill sheet AND wires up an [onScanAgain] callback.
    Widget _wrapScanWithAgain({
      required MasterContent master,
      required UserDataRepository udr,
      required ProductClassifier classifier,
      required ScannedProductInfo scanInfo,
      VoidCallback? onScanAgain,
    }) {
      return ProviderScope(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
          userDataRepositoryProvider.overrideWithValue(udr),
          productClassifierProvider.overrideWith((ref) async => classifier),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he'),
          home: Scaffold(
            body: AddCustomProductSheet(
              prefillFromScan: scanInfo,
              // NEW param — does not exist yet; compile will fail = RED
              onScanAgain: onScanAgain,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'scan-prefill sheet with onScanAgain provided shows "סריקה נוספת"',
        (tester) async {
      // Given: the sheet is opened in scan-prefill mode
      // And:   an onScanAgain callback is provided
      // When:  the sheet renders
      // Then:  the "סריקה נוספת" action is visible
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrapScanWithAgain(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: _reliefSunScan,
        onScanAgain: () {},
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('סריקה נוספת'),
        findsOneWidget,
        reason: '"סריקה נוספת" action must be shown when onScanAgain is provided',
      );
    });

    testWidgets(
        'tapping "סריקה נוספת" invokes the onScanAgain callback exactly once',
        (tester) async {
      // Given: the sheet is in scan-prefill mode with onScanAgain wired up
      // When:  the user taps "סריקה נוספת"
      // Then:  the callback is invoked exactly once
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);
      int callCount = 0;

      await tester.pumpWidget(_wrapScanWithAgain(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
        scanInfo: _reliefSunScan,
        onScanAgain: () => callCount++,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('סריקה נוספת'));
      await tester.pumpAndSettle();

      expect(
        callCount,
        1,
        reason: 'onScanAgain callback must be invoked exactly once on tap',
      );
    });

    testWidgets(
        'plain manual sheet (no prefill, no onScanAgain) does NOT show '
        '"סריקה נוספת"', (tester) async {
      // Given: the sheet is opened in plain manual mode (no scan prefill)
      // And:   no onScanAgain callback is provided
      // When:  the sheet renders
      // Then:  the "סריקה נוספת" action is NOT present
      final udr = _FakeUDR();
      final master = _masterWith([serumCat], []);

      await tester.pumpWidget(_wrap(
        master: master,
        udr: udr,
        classifier: _emptyClassifier(),
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('סריקה נוספת'),
        findsNothing,
        reason: '"סריקה נוספת" must NOT appear in plain manual mode',
      );
    });
  });
}
