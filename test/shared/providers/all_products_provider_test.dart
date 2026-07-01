// Tests that allProductsProvider resolves to master + custom products, and
// re-emits when the custom-products stream pushes a new value.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

/// A minimal UserDataRepository whose watchCustomProducts() is driven by a
/// StreamController so tests can push new lists reactively.
class _ReactiveUDR implements UserDataRepository {
  List<UserCustomProduct> _customs;

  final StreamController<List<UserCustomProduct>> _customsCtrl =
      StreamController<List<UserCustomProduct>>.broadcast();

  _ReactiveUDR(this._customs);

  void pushCustomProducts(List<UserCustomProduct> customs) {
    _customs = customs;
    _customsCtrl.add(customs);
  }

  void dispose() {
    _customsCtrl.close();
  }

  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() {
    return Stream.multi((controller) {
      controller.add(_customs);
      _customsCtrl.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
    });
  }

  // All other methods are unused by allProductsProvider — throw to catch misuse.
  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value([]);
  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);
  @override
  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot) =>
      Stream.value(null);
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {}
  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override
  Future<void> muteConflict(MutedConflict m) async {}
  @override
  Future<void> unmuteConflict(String ruleId) async {}
  @override
  Future<void> upsertSelection(ProductSelection s) async {}
  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override
  Future<void> deleteCustomProduct(String id) async {}
  @override
  Stream<List<CollectionItem>> watchCollectionItems() =>
      throw UnimplementedError();
  @override
  Future<void> upsertCollectionItem(CollectionItem item) =>
      throw UnimplementedError();
  @override
  Future<void> deleteCollectionItem(String id) =>
      throw UnimplementedError();
  @override
  Stream<OrderOverride?> watchOrderOverride(Slot s) => Stream.value(null);
  @override
  Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();
  @override
  Future<void> deleteOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(
          Slot slot, int weekday) async =>
      null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override
  Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      throw UnimplementedError();
  @override
  Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override
  Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override
  Future<void> clearRoutineData() async {}
  @override
  Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      Stream.value([]);
  @override
  Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override
  Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _manifest = MasterListManifest(
  contentVersion: '1.0.0',
  appVersion: '1.0.0',
  changelog: [],
);

const _masterA = MasterProduct(
  id: 'master-a',
  name: 'Cleanser',
  categoryId: 'cat-1',
  morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
  isDeprecated: false,
);

const _masterB = MasterProduct(
  id: 'master-b',
  name: 'Toner',
  categoryId: 'cat-1',
  morningConfig: SlotConfig(order: 2, frequencyRule: DailyRule()),
  isDeprecated: false,
);

final _custom1 = UserCustomProduct(
  id: 'custom-1',
  name: 'My Serum',
  categoryId: 'cat-1',
  inMorning: true,
  inEvening: false,
  isDaily: true,
  lastModified: DateTime(2026),
);

final _custom2 = UserCustomProduct(
  id: 'custom-2',
  name: 'My Moisturiser',
  categoryId: 'cat-1',
  inMorning: true,
  inEvening: false,
  isDaily: true,
  lastModified: DateTime(2026),
);

MasterContent _masterWith(List<MasterProduct> products) => MasterContent(
      products: products,
      categories: const [],
      rules: const [],
      manifest: _manifest,
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('allProductsProvider', () {
    test('resolves to master products + custom product with editable == true',
        () async {
      final udr = _ReactiveUDR([_custom1]);
      addTearDown(udr.dispose);

      final container = ProviderContainer(
        overrides: [
          masterContentRepositoryProvider
              .overrideWithValue(_FakeMCR(_masterWith([_masterA, _masterB]))),
          userDataRepositoryProvider.overrideWithValue(udr),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(allProductsProvider.future);

      // Should contain both master products and the custom one.
      expect(result.length, 3);

      final masterIds = result.where((p) => !p.editable).map((p) => p.id);
      expect(masterIds, containsAll(['master-a', 'master-b']));

      final custom = result.firstWhere((p) => p.id == 'custom-1');
      expect(custom.editable, isTrue,
          reason: 'toMasterProduct() sets editable = true for custom products');
    });

    test('re-emits with new custom product after push', () async {
      final udr = _ReactiveUDR([_custom1]);
      addTearDown(udr.dispose);

      final container = ProviderContainer(
        overrides: [
          masterContentRepositoryProvider
              .overrideWithValue(_FakeMCR(_masterWith([_masterA, _masterB]))),
          userDataRepositoryProvider.overrideWithValue(udr),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<MasterProduct>>>[];
      container.listen<AsyncValue<List<MasterProduct>>>(
        allProductsProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );

      // Wait for initial resolution.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final countBefore = values.length;

      // Push an additional custom product.
      udr.pushCustomProducts([_custom1, _custom2]);

      // Wait for re-emission.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(values.length, greaterThan(countBefore),
          reason: 'allProductsProvider must re-emit when custom products change');

      // The latest value should contain all 4 products.
      final latest = values.last;
      expect(latest, isA<AsyncData<List<MasterProduct>>>());
      final products = (latest as AsyncData<List<MasterProduct>>).value;
      expect(products.length, 4);
      expect(products.map((p) => p.id),
          containsAll(['master-a', 'master-b', 'custom-1', 'custom-2']));
    });
  });
}
