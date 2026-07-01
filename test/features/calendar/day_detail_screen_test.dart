import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
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
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/calendar/day_detail_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final Map<Slot, DayRecord?> records;
  final List<UserCustomProduct> customProducts;
  bool updateCalled = false;

  _FakeUDR({this.records = const {}, this.customProducts = const []});

  @override
  Stream<DayRecord?> watchDayRecord(String date, Slot slot) =>
      Stream.value(records[slot]);

  @override
  Future<void> updateDayRecord(DayRecord r) async => updateCalled = true;

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
  @override Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) => throw UnimplementedError();
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
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value(customProducts);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test data ─────────────────────────────────────────────────────────────────

const _product = MasterProduct(
  id: 'p1',
  name: 'קרם לחות',
  categoryId: 'cat1',
  isDeprecated: false,
  morningConfig: SlotConfig(order: 1, frequencyRule: DailyRule()),
);

final _customProduct = UserCustomProduct(
  id: 'cp1',
  name: 'סרום מותאם',
  categoryId: 'cat1',
  inMorning: true,
  inEvening: false,
  isDaily: true,
  lastModified: DateTime(2024, 1, 15),
  isDeprecated: true,
);

const _master = MasterContent(
  products: [_product],
  categories: [Category(id: 'cat1', name: 'לחות', order: 1)],
  rules: [],
  manifest: MasterListManifest(
    contentVersion: '1.0.0',
    appVersion: '1.0.0',
    changelog: [],
  ),
);

DayRecord _record({
  required List<String> resolved,
  required List<String> recorded,
  Slot slot = Slot.morning,
}) =>
    DayRecord(
      id: 'r1',
      date: '2024-01-15',
      slot: slot,
      resolvedProductIds: resolved,
      recordedProductIds: recorded,
      resolvedAtMasterVersion: '1.0.0',
      lastModified: DateTime(2024, 1, 15),
    );

Widget _wrap({required MasterContent master, required _FakeUDR udr}) {
  final router = GoRouter(
    initialLocation: '/day/2024-01-15',
    routes: [
      GoRoute(
        path: '/day/:date',
        builder: (_, state) =>
            DayDetailScreen(date: state.pathParameters['date']!),
      ),
      GoRoute(
        path: '/skin-log/:date',
        builder: (_, state) =>
            Scaffold(body: Text('journal-${state.pathParameters['date']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
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
  group('DayDetailScreen', () {
    testWidgets('no records → shows אין נתונים ליום זה', (tester) async {
      await tester.pumpWidget(_wrap(
        master: _master,
        udr: _FakeUDR(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('אין נתונים ליום זה'), findsOneWidget);
    });

    testWidgets('morning record with products → products shown', (tester) async {
      final udr = _FakeUDR(records: {
        Slot.morning: _record(resolved: ['p1'], recorded: ['p1']),
      });
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
    });

    testWidgets('toggle product calls updateDayRecord', (tester) async {
      final udr = _FakeUDR(records: {
        Slot.morning: _record(resolved: ['p1'], recorded: ['p1']),
      });
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      // Tap the product row (done variant — InkWell wraps the whole row)
      await tester.tap(find.text('קרם לחות').first);
      await tester.pumpAndSettle();

      expect(udr.updateCalled, isTrue);
    });

    testWidgets('camera button navigates to /skin-log/:date', (tester) async {
      await tester.pumpWidget(_wrap(master: _master, udr: _FakeUDR()));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.camera_alt_outlined));
      await tester.pumpAndSettle();

      expect(find.text('journal-2024-01-15'), findsOneWidget);
    });

    testWidgets(
        'deprecated custom product in resolvedProductIds is shown in history',
        (tester) async {
      // A custom product that was subsequently "deleted" (isDeprecated = true)
      // must still appear when viewing the calendar day where it was used.
      final udr = _FakeUDR(
        records: {
          Slot.morning: _record(resolved: ['cp1'], recorded: ['cp1']),
        },
        customProducts: [_customProduct],
      );
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('סרום מותאם'), findsOneWidget);
    });
  });
}
