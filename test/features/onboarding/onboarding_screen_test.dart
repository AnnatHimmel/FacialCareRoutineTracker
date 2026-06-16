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
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override
  Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      throw UnimplementedError();
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override
  Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override
  Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();
  @override
  Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();
  @override
  Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      throw UnimplementedError();
  @override
  Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override
  Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
}

class _FakeSettings implements SettingsRepository {
  /// When true, setUserName/setUserGender throw — simulating a transient
  /// persistence failure. The regression guard for the bug where a throw here
  /// skipped setOnboardingCompleted() and re-routed the user to onboarding on
  /// every cold start.
  final bool failOnProfileSave;
  _FakeSettings({this.failOnProfileSave = false});

  /// Records what was actually persisted, so tests assert on the side effect
  /// (the saved flag) rather than only on the navigation callback.
  bool? onboardingCompletedValue;
  String? savedName;
  String? savedGender;

  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<String?> getLastKnownMasterVersion() async => null;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<int> getUserSchemaVersion() async => 0;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async =>
      onboardingCompletedValue ?? false;
  @override Future<void> setOnboardingCompleted(bool v) async {
    onboardingCompletedValue = v;
  }
  @override Future<String?> getUserName() async => savedName;
  @override Future<void> setUserName(String n) async {
    if (failOnProfileSave) throw Exception('simulated name save failure');
    savedName = n;
  }
  @override Future<String?> getUserGender() async => savedGender;
  @override Future<void> setUserGender(String g) async {
    if (failOnProfileSave) throw Exception('simulated gender save failure');
    savedGender = g;
  }
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

// Stub route that immediately pops itself with `true` — mirroring the schedule
// screen finishing — so that `await context.push(...)` in _continueToSchedule
// resolves with a finished result and _handleFinish() is reached in tests.
class _AutoPopScreen extends StatefulWidget {
  const _AutoPopScreen();
  @override
  State<_AutoPopScreen> createState() => _AutoPopScreenState();
}

class _AutoPopScreenState extends State<_AutoPopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop(true);
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SizedBox.shrink());
}

Widget _wrap({
  required MasterContent master,
  required VoidCallback onFinish,
  _FakeSettings? settings,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => OnboardingScreen(onFinish: onFinish),
      ),
      GoRoute(
        path: '/setup/schedule',
        builder: (_, __) => const _AutoPopScreen(),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(_FakeUDR()),
      settingsRepositoryProvider
          .overrideWithValue(settings ?? _FakeSettings()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
    ),
  );
}

Future<void> _selectHebrew(WidgetTester tester) async {
  await tester.tap(find.text('עברית'));
  await tester.pumpAndSettle();
}

void main() {
  const cat1 = Category(id: 'cat1', name: 'לחות', order: 1);
  const cat2 = Category(id: 'cat2', name: 'ניקוי', order: 2);

  group('OnboardingScreen', () {
    testWidgets('Step 1 displays app brand name', (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      expect(find.text('The Glow Protocol'), findsOneWidget);
    });

    testWidgets('Step 1 displays start button', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      expect(find.text('נתחיל?'), findsOneWidget);
    });

    testWidgets('Step 1 does NOT display a skip link', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      // Skip option was removed — users must go through all onboarding steps.
      expect(find.text('דלגי'), findsNothing);
    });

    testWidgets('Tapping start button advances to Step 2', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      expect(find.text('כמה פרטים כדי להתחיל'), findsOneWidget);
    });

    testWidgets('Step 2 displays personal info headline', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      expect(find.text('כמה פרטים כדי להתחיל'), findsOneWidget);
    });

    testWidgets('Step 2 displays name text field', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Step 2 displays gender toggle buttons "נקבה" and "זכר"',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      expect(find.text('נקבה'), findsOneWidget);
      expect(find.text('זכר'), findsOneWidget);
    });

    testWidgets('Step 2: continue button is disabled when name is empty',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.text('המשך'),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets(
        'Step 2: continue button is disabled when name non-empty but gender not selected',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.text('המשך'),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets(
        'Step 2: continue button is disabled when gender selected but name empty',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.text('המשך'),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets(
        'Step 2: continue button is enabled when name non-empty AND gender selected',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.ancestor(
          of: find.text('המשך'),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isFalse);
    });

    testWidgets('Step 2: back button returns to Step 1', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('The Glow Protocol'), findsOneWidget);
    });

    testWidgets('Step 3 shows the first category and its products',
        (tester) async {
      // cat1 (order 1) is shown first in the guided view; cat2 comes after.
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
          _product('p3', 'סרום', 'cat1'),
        ],
        [cat1, cat2],
      );

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      // Guided step 0 shows cat1 products; cat2 products are on a later step.
      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('סרום'), findsOneWidget);
    });

    testWidgets('Step 3 shows the "המשיכי לתזמון" CTA in summary view',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      // Single category means we're on the last step; CTA is already "המשיכי לתזמון"
      expect(find.text('המשיכי לתזמון'), findsOneWidget);
    });

    testWidgets('Tapping "המשיכי לתזמון" in Step 3 calls onFinish',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      bool onFinishCalled = false;

      await tester.pumpWidget(
          _wrap(master: master, onFinish: () => onFinishCalled = true));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי לתזמון'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero); // flush _handleFinish async continuation

      expect(onFinishCalled, isTrue);
    });

    testWidgets('Complete onboarding flow: Step 1 → Step 2 → Step 3 → onFinish',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );

      bool onFinishCalled = false;

      await tester.pumpWidget(
          _wrap(master: master, onFinish: () => onFinishCalled = true));
      await tester.pumpAndSettle();

      // Step 0: select language
      await _selectHebrew(tester);

      // Step 1
      expect(find.text('The Glow Protocol'), findsOneWidget);

      // Step 1 → Step 2
      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();
      expect(find.text('כמה פרטים כדי להתחיל'), findsOneWidget);

      // Step 2: fill form
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Step 2 → Step 3
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
      expect(find.text('קרם לחות'), findsOneWidget);

      // Step 3: advance past first category (nothing selected → skip), then finish from last category
      await tester.tap(find.text('דלגי על השלב'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי לתזמון'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero); // flush _handleFinish async continuation

      expect(onFinishCalled, isTrue);
    });

    // Regression: a transient failure saving name/gender must NOT prevent
    // onboarding_completed from being persisted. Before the fix, all saves
    // shared one try/catch, so a throw in setUserName skipped
    // setOnboardingCompleted(true) → the app re-routed to onboarding on every
    // cold start and the user appeared to "lose" their name and language.
    testWidgets(
        'onboarding_completed is still persisted when name/gender save throws',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      final settings = _FakeSettings(failOnProfileSave: true);
      bool onFinishCalled = false;

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () => onFinishCalled = true,
        settings: settings,
      ));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);

      await tester.tap(find.text('נתחיל?'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי לתזמון'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero); // flush _handleFinish async continuation

      // The critical assertion is on the PERSISTED side effect, not just the
      // navigation callback: onboarding must be marked complete even though the
      // profile-field saves threw.
      expect(settings.onboardingCompletedValue, isTrue,
          reason:
              'setOnboardingCompleted(true) must run even when profile saves fail');
      expect(onFinishCalled, isTrue);
    });
  });
}
