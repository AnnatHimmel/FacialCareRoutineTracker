import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
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
import 'package:skincare_tracker/features/setup/routine_ready_route.dart';
import 'package:skincare_tracker/features/setup/routine_ready_summary_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> selections = const [];

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(selections.where((s) => s.slot == slot).toList());
  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override
  Future<void> upsertSelection(ProductSelection s) async {}
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {}
  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() =>
      Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() =>
      Stream.value([]);
  @override Future<void> upsertCollectionItem(CollectionItem item) async {}
  @override Future<void> deleteCollectionItem(String id) async {}
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      Stream.value(null);
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      Stream.value([]);
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      Stream.value(null);
  @override Future<void> upsertOrderOverride(OrderOverride o) async {}
  @override Future<void> deleteOrderOverride(Slot s) async {}
  @override Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);
  @override Future<OrderOverride?> getEffectiveOrderOverride(
          Slot slot, int weekday) async =>
      null;
  @override Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      Stream.value(null);
  @override Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) async {}
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      Stream.value([]);
  @override Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => Stream.value(null);
  @override Future<void> upsertSkinLog(SkinLogEntry e) async {}
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => Stream.value([]);
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) async {}
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

MasterContent _masterWith(List<MasterProduct> products, List<Category> cats) =>
    MasterContent(
      products: products,
      categories: cats,
      rules: const [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({required MasterContent master, UserDataRepository? udr}) {
  final router = GoRouter(
    initialLocation: '/routine-ready',
    routes: [
      GoRoute(
        path: '/routine-ready',
        builder: (_, _) => const RoutineReadyRoute(),
      ),
      GoRoute(
        path: '/collection',
        builder: (_, _) => const Scaffold(body: Text('SHELF')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr ?? _FakeUDR()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
    ),
  );
}

void main() {
  group('RoutineReadyRoute', () {
    testWidgets('builds the summary and renders RoutineReadySummaryScreen',
        (tester) async {
      await tester.pumpWidget(_wrap(master: _masterWith(const [], const [])));
      await tester.pumpAndSettle();

      expect(find.byType(RoutineReadySummaryScreen), findsOneWidget);
      // "Your routine is ready ✨"
      expect(find.text('השגרה שלך מוכנה ✨'), findsOneWidget);
    });

    testWidgets('CTA navigates to the shelf (/collection)', (tester) async {
      await tester.pumpWidget(_wrap(master: _masterWith(const [], const [])));
      await tester.pumpAndSettle();

      // The single CTA: "Show my routine"
      await tester.tap(find.text('הצגת השגרה שלי'));
      await tester.pumpAndSettle();

      expect(find.text('SHELF'), findsOneWidget);
    });
  });
}
