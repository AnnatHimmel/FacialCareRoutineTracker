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
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/setup/product_selection_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);
  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  bool upsertCalled = false;
  ProductSelection? lastUpserted;

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value([]);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Future<void> upsertSelection(ProductSelection s) async {
    upsertCalled = true;
    lastUpserted = s;
  }

  @override Future<void> muteConflict(MutedConflict m) async {}
  @override Future<void> unmuteConflict(String ruleId) async {}

  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) => throw UnimplementedError();
  @override Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) => throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
}

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _product(String id, String name, String categoryId) =>
    MasterProduct(
      id: id,
      name: name,
      categoryId: categoryId,
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

MasterContent _masterWith(List<MasterProduct> products, List<Category> cats) =>
    MasterContent(
      products: products,
      categories: cats,
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

Widget _wrap({
  required MasterContent master,
  _FakeUDR? udr,
  bool fromSetup = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/selection',
    routes: [
      GoRoute(
        path: '/setup/selection',
        builder: (_, __) =>
            ProductSelectionScreen(fromSetup: fromSetup),
      ),
      GoRoute(
        path: '/setup/schedule',
        builder: (_, state) => Scaffold(
          body: Text(
            'schedule-from=${state.uri.queryParameters['from'] ?? 'none'}',
          ),
        ),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr ?? _FakeUDR()),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  final cat1 = const Category(id: 'cat1', name: 'לחות');
  final cat2 = const Category(id: 'cat2', name: 'ניקוי');

  group('ProductSelectionScreen', () {
    testWidgets('products rendered in list', (tester) async {
      final master = _masterWith([
        _product('p1', 'קרם לחות', 'cat1'),
        _product('p2', 'ג׳ל ניקוי', 'cat2'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
    });

    testWidgets('fromSetup: true → sticky CTA with המשך לתזמון visible',
        (tester) async {
      final master = _masterWith([_product('p1', 'קרם', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: true));
      await tester.pumpAndSettle();

      expect(find.text('המשך לתזמון'), findsOneWidget);
    });

    testWidgets('fromSetup: false → no sticky CTA', (tester) async {
      final master = _masterWith([_product('p1', 'קרם', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: false));
      await tester.pumpAndSettle();

      expect(find.text('המשך לתזמון'), findsNothing);
    });

    testWidgets('tapping product calls upsertSelection', (tester) async {
      final udr = _FakeUDR();
      final master = _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Tap the action button (add icon), not the row — the row tap only expands
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(udr.upsertCalled, isTrue);
    });

    testWidgets('search filters product list', (tester) async {
      final master = _masterWith([
        _product('p1', 'קרם לחות', 'cat1'),
        _product('p2', 'ג׳ל ניקוי', 'cat2'),
      ], [cat1, cat2]);

      await tester.pumpWidget(_wrap(master: master));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'קרם');
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsNothing);
    });

    testWidgets('fromSetup: true CTA navigates to /setup/schedule?from=setup',
        (tester) async {
      final master = _masterWith([_product('p1', 'קרם', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, fromSetup: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך לתזמון'));
      await tester.pumpAndSettle();

      expect(find.text('schedule-from=setup'), findsOneWidget);
    });
  });
}
