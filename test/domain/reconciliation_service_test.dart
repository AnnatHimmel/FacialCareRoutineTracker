import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/reconciliation_service.dart';

// ── Minimal fakes ─────────────────────────────────────────────────────────────

class FakeMasterRepo implements MasterContentRepository {
  final MasterContent content;
  FakeMasterRepo(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class FakeSettingsRepo implements SettingsRepository {
  final String? lastKnownVersion;
  FakeSettingsRepo(this.lastKnownVersion);
  @override Future<String?> getLastKnownMasterVersion() async => lastKnownVersion;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<int> getUserSchemaVersion() async => 1;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async => true;
  @override Future<void> setOnboardingCompleted(bool v) async {}
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String name) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String gender) async {}
  @override Future<void> clearUserProfile() async {}
}

class FakeUserRepo implements UserDataRepository {
  final List<ProductSelection> selections;
  FakeUserRepo(this.selections);

  @override
  Future<UserDataExport> exportAllData() async => UserDataExport(
        schemaVersion: '1',
        exportDate: '2026-01-01',
        appVersion: '1.0.0',
        masterContentVersion: '1.0.0',
        selections: selections,
        schedules: [],
        overrides: [],
        dayRecords: [],
        skinLogs: [],
        mutedConflicts: [],
      );

  // Stubs — not called by reconcile()
  @override Stream<List<ProductSelection>> watchSelections(Slot s) => const Stream.empty();
  @override Future<void> upsertSelection(ProductSelection s) async {}
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot slot) => const Stream.empty();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => const Stream.empty();
  @override Future<void> upsertSchedule(WeekdaySchedule s) async {}
  @override Stream<OrderOverride?> watchOrderOverride(Slot slot) => const Stream.empty();
  @override Future<void> upsertOrderOverride(OrderOverride o) async {}
  @override Future<void> deleteOrderOverride(Slot slot) async {}
  @override Stream<DayRecord?> watchDayRecord(String date, Slot slot) => const Stream.empty();
  @override Future<DayRecord> snapshotAndGetDayRecord(String date, Slot slot, List<String> ids, String v) => throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) async {}
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => const Stream.empty();
  @override Stream<List<DayRecord>> watchAllDayRecords() => const Stream.empty();
  @override Stream<SkinLogEntry?> watchSkinLog(String date) => const Stream.empty();
  @override Future<void> upsertSkinLog(SkinLogEntry e) async {}
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => const Stream.empty();
  @override Stream<List<MutedConflict>> watchMutedConflicts() => const Stream.empty();
  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}
  @override Future<void> replaceAllData(UserDataExport export) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterProduct product(String id, String addedInVersion, {bool deprecated = false}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat',
      isDeprecated: deprecated,
      addedInVersion: addedInVersion,
    );

MasterContent masterWith(String contentVersion, List<MasterProduct> products) =>
    MasterContent(
      products: products,
      categories: [],
      rules: [],
      manifest: MasterListManifest(
        contentVersion: contentVersion,
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

ProductSelection selected(String productId) => ProductSelection(
      id: 'sel-$productId',
      productId: productId,
      slot: Slot.morning,
      isSelected: true,
      lastModified: DateTime(2026),
    );

ReconciliationService makeService({
  required MasterContent content,
  required String? lastKnown,
  List<ProductSelection> selections = const [],
}) =>
    ReconciliationService(
      FakeMasterRepo(content),
      FakeUserRepo(selections),
      FakeSettingsRepo(lastKnown),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('no update when versions match', () {
    test('returns isUpdateDetected: false when lastKnown == currentVersion', () async {
      final svc = makeService(
        content: masterWith('1.0.0', [product('p1', '1.0.0')]),
        lastKnown: '1.0.0',
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isFalse);
      expect(result.newProducts, isEmpty);
    });
  });

  group('newProducts filter — BUG 2', () {
    // BUG: filter was `!isDeprecated && !selectedIds.contains(id)`
    // — returned every non-selected product regardless of addedInVersion
    // FIX: must require addedInVersion > lastKnown (semver)

    test('product added at same version as lastKnown → NOT in newProducts', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '1.0.0')]),
        lastKnown: '1.0.0',
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isTrue);
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('product added in version newer than lastKnown → IS in newProducts', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '1.1.0')]),
        lastKnown: '1.0.0',
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isTrue);
      expect(result.newProducts.map((p) => p.id), contains('p1'));
    });

    test('product added in older version → NOT in newProducts', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '0.9.0')]),
        lastKnown: '1.0.0',
      );
      final result = await svc.reconcile();
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('already-selected new product is excluded', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '1.1.0')]),
        lastKnown: '1.0.0',
        selections: [selected('p1')],
      );
      final result = await svc.reconcile();
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('deprecated new product is excluded', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '1.1.0', deprecated: true)]),
        lastKnown: '1.0.0',
      );
      final result = await svc.reconcile();
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('mix: only truly-new non-selected non-deprecated products appear', () async {
      final svc = makeService(
        content: masterWith('1.2.0', [
          product('old', '1.0.0'),                          // same as lastKnown → exclude
          product('new', '1.1.0'),                          // newer → include
          product('also-new', '1.2.0'),                     // newer → include
          product('selected', '1.1.0'),                     // newer but selected → exclude
          product('deprecated', '1.1.0', deprecated: true), // newer but deprecated → exclude
        ]),
        lastKnown: '1.0.0',
        selections: [selected('selected')],
      );
      final result = await svc.reconcile();
      final ids = result.newProducts.map((p) => p.id).toSet();
      expect(ids, containsAll(['new', 'also-new']));
      expect(ids, isNot(contains('old')));
      expect(ids, isNot(contains('selected')));
      expect(ids, isNot(contains('deprecated')));
    });
  });

  group('newlyDeprecatedSelected', () {
    test('selected deprecated product appears in newlyDeprecatedSelected', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', '1.0.0', deprecated: true)]),
        lastKnown: '1.0.0',
        selections: [selected('p1')],
      );
      final result = await svc.reconcile();
      expect(result.newlyDeprecatedSelected.map((p) => p.id), contains('p1'));
    });
  });
}
