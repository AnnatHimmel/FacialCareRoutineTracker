import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/settings/settings_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Stubs ─────────────────────────────────────────────────────────────────────

class _StubSR implements SettingsRepository {
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
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
}

class _StubUDR implements UserDataRepository {
  @override Stream<List<ProductSelection>> watchSelections(Slot s) => const Stream.empty();
  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => const Stream.empty();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => const Stream.empty();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) => const Stream.empty();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) => const Stream.empty();
  @override Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) => throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) => const Stream.empty();
  @override Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => const Stream.empty();
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => const Stream.empty();
  @override Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => Stream.value([]);
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test helper ───────────────────────────────────────────────────────────────

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/settings',
    routes: [
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/export-import',
        builder: (_, __) => const Scaffold(body: Text('export-import')),
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) => const Scaffold(body: Text('about')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWith((_) => _StubSR()),
      userDataRepositoryProvider.overrideWith((_) => _StubUDR()),
      appVersionProvider.overrideWith((_) async => '1.0.0'),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('SettingsScreen – Contact Us', () {
    testWidgets('Contact Us tile is visible in settings', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // he_MA string for settingsContactUs
      expect(find.text('צור קשר'), findsOneWidget);
    });

    testWidgets('tapping Contact Us opens the bottom sheet', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('צור קשר'));
      await tester.pumpAndSettle();

      // he_MA / he string for settingsContactUsSheetTitle
      expect(find.text('יצירת קשר'), findsOneWidget);
    });

    testWidgets('bottom sheet contains a message TextField', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('צור קשר'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });

    testWidgets('Send button is dimmed when the message is empty', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('צור קשר'));
      await tester.pumpAndSettle();

      // he_MA string for settingsContactUsSend
      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('שלח'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, lessThan(1.0));
    });

    testWidgets('Send button becomes fully opaque after typing a message',
        (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.text('צור קשר'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'בדיקה');
      await tester.pumpAndSettle();

      final opacity = tester.widget<AnimatedOpacity>(
        find.ancestor(
          of: find.text('שלח'),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(opacity.opacity, equals(1.0));
    });
  });
}
