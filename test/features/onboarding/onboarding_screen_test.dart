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
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<String?> getLastKnownMasterVersion() async => null;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<int> getUserSchemaVersion() async => 0;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async => false;
  @override Future<void> setOnboardingCompleted(bool v) async {}
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
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => OnboardingScreen(onFinish: onFinish),
      ),
      GoRoute(
        path: '/products/schedule',
        builder: (_, __) => const _AutoPopScreen(),
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

void main() {
  const cat1 = Category(id: 'cat1', name: 'לחות', order: 1);
  const cat2 = Category(id: 'cat2', name: 'ניקוי', order: 2);

  group('OnboardingScreen', () {
    testWidgets('Step 1 displays welcome headline "ברוכה הבאה"',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      expect(find.text('ברוכה הבאה'), findsOneWidget);
    });

    testWidgets('Step 1 displays "בואי נתחיל" button', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      expect(find.text('בואי נתחיל'), findsOneWidget);
    });

    testWidgets('Step 1 does NOT display a skip link', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      // Skip option was removed — users must go through all onboarding steps.
      expect(find.text('דלגי'), findsNothing);
    });

    testWidgets('Tapping "בואי נתחיל" advances to Step 2', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('ספרי לנו עלייך'), findsOneWidget);
    });

    testWidgets('Step 2 displays "ספרי לנו עלייך" headline', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('ספרי לנו עלייך'), findsOneWidget);
    });

    testWidgets('Step 2 displays name text field', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Step 2 displays gender toggle buttons "נקבה" and "זכר"',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      expect(find.text('נקבה'), findsOneWidget);
      expect(find.text('זכר'), findsOneWidget);
    });

    testWidgets('Step 2: "המשך" button is disabled when name is empty',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשיכי',
      );

      expect(continueButton, findsOneWidget);
      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is disabled when name non-empty but gender not selected',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשיכי',
      );

      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is disabled when gender selected but name empty',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשיכי',
      );

      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNull);
    });

    testWidgets(
        'Step 2: "המשך" button is enabled when name non-empty AND gender selected',
        (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();

      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      final continueButton = find.byWidgetPredicate(
        (widget) =>
            widget is ElevatedButton &&
            widget.child is Text &&
            (widget.child as Text).data == 'המשיכי',
      );

      expect(tester.widget<ElevatedButton>(continueButton).onPressed, isNotNull);
    });

    testWidgets('Step 2: "חזרה" button returns to Step 1', (tester) async {
      final master =
          _masterWith([_product('p1', 'קרם לחות', 'cat1')], [cat1]);

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('חזרה'));
      await tester.pumpAndSettle();

      expect(find.text('ברוכה הבאה'), findsOneWidget);
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

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי'));
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

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי'));
      await tester.pumpAndSettle();

      // Skip to summary from guided view
      await tester.tap(find.text('דלגי לסיכום'));
      await tester.pumpAndSettle();

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

      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('דלגי לסיכום'));
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

      // Step 1
      expect(find.text('ברוכה הבאה'), findsOneWidget);

      // Step 1 → Step 2
      await tester.tap(find.text('בואי נתחיל'));
      await tester.pumpAndSettle();
      expect(find.text('ספרי לנו עלייך'), findsOneWidget);

      // Step 2: fill form
      await tester.enterText(find.byType(TextField).first, 'שמי');
      await tester.pumpAndSettle();
      await tester.tap(find.text('נקבה'));
      await tester.pumpAndSettle();

      // Step 2 → Step 3
      await tester.tap(find.text('המשיכי'));
      await tester.pumpAndSettle();
      expect(find.text('קרם לחות'), findsOneWidget);

      // Step 3: skip to summary and finish
      await tester.tap(find.text('דלגי לסיכום'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('המשיכי לתזמון'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero); // flush _handleFinish async continuation

      expect(onFinishCalled, isTrue);
    });
  });
}
