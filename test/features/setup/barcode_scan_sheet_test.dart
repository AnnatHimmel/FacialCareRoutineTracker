import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/data/remote/barcode_lookup_service.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/scanned_product_info.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/setup/barcode_scan_sheet.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FailingMCR implements MasterContentRepository {
  @override
  Future<MasterContent> load() => Future.error(Exception('load failed'));
}

class _TrackingLookupService extends BarcodeProductLookupService {
  int callCount = 0;
  ScannedProductInfo? stubbedResult;

  @override
  Future<ScannedProductInfo?> lookup(String barcode) async {
    callCount++;
    return stubbedResult;
  }
}

// Supports pre-loading specific selections per slot to test duplicate guards.
class _CapturingUDR implements UserDataRepository {
  final Map<Slot, List<ProductSelection>> _initial;
  final List<ProductSelection> captured = [];

  _CapturingUDR([Map<Slot, List<ProductSelection>>? initial])
      : _initial = initial ?? {};

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(_initial[slot] ?? []);

  @override
  Future<void> upsertSelection(ProductSelection s) async => captured.add(s);

  @override Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem i) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
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
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterContent _contentWith(List<MasterProduct> products) => MasterContent(
      products: products,
      categories: [
        const Category(id: 'cat-toner', name: 'טונר', nameEn: 'Toner', order: 1),
      ],
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({
  required MasterContent master,
  required _TrackingLookupService lookup,
  _CapturingUDR? udr,
  required String testBarcode,
  void Function(ScannedProductInfo info)? onExternalProductFound,
}) =>
    ProviderScope(
      overrides: [
        masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
        barcodeProductLookupServiceProvider.overrideWithValue(lookup),
        userDataRepositoryProvider.overrideWithValue(udr ?? _CapturingUDR()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he'),
        home: Scaffold(
          body: BarcodeScanSheet(
            testBarcodeToScan: testBarcode,
            onExternalProductFound: onExternalProductFound,
          ),
        ),
      ),
    );

ProductSelection _selectedIn(String productId, Slot slot) => ProductSelection(
      id: 'existing-$productId-${slot.name}',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2025),
    );

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _matchingBarcode = '8809968130239';

const _morningProduct = MasterProduct(
  id: 'prod-morning',
  name: 'Morning Serum',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  barcodes: [_matchingBarcode],
  morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
  eveningConfig: null,
);

const _eveningProduct = MasterProduct(
  id: 'prod-evening',
  name: 'Evening Cream',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  barcodes: [_matchingBarcode],
  morningConfig: null,
  eveningConfig: SlotConfig(order: 5, frequencyRule: DailyRule()),
);

const _bothSlotsProduct = MasterProduct(
  id: 'prod-both',
  name: 'Rice Toner',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  barcodes: [_matchingBarcode],
  morningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
  eveningConfig: SlotConfig(order: 6, frequencyRule: DailyRule()),
);

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('BarcodeScanSheet — master product matching', () {
    testWidgets(
        'barcode matching a master product shows recognized-product UI '
        'and does NOT call external lookup service', (tester) async {
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();

      expect(find.text('מוצר מוכר'), findsOneWidget);
      expect(find.text('Rice Toner'), findsOneWidget);
      expect(find.text('הוסיפי לשגרה'), findsOneWidget);
      expect(lookup.callCount, 0);
    });

    testWidgets(
        'barcode NOT in master product list falls through to external lookup',
        (tester) async {
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        testBarcode: 'unknown-barcode-999',
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'deprecated product with matching barcode is NOT matched — '
        'falls through to external lookup', (tester) async {
      final deprecated = _bothSlotsProduct.copyWith(isDeprecated: true);
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([deprecated]),
        lookup: lookup,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'master product with empty barcodes list is never matched — '
        'simulates stale cache before barcodes migration', (tester) async {
      final noBarcodes = _bothSlotsProduct.copyWith(barcodes: []);
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([noBarcodes]),
        lookup: lookup,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'master content load failure falls through to external lookup',
        (tester) async {
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(ProviderScope(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(_FailingMCR()),
          barcodeProductLookupServiceProvider.overrideWithValue(lookup),
          userDataRepositoryProvider.overrideWithValue(_CapturingUDR()),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('he'),
          home: Scaffold(
            body: BarcodeScanSheet(testBarcodeToScan: _matchingBarcode),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'product with multiple barcodes — second barcode in list is also matched',
        (tester) async {
      const secondBarcode = '1234567890000';
      final multiBarcode = _bothSlotsProduct.copyWith(
        barcodes: [_matchingBarcode, secondBarcode],
      );
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([multiBarcode]),
        lookup: lookup,
        testBarcode: secondBarcode,
      ));
      await tester.pumpAndSettle();

      expect(find.text('מוצר מוכר'), findsOneWidget);
      expect(lookup.callCount, 0);
    });

    testWidgets(
        'multiple products in content — only the product whose barcode matches '
        'is returned', (tester) async {
      const otherBarcode = '9999999999999';
      final otherProduct = _morningProduct.copyWith(
        id: 'prod-other',
        name: 'Other Product',
        barcodes: [otherBarcode],
      );
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct, otherProduct]),
        lookup: lookup,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();

      expect(find.text('מוצר מוכר'), findsOneWidget);
      expect(find.text('Rice Toner'), findsOneWidget);
      expect(find.text('Other Product'), findsNothing);
      expect(lookup.callCount, 0);
    });

    testWidgets(
        'no master match + external returns data → '
        'calls onExternalProductFound spy with info; '
        'intermediate "מוצר נמצא" card is NOT shown',
        (tester) async {
      // Given: external lookup returns product info
      // When:  barcode is not in master list AND onExternalProductFound is provided
      // Then:  spy is called exactly once with the scanned info;
      //        the intermediate "מוצר נמצא" card never renders
      final lookup = _TrackingLookupService()
        ..stubbedResult = const ScannedProductInfo(
          barcode: 'unknown-barcode-999',
          name: 'External Product',
          brand: 'Some Brand',
        );

      ScannedProductInfo? capturedInfo;
      int spyCallCount = 0;

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        testBarcode: 'unknown-barcode-999',
        onExternalProductFound: (info) {
          spyCallCount++;
          capturedInfo = info;
        },
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(spyCallCount, 1, reason: 'spy must be called exactly once');
      expect(capturedInfo, isNotNull);
      expect(capturedInfo!.barcode, 'unknown-barcode-999');
      expect(capturedInfo!.name, 'External Product');
      expect(find.text('מוצר נמצא'), findsNothing,
          reason: 'intermediate card must not be shown when callback fires');
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'no master match + external returns null → shows productNotFound state',
        (tester) async {
      final lookup = _TrackingLookupService(); // stubbedResult = null

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        testBarcode: 'unknown-barcode-999',
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('המוצר לא נמצא במאגרים'), findsOneWidget);
      expect(find.text('מוצר מוכר'), findsNothing);
    });
  });

  group('BarcodeScanSheet — add to routine', () {
    Future<_CapturingUDR> tapAddAndSettle(
      WidgetTester tester, {
      required MasterProduct product,
      Map<Slot, List<ProductSelection>> existing = const {},
    }) async {
      final udr = _CapturingUDR(existing);
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(_wrap(
        master: _contentWith([product]),
        lookup: lookup,
        udr: udr,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();
      expect(find.text('הוסיפי לשגרה'), findsOneWidget);

      await tester.tap(find.text('הוסיפי לשגרה'));
      await tester.pumpAndSettle();
      return udr;
    }

    testWidgets('morning-only product → upserts only morning selection',
        (tester) async {
      final udr = await tapAddAndSettle(tester, product: _morningProduct);

      expect(udr.captured.length, 1);
      expect(udr.captured.first.productId, 'prod-morning');
      expect(udr.captured.first.slot, Slot.morning);
      expect(udr.captured.first.isSelected, true);
    });

    testWidgets('evening-only product → upserts only evening selection',
        (tester) async {
      final udr = await tapAddAndSettle(tester, product: _eveningProduct);

      expect(udr.captured.length, 1);
      expect(udr.captured.first.productId, 'prod-evening');
      expect(udr.captured.first.slot, Slot.evening);
      expect(udr.captured.first.isSelected, true);
    });

    testWidgets('both-slot product → upserts morning and evening selections',
        (tester) async {
      final udr = await tapAddAndSettle(tester, product: _bothSlotsProduct);

      expect(udr.captured.length, 2);
      final slots = udr.captured.map((s) => s.slot).toSet();
      expect(slots, {Slot.morning, Slot.evening});
      for (final s in udr.captured) {
        expect(s.productId, 'prod-both');
        expect(s.isSelected, true);
      }
    });

    testWidgets(
        'product already selected in morning → only evening is upserted',
        (tester) async {
      final udr = await tapAddAndSettle(
        tester,
        product: _bothSlotsProduct,
        existing: {
          Slot.morning: [_selectedIn('prod-both', Slot.morning)],
        },
      );

      expect(udr.captured.length, 1);
      expect(udr.captured.first.slot, Slot.evening);
    });

    testWidgets(
        'product already selected in evening → only morning is upserted',
        (tester) async {
      final udr = await tapAddAndSettle(
        tester,
        product: _bothSlotsProduct,
        existing: {
          Slot.evening: [_selectedIn('prod-both', Slot.evening)],
        },
      );

      expect(udr.captured.length, 1);
      expect(udr.captured.first.slot, Slot.morning);
    });

    testWidgets(
        'product already selected in both slots → '
        '"already in routine" badge shown, add button hidden, nothing upserted',
        (tester) async {
      final udr = _CapturingUDR({
        Slot.morning: [_selectedIn('prod-both', Slot.morning)],
        Slot.evening: [_selectedIn('prod-both', Slot.evening)],
      });

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: _TrackingLookupService(),
        udr: udr,
        testBarcode: _matchingBarcode,
      ));
      await tester.pumpAndSettle();

      expect(find.text('כבר בשגרה שלך'), findsOneWidget);
      expect(find.text('הוסיפי לשגרה'), findsNothing);
      expect(udr.captured, isEmpty);
    });

    testWidgets(
        'product with isSelected=false in morning is treated as not-in-routine '
        'and gets re-added', (tester) async {
      final deselected = ProductSelection(
        id: 'deselected-morning',
        productId: 'prod-both',
        slot: Slot.morning,
        isSelected: false, // explicitly deselected, not currently active
        lastModified: DateTime(2025),
      );
      final udr = await tapAddAndSettle(
        tester,
        product: _bothSlotsProduct,
        existing: {
          Slot.morning: [deselected],
        },
      );

      // Both slots should be upserted — deselected entry doesn't count as "in routine"
      final slots = udr.captured.map((s) => s.slot).toSet();
      expect(slots, {Slot.morning, Slot.evening});
    });

    testWidgets('each upserted selection has a unique UUID id', (tester) async {
      final udr = await tapAddAndSettle(tester, product: _bothSlotsProduct);

      expect(udr.captured.length, 2);
      final ids = udr.captured.map((s) => s.id).toSet();
      expect(ids.length, 2, reason: 'each selection must have a distinct UUID');
    });
  });

  // ── Gallery scan tests ────────────────────────────────────────────────────────
  //
  // These tests exercise the NEW `testGalleryResult` seam on BarcodeScanSheet.
  // The seam does NOT exist yet — this file will not compile until the coder
  // adds:
  //   @visibleForTesting final ({String? code})? testGalleryResult;
  // to BarcodeScanSheet and wires up the gallery-decode path.

  Widget wrapGallery({
    required MasterContent master,
    required _TrackingLookupService lookup,
    _CapturingUDR? udr,
    required ({String? code})? galleryResult,
    void Function(ScannedProductInfo info)? onExternalProductFound,
  }) =>
      ProviderScope(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
          barcodeProductLookupServiceProvider.overrideWithValue(lookup),
          userDataRepositoryProvider.overrideWithValue(udr ?? _CapturingUDR()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he'),
          home: Scaffold(
            body: BarcodeScanSheet(
              testGalleryResult: galleryResult,
              onExternalProductFound: onExternalProductFound,
            ),
          ),
        ),
      );

  group('BarcodeScanSheet — gallery scan', () {
    testWidgets(
        'gallery decode of a barcode that matches a master product '
        'shows "מוצר מוכר" with product name; external lookup NOT called',
        (tester) async {
      // Given: master list contains a product whose barcode matches the gallery decode
      // When:  widget receives testGalleryResult: (code: _matchingBarcode)
      // Then:  masterProductFound state is shown; external lookup is never called
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(wrapGallery(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        galleryResult: (code: _matchingBarcode),
      ));
      await tester.pumpAndSettle();

      expect(find.text('מוצר מוכר'), findsOneWidget);
      expect(find.text('Rice Toner'), findsOneWidget);
      expect(lookup.callCount, 0,
          reason: 'master match must short-circuit external lookup');
    });

    testWidgets(
        'gallery decode of unknown barcode + external returns data '
        'calls onExternalProductFound spy with info; '
        '"מוצר נמצא" intermediate card is NOT shown; '
        'external lookup called exactly once',
        (tester) async {
      // Given: barcode is NOT in the master list; external service returns data;
      //        onExternalProductFound callback is provided
      // When:  widget receives testGalleryResult: (code: 'unknown-gallery-barcode')
      // Then:  spy fires once with the returned info;
      //        intermediate "מוצר נמצא" card is never rendered;
      //        external lookup called exactly once
      final lookup = _TrackingLookupService()
        ..stubbedResult = const ScannedProductInfo(
          barcode: 'unknown-gallery-barcode',
          name: 'Gallery External Product',
          brand: 'Gallery Brand',
        );

      ScannedProductInfo? capturedInfo;
      int spyCallCount = 0;

      await tester.pumpWidget(wrapGallery(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        galleryResult: (code: 'unknown-gallery-barcode'),
        onExternalProductFound: (info) {
          spyCallCount++;
          capturedInfo = info;
        },
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1,
          reason: 'external lookup must be called for unknown barcode');
      expect(spyCallCount, 1, reason: 'spy must be called exactly once');
      expect(capturedInfo, isNotNull);
      expect(capturedInfo!.barcode, 'unknown-gallery-barcode');
      expect(capturedInfo!.name, 'Gallery External Product');
      expect(find.text('מוצר נמצא'), findsNothing,
          reason: 'intermediate card must not be shown when callback fires');
      expect(find.text('מוצר מוכר'), findsNothing);
    });

    testWidgets(
        'gallery decode of an unknown barcode + external returns null '
        'shows "המוצר לא נמצא במאגרים"; external lookup called exactly once',
        (tester) async {
      // Given: barcode is NOT in master list; external service returns null
      // When:  widget receives testGalleryResult: (code: 'unknown-gallery-barcode-404')
      // Then:  productNotFound state is shown; external lookup called once
      final lookup = _TrackingLookupService(); // stubbedResult = null by default

      await tester.pumpWidget(wrapGallery(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        galleryResult: (code: 'unknown-gallery-barcode-404'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('המוצר לא נמצא במאגרים'), findsOneWidget);
      expect(find.text('מוצר מוכר'), findsNothing);
      expect(lookup.callCount, 1,
          reason: 'external lookup must be called for unknown barcode');
    });

    testWidgets(
        'gallery image with no decodable barcode (code: null) '
        'shows "המוצר לא נמצא במאגרים"; external lookup NOT called',
        (tester) async {
      // Given: the gallery image contained no readable barcode
      // When:  widget receives testGalleryResult: (code: null)
      // Then:  productNotFound state is shown immediately; external lookup skipped
      final lookup = _TrackingLookupService();

      await tester.pumpWidget(wrapGallery(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        galleryResult: (code: null),
      ));
      await tester.pumpAndSettle();

      expect(find.text('המוצר לא נמצא במאגרים'), findsOneWidget);
      expect(lookup.callCount, 0,
          reason: 'no barcode decoded — external lookup must not be called');
    });
  });

  // ── Web/camera-unavailable scanning tests ─────────────────────────────────
  //
  // These tests exercise the NEW `testForceCameraUnavailable` seam on
  // BarcodeScanSheet.  The seam does NOT exist yet — this file will not
  // compile until the coder adds:
  //   @visibleForTesting final bool testForceCameraUnavailable;  // default false
  // to BarcodeScanSheet and wires up the camera-unavailable (web) path so that
  // the scanning state shows a gallery-first view instead of launching the
  // MobileScannerController.

  Widget wrapScanningWeb({
    MasterContent? master,
    _TrackingLookupService? lookup,
    _CapturingUDR? udr,
    void Function(ScannedProductInfo info)? onExternalProductFound,
  }) =>
      ProviderScope(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(
              _FakeMCR(master ?? _contentWith([_bothSlotsProduct]))),
          barcodeProductLookupServiceProvider
              .overrideWithValue(lookup ?? _TrackingLookupService()),
          userDataRepositoryProvider
              .overrideWithValue(udr ?? _CapturingUDR()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he'),
          home: Scaffold(
            body: BarcodeScanSheet(
              // NEW seam — does not exist yet; compile will fail = RED
              testForceCameraUnavailable: true,
              onExternalProductFound: onExternalProductFound,
            ),
          ),
        ),
      );

  group('BarcodeScanSheet — web/camera-unavailable scanning', () {
    testWidgets(
        'with testForceCameraUnavailable:true renders without throwing '
        'and shows gallery button "סריקה מתמונה בגלריה"', (tester) async {
      // Given: camera is forced-unavailable via test seam (simulates web)
      // When:  the sheet is built with testForceCameraUnavailable: true
      //        and no testBarcodeToScan / testGalleryResult provided
      // Then:  the widget renders without error and shows the gallery-first
      //        button labelled "סריקה מתמונה בגלריה"
      await tester.pumpWidget(wrapScanningWeb());
      await tester.pumpAndSettle();

      // The gallery button label is the existing l10n key barcodeScanFromGallery.
      expect(
        find.text('סריקה מתמונה בגלריה'),
        findsOneWidget,
        reason: 'camera-unavailable view must show gallery-first button',
      );
    });

    testWidgets(
        'with testForceCameraUnavailable:true the live-camera MobileScanner '
        'widget is NOT present in the tree', (tester) async {
      // Given: camera is forced-unavailable via test seam
      // When:  the sheet is built with testForceCameraUnavailable: true
      // Then:  no MobileScanner widget is rendered — the uninitialized
      //        MobileScannerController must never be touched
      await tester.pumpWidget(wrapScanningWeb());
      await tester.pumpAndSettle();

      expect(
        find.byType(MobileScanner),
        findsNothing,
        reason: 'MobileScanner must NOT be rendered when camera is unavailable',
      );
    });
  });
}
