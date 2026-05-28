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
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/home/daily_home_screen.dart';
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
  final DayRecord? morningRecord;
  final DayRecord? eveningRecord;
  bool updateCalled = false;
  DayRecord? lastUpdate;

  _FakeUDR({
    this.morningSelections = const [],
    this.eveningSelections = const [],
    this.morningRecord,
    this.eveningRecord,
  });

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value(
        slot == Slot.morning ? morningSelections : eveningSelections,
      );

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(null);

  @override
  Stream<DayRecord?> watchDayRecord(String date, Slot slot) =>
      Stream.value(slot == Slot.morning ? morningRecord : eveningRecord);

  @override
  Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([
        if (morningRecord != null) morningRecord!,
        if (eveningRecord != null) eveningRecord!,
      ]);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<DayRecord> snapshotAndGetDayRecord(
    String date,
    Slot slot,
    List<String> resolvedIds,
    String version,
  ) async =>
      DayRecord(
        id: 'snap',
        date: date,
        slot: slot,
        resolvedProductIds: resolvedIds,
        recordedProductIds: [],
        resolvedAtMasterVersion: version,
        lastModified: DateTime(2024, 1, 15),
      );

  @override
  Future<void> updateDayRecord(DayRecord r) async {
    updateCalled = true;
    lastUpdate = r;
  }

  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
}

// ── Test data ─────────────────────────────────────────────────────────────────

final _morningProduct = MasterProduct(
  id: 'pm1',
  name: 'קרם בוקר',
  categoryId: 'cat1',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
);

final _master = MasterContent(
  products: [_morningProduct],
  categories: [const Category(id: 'cat1', name: 'לחות')],
  rules: [],
  manifest: const MasterListManifest(
    contentVersion: '1.0.0',
    appVersion: '1.0.0',
    changelog: [],
  ),
);

DayRecord _dayRecord({required List<String> recorded}) => DayRecord(
      id: 'r1',
      date: '2024-01-15',
      slot: Slot.morning,
      resolvedProductIds: ['pm1'],
      recordedProductIds: recorded,
      resolvedAtMasterVersion: '1.0.0',
      lastModified: DateTime(2024, 1, 15),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 's1',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

Widget _wrap({required MasterContent master, required _FakeUDR udr}) {
  final router = GoRouter(
    initialLocation: '/today',
    routes: [
      GoRoute(
        path: '/today',
        builder: (_, __) => const DailyHomeScreen(),
      ),
      GoRoute(
        path: '/skin-log/:date',
        builder: (_, state) =>
            Scaffold(body: Text('journal-${state.pathParameters['date']}')),
      ),
      GoRoute(
        path: '/setup/selection',
        builder: (_, __) => const Scaffold(body: Text('setup-screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
      effectiveDateProvider.overrideWithValue(DateTime(2024, 1, 15)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('DailyHomeScreen', () {
    testWidgets('empty routine → shows אין מוצרים להיום', (tester) async {
      await tester.pumpWidget(_wrap(
        master: _master,
        udr: _FakeUDR(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('אין מוצרים להיום'), findsOneWidget);
    });

    testWidgets('empty routine → CTA to setup visible', (tester) async {
      await tester.pumpWidget(_wrap(master: _master, udr: _FakeUDR()));
      await tester.pumpAndSettle();

      expect(find.text('הוסף מוצרים'), findsOneWidget);
    });

    testWidgets('morning product shown when selected', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
        morningRecord: _dayRecord(recorded: []),
      );
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('קרם בוקר'), findsOneWidget);
    });

    testWidgets('toggle product calls updateDayRecord', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
        morningRecord: _dayRecord(recorded: []),
      );
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      // Tap the action button (check icon), not the row — the row tap only expands
      await tester.tap(find.byIcon(Icons.check).first);
      await tester.pumpAndSettle();

      expect(udr.updateCalled, isTrue);
    });

    testWidgets('journal CTA navigates to /skin-log/:date', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
        morningRecord: _dayRecord(recorded: []),
      );
      await tester.pumpWidget(_wrap(master: _master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('תיעוד עכשיו'));
      await tester.pumpAndSettle();

      expect(find.textContaining('journal-2024-01-15'), findsOneWidget);
    });
  });
}
