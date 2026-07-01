import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
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
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/reconciliation_service.dart';

// ── Minimal fakes ─────────────────────────────────────────────────────────────

class FakeMasterRepo implements MasterContentRepository {
  final MasterContent content;
  FakeMasterRepo(this.content);
  @override
  Future<MasterContent> load() async => content;
}

/// In-memory SettingsRepository that supports both the legacy version pref
/// and the new known-product-IDs snapshot pref.
class FakeSettingsRepo implements SettingsRepository {
  final String? lastKnownVersion;
  final Set<String>? initialKnownProductIds;
  String? _savedVersion;
  Set<String>? _savedProductIds;

  FakeSettingsRepo(this.lastKnownVersion, {Set<String>? knownProductIds})
      : initialKnownProductIds = knownProductIds;

  @override Future<String?> getLastKnownMasterVersion() async => lastKnownVersion;
  @override Future<void> setLastKnownMasterVersion(String v) async { _savedVersion = v; }
  @override Future<Set<String>?> getKnownProductIds() async => initialKnownProductIds;
  @override Future<void> setKnownProductIds(Set<String> ids) async { _savedProductIds = ids; }

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
  @override Future<String> getRoutineViewMode() async => 'list';
  @override Future<void> setRoutineViewMode(String m) async {}
  @override Future<bool> getRoutineShowNames() async => false;
  @override Future<void> setRoutineShowNames(bool v) async {}
  @override Future<String> getAppLanguage() async => 'he';
  @override Future<void> setAppLanguage(String code) async {}
  @override Future<bool> getTapHintSeen() async => false;
  @override Future<void> setTapHintSeen(bool value) async {}
  @override Future<String?> getWeeklyPhotoReminderDismissedDate() async => null;
  @override Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate) async {}
  @override Future<bool> getWeeklyReminderEnabled() async => true;
  @override Future<void> setWeeklyReminderEnabled(bool value) async {}
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

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
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
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => const Stream.empty();
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

