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
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/onboarding/onboarding_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeMCR implements MasterContentRepository {
  final MasterContent content;
  _FakeMCR(this.content);

  @override
  Future<MasterContent> load() async => content;
}

class _FakeUDR implements UserDataRepository {
  final List<ProductSelection> _morning;
  final List<ProductSelection> _evening;

  _FakeUDR({
    List<ProductSelection> morning = const [],
    List<ProductSelection> evening = const [],
  })  : _morning = morning,
        _evening = evening;

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      Stream.value(slot == Slot.morning ? _morning : _evening);
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
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
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
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
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
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
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
  @override Future<bool> getTapHintSeen() async => false;
  @override Future<void> setTapHintSeen(bool value) async {}
  @override Future<String?> getWeeklyPhotoReminderDismissedDate() async => null;
  @override Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate) async {}
  @override Future<bool> getWeeklyReminderEnabled() async => true;
  @override Future<void> setWeeklyReminderEnabled(bool value) async {}
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

// All navigation is now in-widget state (no route pushes). The router only
// needs the root onboarding route.
Widget _wrap({
  required MasterContent master,
  required VoidCallback onFinish,
  List<ProductSelection> morningSelections = const [],
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
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(
        _FakeUDR(morning: morningSelections),
      ),
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

/// Drives the onboarding flow up to the schedule screen (amSchedule stage).
/// Requires at least one morning product to be pre-selected in the UDR.
///
/// New flow: products → categoryReview → routineSummary → amSchedule.
/// After category review, the routine summary screen appears with a morning
/// CTA ("נתחיל עם שגרת הבוקר"); tapping it advances to amSchedule.
Future<void> _advanceToAmSchedule(WidgetTester tester) async {
  // Step 0: language
  await tester.tap(find.text('עברית'));
  await tester.pumpAndSettle();
  // Step 1 → Step 2
  await tester.tap(find.text('נתחיל?'));
  await tester.pumpAndSettle();
  // Step 2: fill form
  await tester.enterText(find.byType(TextField).first, 'שמי');
  await tester.pumpAndSettle();
  await tester.tap(find.text('נקבה'));
  await tester.pumpAndSettle();
  // Step 2 → Step 3 (V3 product selection)
  await tester.tap(find.text('המשך'));
  await tester.pumpAndSettle();
  // Step 3: product is pre-selected — tap "סידור המדף שלי"
  await tester.tap(find.text('סידור המדף שלי'));
  await tester.pumpAndSettle();
  // Category review → routineSummary (async summary build)
  await tester.tap(find.text('נמשיך לתכנון השגרה'));
  await tester.pumpAndSettle();
  await tester.pump(Duration.zero); // flush _loadSummary async continuation
  await tester.pumpAndSettle();
  // routineSummary → tap morning CTA to reach amSchedule
  await tester.tap(find.text('נתחיל עם שגרת הבוקר'));
  await tester.pumpAndSettle();
}

void main() {
  const cat1 = Category(id: 'cat1', name: 'לחות', order: 1);

  group('Onboarding back navigation', () {
    testWidgets(
        'Back from amSchedule returns to routine summary, not onboarding step 1',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);
      bool onFinishCalled = false;

      // Pre-select p1 so "סידור המדף שלי" is enabled.
      final preSel = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () => onFinishCalled = true,
        morningSelections: preSel,
      ));
      await tester.pumpAndSettle();

      await _advanceToAmSchedule(tester);

      // We should now be on the amSchedule screen.
      expect(find.text('תזמון שבועי'), findsOneWidget,
          reason: 'Should be on schedule screen (amSchedule stage)');

      // The custom header back button calls onBack → goes to routineSummary.
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget,
          reason: 'Schedule screen should show a back button in onboarding mode');

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Should land back on the routine summary screen, NOT onboarding step 1.
      expect(find.text('נתחיל?'), findsNothing,
          reason: 'Back must not return to onboarding step 1 (welcome)');
      expect(onFinishCalled, isFalse,
          reason: 'Pressing back must not complete onboarding');
      expect(find.text('נתחיל עם שגרת הבוקר'), findsOneWidget,
          reason: 'Back from amSchedule should return to the routine summary screen');
    });

    testWidgets(
        'Back from amOrder returns to amSchedule',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      final preSel = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () {},
        morningSelections: preSel,
      ));
      await tester.pumpAndSettle();

      await _advanceToAmSchedule(tester);
      // Advance to amOrder
      await tester.tap(find.text('נמשיך לסדר המריחה'));
      await tester.pumpAndSettle();

      expect(find.text('סדר המריחה בבוקר'), findsOneWidget,
          reason: 'Should be on morning order screen');

      // Press back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should return to amSchedule
      expect(find.text('תזמון שבועי'), findsOneWidget,
          reason: 'Back from amOrder should return to amSchedule');
      expect(find.text('שגרת בוקר'), findsOneWidget,
          reason: 'Should show morning context chip on amSchedule');
    });

    testWidgets(
        'Back from pmSchedule returns to amOrder',
        (tester) async {
      final masterProduct = MasterProduct(
        id: 'p1',
        name: 'קרם לחות',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
        eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      final master = _masterWith([masterProduct], [cat1]);
      final morningPre = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];
      final eveningPre = [
        ProductSelection(
          id: 's2',
          productId: 'p1',
          slot: Slot.evening,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      final router = GoRouter(
        initialLocation: '/onboarding',
        routes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, __) => OnboardingScreen(onFinish: () {}),
          ),
        ],
      );
      await tester.pumpWidget(ProviderScope(
        overrides: [
          masterContentRepositoryProvider
              .overrideWithValue(_FakeMCR(master)),
          userDataRepositoryProvider.overrideWithValue(
            _FakeUDR(morning: morningPre, evening: eveningPre),
          ),
          settingsRepositoryProvider.overrideWithValue(_FakeSettings()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he'),
        ),
      ));
      await tester.pumpAndSettle();

      await _advanceToAmSchedule(tester);
      // amSchedule → amOrder
      await tester.tap(find.text('נמשיך לסדר המריחה'));
      await tester.pumpAndSettle();
      expect(find.text('סדר המריחה בבוקר'), findsOneWidget,
          reason: 'Should be on morning order screen');
      // amOrder → pmSchedule directly (eveningTransition removed)
      await tester.tap(find.text('נראה טוב, נמשיך לשגרת הערב'));
      await tester.pumpAndSettle();

      expect(find.text('שגרת ערב'), findsOneWidget,
          reason: 'Should be on pmSchedule with evening context chip');

      // Press back → should return to amOrder, not amSchedule
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('סדר המריחה בבוקר'), findsOneWidget,
          reason: 'Back from pmSchedule should return to amOrder');
    });
  });
}
