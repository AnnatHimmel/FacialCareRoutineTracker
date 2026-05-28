import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
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
import 'package:skincare_tracker/features/setup/order_customization_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> morningSelections;
  final List<ProductSelection> eveningSelections;
  final OrderOverride? morningOverride;
  final OrderOverride? eveningOverride;
  bool deleteOverrideCalled = false;

  _FakeUDR({
    this.morningSelections = const [],
    this.eveningSelections = const [],
    this.morningOverride,
    this.eveningOverride,
  });

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value(
        slot == Slot.morning ? morningSelections : eveningSelections,
      );

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(
        slot == Slot.morning ? morningOverride : eveningOverride,
      );

  @override
  Future<void> deleteOrderOverride(Slot slot) async {
    deleteOverrideCalled = true;
  }

  @override
  Future<void> upsertOrderOverride(OrderOverride o) async {}

  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
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
}

class _FakeSR implements SettingsRepository {
  bool onboardingCompleted = false;

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    onboardingCompleted = value;
  }

  @override Future<bool> getOnboardingCompleted() async => false;
  @override Future<String?> getLastExportDate() => throw UnimplementedError();
  @override Future<void> setLastExportDate(String d) => throw UnimplementedError();
  @override Future<String?> getLastKnownMasterVersion() => throw UnimplementedError();
  @override Future<void> setLastKnownMasterVersion(String v) => throw UnimplementedError();
  @override Future<int> getUserSchemaVersion() => throw UnimplementedError();
  @override Future<void> setUserSchemaVersion(int v) => throw UnimplementedError();
  @override Future<int> getLongestStreak() => throw UnimplementedError();
  @override Future<void> setLongestStreak(int s) => throw UnimplementedError();
}

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _product(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _master(List<MasterProduct> products) => MasterContent(
      products: products,
      categories: [const Category(id: 'cat1', name: 'לחות')],
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 's1',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

OrderOverride _override(Slot slot, List<String> ids) => OrderOverride(
      id: 'ov1',
      slot: slot,
      orderedProductIds: ids,
      lastModified: DateTime(2024, 1, 1),
    );

Widget _wrap({
  required MasterContent master,
  required _FakeUDR udr,
  _FakeSR? sr,
  bool fromSetup = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/order',
    routes: [
      GoRoute(
        path: '/setup/order',
        builder: (_, __) => OrderCustomizationScreen(fromSetup: fromSetup),
      ),
      GoRoute(
        path: '/today',
        builder: (_, __) => const Scaffold(body: Text('home-screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
      settingsRepositoryProvider.overrideWithValue(sr ?? _FakeSR()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('OrderCustomizationScreen', () {
    testWidgets('morning product shown when selected', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם לחות')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
    });

    testWidgets('no products → shows לא נבחרו מוצרים', (tester) async {
      final udr = _FakeUDR();
      final master = _master([_product('p1', 'קרם לחות')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('לא נבחרו מוצרים'), findsOneWidget);
    });

    testWidgets('fromSetup: true → CTA text is סיום והתחלה', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('סיום והתחלה'), findsOneWidget);
    });

    testWidgets('fromSetup: false → CTA text is שמירת הסדר החדש', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, fromSetup: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('שמירת הסדר החדש'), findsOneWidget);
    });

    testWidgets(
        'fromSetup: true → save sets onboardingCompleted and navigates to /today',
        (tester) async {
      final sr = _FakeSR();
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, sr: sr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('סיום והתחלה'));
      await tester.pumpAndSettle();

      expect(sr.onboardingCompleted, isTrue);
      expect(find.text('home-screen'), findsOneWidget);
    });

    testWidgets('reset button visible when order override exists', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        morningOverride: _override(Slot.morning, ['p1']),
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('איפוס לסדר המומלץ'), findsOneWidget);
    });

    testWidgets('tapping reset button calls deleteOrderOverride', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        morningOverride: _override(Slot.morning, ['p1']),
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('איפוס לסדר המומלץ'));
      await tester.pumpAndSettle();

      expect(udr.deleteOverrideCalled, isTrue);
    });
  });
}
