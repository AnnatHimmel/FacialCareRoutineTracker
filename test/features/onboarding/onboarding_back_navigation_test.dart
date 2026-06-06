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
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/onboarding/onboarding_screen.dart';
import 'package:skincare_tracker/features/setup/product_selection_screen.dart';
import 'package:skincare_tracker/features/setup/schedule_setup_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value([]);
  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);
  @override
  Future<void> upsertSelection(ProductSelection s) async {}
  @override
  Future<void> muteConflict(MutedConflict m) async {}
  @override
  Future<void> unmuteConflict(String ruleId) async {}
  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override
  Future<void> deleteCustomProduct(String id) async {}
  @override
  Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      Stream.value(null);
  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async {}
  @override
  Stream<OrderOverride?> watchOrderOverride(Slot s) => Stream.value(null);
  @override
  Future<void> upsertOrderOverride(OrderOverride o) async {}
  @override
  Future<void> deleteOrderOverride(Slot s) async {}
  @override
  Stream<DayRecord?> watchDayRecord(String d, Slot s) => Stream.value(null);
  @override
  Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override
  Future<void> updateDayRecord(DayRecord r) async {}
  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      Stream.value([]);
  @override
  Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) => Stream.value(null);
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) async {}
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => Stream.value([]);
  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) async {}
}

class _FakeSettings implements SettingsRepository {
  bool onboardingCompleted = false;
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<String?> getLastKnownMasterVersion() async => null;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<int> getUserSchemaVersion() async => 0;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async => onboardingCompleted;
  @override Future<void> setOnboardingCompleted(bool v) async {
    onboardingCompleted = v;
  }
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String n) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String g) async {}
  @override Future<void> clearUserProfile() async {}
  @override Future<String> getRoutineViewMode() async => 'images';
  @override Future<void> setRoutineViewMode(String m) async {}
  @override Future<bool> getRoutineShowNames() async => true;
  @override Future<void> setRoutineShowNames(bool v) async {}
  @override Future<String> getAppLanguage() async => 'he';
  @override Future<void> setAppLanguage(String code) async {}
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

/// Router that mirrors the real app structure: `/onboarding` embeds the
/// product-selection step, which pushes the nested `/products/schedule` route
/// living inside the shell — exactly as in [appRouter].
Widget _wrap({
  required MasterContent master,
  required VoidCallback onFinish,
}) {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => OnboardingScreen(onFinish: onFinish),
      ),
      GoRoute(
        path: '/today',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('TODAY_SCREEN'))),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(body: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/products',
                builder: (_, __) =>
                    const ProductSelectionScreen(isTabDestination: true),
                routes: [
                  GoRoute(
                    path: 'schedule',
                    builder: (_, __) =>
                        const ScheduleSetupScreen(fromProducts: true),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(_FakeUDR()),
      settingsRepositoryProvider.overrideWithValue(_FakeSettings()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
    ),
  );
}

/// Drives the onboarding flow up to the schedule screen.
/// Assumes language (step 0) was already selected before calling this.
Future<void> _advanceToSchedule(WidgetTester tester) async {
  // Step 1 → Step 2
  await tester.tap(find.text('נתחיל?'));
  await tester.pumpAndSettle();
  // Step 2 → Step 3 (product selection)
  await tester.enterText(find.byType(TextField).first, 'שמי');
  await tester.pumpAndSettle();
  await tester.tap(find.text('נקבה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('המשך'));
  await tester.pumpAndSettle();
  // Step 3: single category means we're on the last step; CTA is already "המשיכי לתזמון"
  await tester.tap(find.text('המשיכי לתזמון'));
  await tester.pumpAndSettle();
}

void main() {
  const cat1 = Category(id: 'cat1', name: 'לחות', order: 1);

  group('Onboarding back navigation from schedule', () {
    testWidgets(
        'Back from schedule returns to product selection, not onboarding step 1',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);
      bool onFinishCalled = false;

      await tester.pumpWidget(
          _wrap(master: master, onFinish: () => onFinishCalled = true));
      await tester.pumpAndSettle();

      // Step 0: select language (added when language selection step was introduced)
      await tester.tap(find.text('עברית'));
      await tester.pumpAndSettle();

      await _advanceToSchedule(tester);

      // We should now be on the schedule screen with a back button.
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget,
          reason: 'Schedule screen should show a back button');

      // Press back.
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should land on product selection (its CTA), NOT the onboarding
      // welcome screen, and onboarding must NOT have been finished.
      expect(find.text('The Glow Protocol'), findsNothing,
          reason: 'Back must not return to onboarding step 1');
      expect(onFinishCalled, isFalse,
          reason: 'Pressing back must not complete onboarding');
      expect(find.text('המשיכי לתזמון'), findsOneWidget,
          reason: 'Back should return to the product selection screen');
    });
  });
}
