import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/photo_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/journal/skin_journal_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakePhotoRepo implements PhotoRepository {
  @override Future<void> savePhoto(String key, Uint8List bytes) async {}
  @override Future<Uint8List?> readPhoto(String key) async => null;
  @override Future<void> deletePhoto(String key) async {}
  @override Future<List<String>> listAllKeys() async => [];
}

class _FakeUDR implements UserDataRepository {
  final List<SkinLogEntry> logs;
  _FakeUDR(this.logs);

  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => Stream.value(logs);

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
  @override Stream<List<MutedConflict>> watchMutedConflicts() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
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

// ── Helpers ───────────────────────────────────────────────────────────────────

SkinLogEntry _log(String id, String date, {List<String> photos = const ['photo.jpg']}) =>
    SkinLogEntry(
      id: id,
      date: date,
      photoPaths: photos,
      lastModified: DateTime(2024, 1, 1),
    );

Widget _wrap(List<SkinLogEntry> logs, {List<RouteBase> extra = const []}) {
  final router = GoRouter(
    initialLocation: '/journal',
    routes: [
      GoRoute(
        path: '/journal',
        builder: (_, __) => const SkinJournalScreen(),
      ),
      GoRoute(
        path: '/skin-log/new',
        builder: (_, __) => const Scaffold(body: Text('new-entry-screen')),
      ),
      GoRoute(
        path: '/skin-log/:date',
        builder: (_, state) =>
            Scaffold(body: Text('entry-${state.pathParameters['date']}')),
      ),
      ...extra,
    ],
  );
  return ProviderScope(
    overrides: [
      userDataRepositoryProvider.overrideWithValue(_FakeUDR(logs)),
      photoRepositoryProvider.overrideWithValue(_FakePhotoRepo()),
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
  group('SkinJournalScreen', () {
    testWidgets('empty state when no logs with photos', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      expect(find.text('אין תמונות עדיין'), findsOneWidget);
    });

    testWidgets('logs without photos show empty state', (tester) async {
      final logs = [_log('l1', '2024-01-15', photos: [])];
      await tester.pumpWidget(_wrap(logs));
      await tester.pumpAndSettle();

      expect(find.text('אין תמונות עדיין'), findsOneWidget);
    });

    testWidgets('entries with photos are shown sorted newest first', (tester) async {
      final logs = [
        _log('l1', '2024-01-10'),
        _log('l2', '2024-01-20'),
        _log('l3', '2024-01-05'),
      ];
      await tester.pumpWidget(_wrap(logs));
      await tester.pumpAndSettle();

      // The screen sort is descending by date. The first visible card should
      // be Jan 20 (newest). Each card's photo is ~screen-width tall, so only
      // one card is rendered in the lazy ListView at a time.
      // If sorted correctly: Jan 20 visible, Jan 5 off-screen (not built).
      expect(find.textContaining('20 בינואר'), findsOneWidget);
      expect(find.textContaining('5 בינואר'), findsNothing);
    });

    testWidgets('tapping entry navigates to /skin-log/:date', (tester) async {
      final logs = [_log('l1', '2024-01-15')];
      await tester.pumpWidget(_wrap(logs));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('ינואר'));
      await tester.pumpAndSettle();

      expect(find.text('entry-2024-01-15'), findsOneWidget);
    });

    testWidgets('empty state CTA navigates to /skin-log/new', (tester) async {
      await tester.pumpWidget(_wrap([]));
      await tester.pumpAndSettle();

      await tester.tap(find.text('התחל לתעד'));
      await tester.pumpAndSettle();

      expect(find.text('new-entry-screen'), findsOneWidget);
    });
  });
}
