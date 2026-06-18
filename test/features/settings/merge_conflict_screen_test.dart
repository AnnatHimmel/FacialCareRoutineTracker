import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
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
import 'package:skincare_tracker/domain/services/export_import_service.dart';
import 'package:skincare_tracker/features/settings/merge_conflict_screen.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeUDR implements UserDataRepository {
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
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() async => const UserDataExport(
    schemaVersion: '1',
    exportDate: '',
    appVersion: '1.0.0',
    masterContentVersion: '1.0.0',
    selections: [],
    schedules: [],
    overrides: [],
    dayRecords: [],
    skinLogs: [],
    mutedConflicts: [],
  );
  @override Future<void> replaceAllData(UserDataExport e) async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

class _FakePhotoRepo implements PhotoRepository {
  @override Future<void> savePhoto(String key, Uint8List bytes) async {}
  @override Future<Uint8List?> readPhoto(String key) async => null;
  @override Future<void> deletePhoto(String key) async {}
  @override Future<List<String>> listAllKeys() async => [];
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const _emptyExport = UserDataExport(
  schemaVersion: '1',
  exportDate: '',
  appVersion: '1.0.0',
  masterContentVersion: '1.0.0',
  selections: [],
  schedules: [],
  overrides: [],
  dayRecords: [],
  skinLogs: [],
  mutedConflicts: [],
);

MergeSession _session(List<MergeConflict> conflicts) => MergeSession(
      conflicts: conflicts,
      archiveData: _emptyExport,
      photos: const {},
      userRepo: _FakeUDR(),
      photoRepo: _FakePhotoRepo(),
    );

MergeConflict _conflict(String id) => MergeConflict(
      recordId: id,
      recordType: 'selection',
      archiveRecord: null,
      localRecord: null,
    );

Widget _wrap({MergeSession? session}) {
  final router = GoRouter(
    initialLocation: '/merge',
    routes: [
      GoRoute(
        path: '/merge',
        builder: (_, __) => const MergeConflictScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const Scaffold(body: Text('settings-screen')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      pendingMergeSessionProvider.overrideWith((_) => session),
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
  group('MergeConflictScreen', () {
    testWidgets('null session → shows אין נתונים למיזוג', (tester) async {
      await tester.pumpWidget(_wrap(session: null));
      await tester.pumpAndSettle();

      expect(find.text('אין נתונים למיזוג'), findsOneWidget);
    });

    testWidgets('first conflict card shows count', (tester) async {
      final session = _session([_conflict('r1'), _conflict('r2')]);
      await tester.pumpWidget(_wrap(session: session));
      await tester.pumpAndSettle();

      expect(find.textContaining('1 מתוך 2'), findsOneWidget);
    });

    testWidgets('keep local → advances to next conflict', (tester) async {
      final session = _session([_conflict('r1'), _conflict('r2')]);
      await tester.pumpWidget(_wrap(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('שמור גרסה מקומית'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 מתוך 2'), findsOneWidget);
    });

    testWidgets('use archive → advances to next conflict', (tester) async {
      final session = _session([_conflict('r1'), _conflict('r2')]);
      await tester.pumpWidget(_wrap(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('השתמש בגרסת הגיבוי'));
      await tester.pumpAndSettle();

      expect(find.textContaining('2 מתוך 2'), findsOneWidget);
    });

    testWidgets('done state shown after resolving last conflict', (tester) async {
      final session = _session([_conflict('r1')]);
      await tester.pumpWidget(_wrap(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('שמור גרסה מקומית'));
      await tester.pumpAndSettle();

      expect(find.text('כל ההתנגשויות נפתרו'), findsOneWidget);
      expect(find.text('סיים'), findsOneWidget);
    });

    testWidgets('סיים completes session and navigates to settings', (tester) async {
      final session = _session([_conflict('r1')]);
      await tester.pumpWidget(_wrap(session: session));
      await tester.pumpAndSettle();

      await tester.tap(find.text('שמור גרסה מקומית'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('סיים'));
      await tester.pumpAndSettle();

      expect(find.text('settings-screen'), findsOneWidget);
    });
  });
}
