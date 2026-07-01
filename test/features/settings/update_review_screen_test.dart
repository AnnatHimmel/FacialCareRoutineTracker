import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
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
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/reconciliation_service.dart';
import 'package:skincare_tracker/features/settings/update_review_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Stubs (never called — reconcile() is overridden) ─────────────────────────

class _StubMCR implements MasterContentRepository {
  @override
  Future<MasterContent> load() => throw UnimplementedError();
}

class _StubSR implements SettingsRepository {
  @override Future<String?> getLastExportDate() => throw UnimplementedError();
  @override Future<void> setLastExportDate(String d) => throw UnimplementedError();
  @override Future<String?> getLastKnownMasterVersion() => throw UnimplementedError();
  @override Future<void> setLastKnownMasterVersion(String v) => throw UnimplementedError();
  @override Future<int> getUserSchemaVersion() => throw UnimplementedError();
  @override Future<void> setUserSchemaVersion(int v) => throw UnimplementedError();
  @override Future<int> getLongestStreak() => throw UnimplementedError();
  @override Future<void> setLongestStreak(int s) => throw UnimplementedError();
  @override Future<bool> getOnboardingCompleted() => throw UnimplementedError();
  @override Future<void> setOnboardingCompleted(bool v) => throw UnimplementedError();
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String name) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String gender) async {}
  @override Future<void> clearUserProfile() => throw UnimplementedError();
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
  @override Future<Set<String>?> getKnownProductIds() async => null;
  @override Future<void> setKnownProductIds(Set<String> ids) async {}
}

class _StubUDR implements UserDataRepository {
  @override Stream<List<ProductSelection>> watchSelections(Slot s) => throw UnimplementedError();
  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
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
  @override Stream<List<MutedConflict>> watchMutedConflicts() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Fake ReconciliationService ────────────────────────────────────────────────

class _FakeReconciliationService extends ReconciliationService {
  final ReconciliationResult fixedResult;
  bool acknowledged = false;
  String? acknowledgedVersion;

  _FakeReconciliationService(this.fixedResult)
      : super(_StubMCR(), _StubUDR(), _StubSR());

  @override
  Future<ReconciliationResult> reconcile() async => fixedResult;

  @override
  Future<void> acknowledgeUpdate(String version, Set<String> masterProductIds) async {
    acknowledged = true;
    acknowledgedVersion = version;
  }
}

// ── Test helpers ──────────────────────────────────────────────────────────────

MasterProduct _product(String id, String name, {bool isDeprecated = false}) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: isDeprecated,
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

Widget _wrap(_FakeReconciliationService service) {
  final router = GoRouter(
    initialLocation: '/update-review',
    routes: [
      GoRoute(
        path: '/update-review',
        builder: (_, _) => const UpdateReviewScreen(),
      ),
      GoRoute(
        path: '/today',
        builder: (_, _) => const Scaffold(body: Text('today-screen')),
      ),
      GoRoute(
        path: '/export-import',
        builder: (_, _) => const Scaffold(body: Text('export-import-screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      reconciliationServiceProvider.overrideWith((_) => service),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
    ),
  );
}

void main() {
  group('UpdateReviewScreen', () {
    testWidgets('no update → shows הכל מעודכן', (tester) async {
      final svc = _FakeReconciliationService(const ReconciliationResult(
        isUpdateDetected: false,
        newProducts: [],
        newlyDeprecatedSelected: [],
        currentContentVersion: '1.0.0',
        currentMasterProductIds: {},
      ));

      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      expect(find.text('הכל מעודכן'), findsOneWidget);
    });

    testWidgets('update detected → new products section listed', (tester) async {
      final svc = _FakeReconciliationService(ReconciliationResult(
        isUpdateDetected: true,
        newProducts: [_product('p1', 'סרום ויטמין C')],
        newlyDeprecatedSelected: [],
        currentContentVersion: '1.1.0',
        currentMasterProductIds: const {'p1'},
      ));

      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      expect(find.textContaining('מוצרים חדשים'), findsOneWidget);
      expect(find.text('סרום ויטמין C'), findsOneWidget);
    });

    testWidgets('update detected → deprecated products section listed', (tester) async {
      final svc = _FakeReconciliationService(ReconciliationResult(
        isUpdateDetected: true,
        newProducts: [],
        newlyDeprecatedSelected: [_product('p2', 'קרם ישן', isDeprecated: true)],
        currentContentVersion: '1.1.0',
        currentMasterProductIds: const {},
      ));

      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      expect(find.textContaining('שאינם מומלצים עוד'), findsOneWidget);
      expect(find.text('קרם ישן'), findsWidgets);
    });

    testWidgets('acknowledge button calls acknowledgeUpdate with correct version',
        (tester) async {
      final svc = _FakeReconciliationService(const ReconciliationResult(
        isUpdateDetected: true,
        newProducts: [],
        newlyDeprecatedSelected: [],
        currentContentVersion: '1.1.0',
        currentMasterProductIds: {},
      ));

      await tester.pumpWidget(_wrap(svc));
      await tester.pumpAndSettle();

      await tester.tap(find.text('הבנתי, המשך'));
      await tester.pumpAndSettle();

      expect(svc.acknowledged, isTrue);
      expect(svc.acknowledgedVersion, '1.1.0');
    });
  });
}
