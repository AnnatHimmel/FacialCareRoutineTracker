import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
          body: BarcodeScanSheet(testBarcodeToScan: testBarcode),
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

final _morningProduct = MasterProduct(
  id: 'prod-morning',
  name: 'Morning Serum',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  barcodes: [_matchingBarcode],
  morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
  eveningConfig: null,
);

final _eveningProduct = MasterProduct(
  id: 'prod-evening',
  name: 'Evening Cream',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  barcodes: [_matchingBarcode],
  morningConfig: null,
  eveningConfig: const SlotConfig(order: 5, frequencyRule: DailyRule()),
);

final _bothSlotsProduct = MasterProduct(
  id: 'prod-both',
  name: 'Rice Toner',
  imageAsset: null,
  categoryId: 'cat-toner',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  barcodes: [_matchingBarcode],
  morningConfig: const SlotConfig(order: 2, frequencyRule: DailyRule()),
  eveningConfig: const SlotConfig(order: 6, frequencyRule: DailyRule()),
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
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he'),
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
        'no master match + external returns data → shows productFound state',
        (tester) async {
      final lookup = _TrackingLookupService()
        ..stubbedResult = ScannedProductInfo(
          barcode: 'unknown-barcode-999',
          name: 'External Product',
          brand: 'Some Brand',
          imageUrl: null,
        );

      await tester.pumpWidget(_wrap(
        master: _contentWith([_bothSlotsProduct]),
        lookup: lookup,
        testBarcode: 'unknown-barcode-999',
      ));
      await tester.pumpAndSettle();

      expect(lookup.callCount, 1);
      expect(find.text('מוצר נמצא'), findsOneWidget);
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
    Future<_CapturingUDR> _tapAddAndSettle(
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
      final udr = await _tapAddAndSettle(tester, product: _morningProduct);

      expect(udr.captured.length, 1);
      expect(udr.captured.first.productId, 'prod-morning');
      expect(udr.captured.first.slot, Slot.morning);
      expect(udr.captured.first.isSelected, true);
    });

    testWidgets('evening-only product → upserts only evening selection',
        (tester) async {
      final udr = await _tapAddAndSettle(tester, product: _eveningProduct);

      expect(udr.captured.length, 1);
      expect(udr.captured.first.productId, 'prod-evening');
      expect(udr.captured.first.slot, Slot.evening);
      expect(udr.captured.first.isSelected, true);
    });

    testWidgets('both-slot product → upserts morning and evening selections',
        (tester) async {
      final udr = await _tapAddAndSettle(tester, product: _bothSlotsProduct);

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
      final udr = await _tapAddAndSettle(
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
      final udr = await _tapAddAndSettle(
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
      final udr = await _tapAddAndSettle(
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
      final udr = await _tapAddAndSettle(tester, product: _bothSlotsProduct);

      expect(udr.captured.length, 2);
      final ids = udr.captured.map((s) => s.id).toSet();
      expect(ids.length, 2, reason: 'each selection must have a distinct UUID');
    });
  });
}
