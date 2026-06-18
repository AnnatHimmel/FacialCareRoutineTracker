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

void main() {
  const exfoliateCat = Category(id: 'cat-exfoliate', name: 'פילינג', order: 3);
  const serumCat = Category(id: 'cat-serum', name: 'סרום', order: 5);
  const salicylicSub = SubCategory(
    id: 'sub-bha-salicylic',
    name: 'חומצה סליצילית',
    categoryId: 'cat-exfoliate',
    order: 5,
  );

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
    await tester.scrollUntilVisible(
      find.text('הוספה לשגרה שלי'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('הוספה לשגרה שלי'));
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
}