MasterProduct product(String id, {bool deprecated = false}) =>
    MasterProduct(
      id: id,
      name: id,
      categoryId: 'cat',
      isDeprecated: deprecated,
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

/// Build a service with an optional pre-seeded known-ID snapshot.
ReconciliationService makeService({
  required MasterContent content,
  required String? lastKnown,
  Set<String>? knownProductIds,
  List<ProductSelection> selections = const [],
}) {
  final settings = FakeSettingsRepo(lastKnown, knownProductIds: knownProductIds);
  return ReconciliationService(
    FakeMasterRepo(content),
    FakeUserRepo(selections),
    settings,
  );
}

/// Build a service and expose the settings fake so tests can inspect persisted state.
(ReconciliationService, FakeSettingsRepo) makeServiceWithSettings({
  required MasterContent content,
  required String? lastKnown,
  Set<String>? knownProductIds,
  List<ProductSelection> selections = const [],
}) {
  final settings = FakeSettingsRepo(lastKnown, knownProductIds: knownProductIds);
  final svc = ReconciliationService(
    FakeMasterRepo(content),
    FakeUserRepo(selections),
    settings,
  );
  return (svc, settings);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── First-run (knownProductIds snapshot is null) ──────────────────────────

  group('first run — no snapshot yet', () {
    test('seeds the snapshot with current non-deprecated IDs and returns no update', () async {
      final master = masterWith('1.0.0', [
        product('p1'),
        product('p2'),
        product('dep', deprecated: true),
      ]);
      final (svc, settings) = makeServiceWithSettings(
        content: master,
        lastKnown: null, // never set
        knownProductIds: null, // no snapshot
      );

      final result = await svc.reconcile();

      expect(result.isUpdateDetected, isFalse);
      expect(result.newProducts, isEmpty);
      // Snapshot should be seeded with non-deprecated IDs
      expect(settings._savedProductIds, equals({'p1', 'p2'}));
    });

    test('first run with existing version pref but no ID snapshot also seeds', () async {
      // Edge case: user had old app with version pref but no ID snapshot
      final master = masterWith('1.1.0', [product('p1'), product('p2')]);
      final (svc, settings) = makeServiceWithSettings(
        content: master,
        lastKnown: '1.0.0', // version pref exists
        knownProductIds: null, // but no ID snapshot
      );

      final result = await svc.reconcile();

      expect(result.isUpdateDetected, isFalse);
      expect(result.newProducts, isEmpty);
      expect(settings._savedProductIds, equals({'p1', 'p2'}));
    });
  });

  // ── Version early-out ─────────────────────────────────────────────────────

  group('version early-out', () {
    test('returns no update when versions match AND snapshot exists', () async {
      final svc = makeService(
        content: masterWith('1.0.0', [product('p1')]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isFalse);
      expect(result.newProducts, isEmpty);
    });
  });

  // ── New product detection via ID diff ─────────────────────────────────────

  group('newProducts — ID-snapshot diff', () {
    test('product in snapshot → NOT in newProducts', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1')]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
      );
      final result = await svc.reconcile();
      // p1 was in the last-known snapshot → not new
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('product NOT in snapshot → IS in newProducts', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1'), product('p2')]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'}, // p2 not in snapshot
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isTrue);
      expect(result.newProducts.map((p) => p.id), contains('p2'));
      expect(result.newProducts.map((p) => p.id), isNot(contains('p1')));
    });

    test('already-selected new product is excluded', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1'), product('p2')]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
        selections: [selected('p2')],
      );
      final result = await svc.reconcile();
      expect(result.newProducts.map((p) => p.id), isNot(contains('p2')));
    });

    test('deprecated new product is excluded', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('dep', deprecated: true)]),
        lastKnown: '1.0.0',
        knownProductIds: {}, // dep not in snapshot
      );
      final result = await svc.reconcile();
      expect(result.newProducts, isEmpty);
    });

    test('mix: only truly-new non-selected non-deprecated products appear', () async {
      final svc = makeService(
        content: masterWith('1.2.0', [
          product('old'),                          // in snapshot → exclude
          product('new1'),                         // not in snapshot → include
          product('new2'),                         // not in snapshot → include
          product('sel'),                          // not in snapshot but selected → exclude
          product('dep', deprecated: true),        // not in snapshot but deprecated → exclude
        ]),
        lastKnown: '1.0.0',
        knownProductIds: {'old'},
        selections: [selected('sel')],
      );
      final result = await svc.reconcile();
      final ids = result.newProducts.map((p) => p.id).toSet();
      expect(ids, containsAll(['new1', 'new2']));
      expect(ids, isNot(contains('old')));
      expect(ids, isNot(contains('sel')));
      expect(ids, isNot(contains('dep')));
    });
  });

  // ── newlyDeprecatedSelected ───────────────────────────────────────────────

  group('newlyDeprecatedSelected', () {
    test('selected deprecated product appears in newlyDeprecatedSelected', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', deprecated: true)]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
        selections: [selected('p1')],
      );
      final result = await svc.reconcile();
      expect(result.newlyDeprecatedSelected.map((p) => p.id), contains('p1'));
    });

    test('isUpdateDetected true when only deprecated-selected', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [product('p1', deprecated: true)]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
        selections: [selected('p1')],
      );
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isTrue);
    });
  });

  // ── acknowledgeUpdate persists BOTH version and ID set ───────────────────

  group('acknowledgeUpdate', () {
    test('persists version and current master non-deprecated IDs', () async {
      final master = masterWith('1.1.0', [
        product('p1'),
        product('p2'),
        product('dep', deprecated: true),
      ]);
      final (svc, settings) = makeServiceWithSettings(
        content: master,
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
      );

      final currentIds = {'p1', 'p2'}; // non-deprecated
      await svc.acknowledgeUpdate('1.1.0', currentIds);

      expect(settings._savedVersion, '1.1.0');
      expect(settings._savedProductIds, equals({'p1', 'p2'}));
    });

    test('after acknowledgeUpdate, reconcile with same content returns no update', () async {
      final master = masterWith('1.1.0', [product('p1'), product('p2')]);
      final (svc, settings) = makeServiceWithSettings(
        content: master,
        lastKnown: '1.1.0',
        knownProductIds: {'p1', 'p2'},
      );

      // Make sure version-match early-out works with up-to-date snapshot
      final result = await svc.reconcile();
      expect(result.isUpdateDetected, isFalse);
    });
  });

  // ── currentMasterProductIds in ReconciliationResult ──────────────────────

  group('ReconciliationResult.currentMasterProductIds', () {
    test('contains all non-deprecated product IDs', () async {
      final svc = makeService(
        content: masterWith('1.1.0', [
          product('p1'),
          product('p2'),
          product('dep', deprecated: true),
        ]),
        lastKnown: '1.0.0',
        knownProductIds: {'p1'},
      );
      final result = await svc.reconcile();
      expect(result.currentMasterProductIds, containsAll(['p1', 'p2']));
      expect(result.currentMasterProductIds, isNot(contains('dep')));
    });
  });
}
