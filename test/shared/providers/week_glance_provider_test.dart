// Tests that weekGlanceProvider re-evaluates when the backing DB streams emit
// new values (Bug 4: week glance did not refresh after a product was added).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
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
import 'package:skincare_tracker/domain/services/week_glance_builder.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

/// A UserDataRepository whose watchSelections() is driven by StreamControllers
/// that keep the current value and can push updates.
class _ReactiveUDR implements UserDataRepository {
  List<ProductSelection> _morning = [];
  List<ProductSelection> _evening = [];

  // Each controller holds the most-recent value; calling watchSelections
  // returns a stream that immediately emits the current list, then emits on
  // each pushSelections() call.
  final StreamController<List<ProductSelection>> _morningCtrl =
      StreamController<List<ProductSelection>>.broadcast();
  final StreamController<List<ProductSelection>> _eveningCtrl =
      StreamController<List<ProductSelection>>.broadcast();

  void pushSelections(Slot slot, List<ProductSelection> sels) {
    if (slot == Slot.morning) {
      _morning = sels;
      _morningCtrl.add(sels);
    } else {
      _evening = sels;
      _eveningCtrl.add(sels);
    }
  }

  void dispose() {
    _morningCtrl.close();
    _eveningCtrl.close();
  }

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) {
    // Emit current value first, then re-emit on every push.
    if (slot == Slot.morning) {
      return Stream.multi((controller) {
        controller.add(_morning);
        _morningCtrl.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      });
    } else {
      return Stream.multi((controller) {
        controller.add(_evening);
        _eveningCtrl.stream.listen(
          controller.add,
          onError: controller.addError,
          onDone: controller.close,
        );
      });
    }
  }

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
  Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
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
  Stream<List<DayRecord>> watchAllDayRecords() =>
      throw UnimplementedError();
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) =>
      throw UnimplementedError();
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() =>
      throw UnimplementedError();
  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) =>
      throw UnimplementedError();
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

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterContent _emptyMaster() => const MasterContent(
      products: [],
      categories: [],
      rules: [],
      manifest: MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('weekGlanceProvider', () {
    test(
        'Bug 4: re-emits when the morning selections stream pushes a new value',
        () async {
      final udr = _ReactiveUDR();
      addTearDown(udr.dispose);

      final master = _emptyMaster();
      final container = ProviderContainer(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
          userDataRepositoryProvider.overrideWithValue(udr),
        ],
      );
      addTearDown(container.dispose);

      // Listen to weekGlanceProvider — this triggers the provider to start.
      final values = <AsyncValue<WeekGlance>>[];
      container.listen<AsyncValue<WeekGlance>>(
        weekGlanceProvider,
        (_, next) => values.add(next),
        fireImmediately: true,
      );

      // Allow the initial future to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Verify initial state arrived (either data or still loading).
      // Regardless, capture the current count.
      final countBefore = values.length;

      // Push a new product selection — weekGlanceProvider must re-run.
      final sel = ProductSelection(
        id: 'sel-1',
        productId: 'p1',
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2025, 1, 1),
      );
      udr.pushSelections(Slot.morning, [sel]);

      // Allow async re-evaluation to propagate.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(values.length, greaterThan(countBefore),
          reason: 'Bug 4: weekGlanceProvider must re-emit when the selections '
              'stream emits a new list');
    });
  });
}
