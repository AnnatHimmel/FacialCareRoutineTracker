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
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
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
  @override Future<bool> getTapHintSeen() async => false;
  @override Future<void> setTapHintSeen(bool value) async {}
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
  required VoidCallback onFinish,
  _FakeSettings? settings,
  List<ProductSelection> morningSelections = const [],
  List<ProductSelection> eveningSelections = const [],
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => OnboardingScreen(onFinish: onFinish),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(
        _FakeUDR(morning: morningSelections, evening: eveningSelections),
      ),
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

/// Drives from Step 1 through to the product selection screen (Step 3).
Future<void> _advanceToProductSelection(WidgetTester tester) async {
  await tester.tap(find.text('נתחיל?'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).first, 'שמי');
  await tester.pumpAndSettle();
  await tester.tap(find.text('נקבה'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('המשך'));
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

    testWidgets('Step 3 shows V3 product selection UI with all products',
        (tester) async {
      // V3: unified search+scan — all products visible in "popular" list by default.
      // The V3 list is a lazy ListView; with the onboarding scaffold chrome the
      // default 800×600 viewport pushes the last product off-screen, so use a
      // tall surface to lay out all rows (matches product_selection_screen_test).
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
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
      await _advanceToProductSelection(tester);

      // V3: all products visible in the unified search list.
      expect(find.text('קרם לחות'), findsOneWidget);
      expect(find.text('ג׳ל ניקוי'), findsOneWidget);
      expect(find.text('סרום'), findsOneWidget);
    });

    testWidgets('Step 3 shows "סידור המדף שלי" CTA', (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );

      await tester.pumpWidget(_wrap(master: master, onFinish: () {}));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);

      expect(find.text('סידור המדף שלי'), findsOneWidget);
    });

    testWidgets(
        'Tapping "סידור המדף שלי" (with product pre-selected) navigates to category review',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
      // Pre-populate p1 as selected so the CTA is enabled.
      final preSel = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      bool onFinishCalled = false;

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () => onFinishCalled = true,
        morningSelections: preSel,
      ));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);

      // "סידור המדף שלי" should be enabled (p1 is pre-selected).
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      // Category review should appear.
      expect(find.text('סידרנו את המוצרים לפי שלבים'), findsOneWidget);
      expect(onFinishCalled, isFalse);
    });

    testWidgets(
        'Category review → amSchedule shows schedule header, morning context chip, scheduleContinueToOrder CTA',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
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

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      // Now on category review — advance to amSchedule
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();

      // Schedule header should be visible
      expect(find.text('תזמון שבועי'), findsOneWidget);
      // Morning context chip
      expect(find.text('שגרת בוקר'), findsOneWidget);
      // CTA label for onboarding schedule
      expect(find.text('המשך לסדר המריחה'), findsOneWidget);
    });

    testWidgets(
        'amSchedule → amOrder shows morning order header',
        (tester) async {
      final master = _masterWith(
        [_product('p1', 'קרם לחות', 'cat1')],
        [cat1],
      );
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

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();
      // On amSchedule — tap "המשך לסדר המריחה"
      await tester.tap(find.text('המשך לסדר המריחה'));
      await tester.pumpAndSettle();

      // Morning order header should be visible
      expect(find.text('סדר המריחה בבוקר'), findsOneWidget);
    });

    testWidgets(
        'Evening transition appears when evening products exist after morning order',
        (tester) async {
      // Product with both morning and evening config
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

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () {},
        morningSelections: morningPre,
        eveningSelections: eveningPre,
      ));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();
      // Category review
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();
      // amSchedule
      await tester.tap(find.text('המשך לסדר המריחה'));
      await tester.pumpAndSettle();
      // amOrder — tap morning CTA
      await tester.tap(find.text('נראה טוב, נמשיך לשגרת הערב'));
      await tester.pumpAndSettle();

      // Evening transition screen should appear
      expect(find.text('עכשיו נעבור לשגרת הערב'), findsOneWidget);
    });

    testWidgets(
        'Evening-only selection skips morning steps and goes straight to pmSchedule',
        (tester) async {
      final eveningProduct = MasterProduct(
        id: 'p2',
        name: 'שמן ערב',
        categoryId: 'cat1',
        isDeprecated: false,
        addedInVersion: '1.0.0',
        eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      );
      final master = _masterWith([eveningProduct], [cat1]);
      final eveningPre = [
        ProductSelection(
          id: 's1',
          productId: 'p2',
          slot: Slot.evening,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () {},
        eveningSelections: eveningPre,
      ));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();
      // Category review — tap "המשך לבחירת ימים" → should go to pmSchedule
      // (no morning products, so morning steps are skipped)
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();

      // Should be on pmSchedule (evening schedule header)
      expect(find.text('תזמון שבועי'), findsOneWidget);
      expect(find.text('שגרת ערב'), findsOneWidget);
    });

    testWidgets('Complete onboarding flow (morning only): products → schedule → order → finish',
        (tester) async {
      final master = _masterWith(
        [
          _product('p1', 'קרם לחות', 'cat1'),
          _product('p2', 'ג׳ל ניקוי', 'cat2'),
        ],
        [cat1, cat2],
      );
      final preSel = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      bool onFinishCalled = false;

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () => onFinishCalled = true,
        morningSelections: preSel,
      ));
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

      // Step 2 → Step 3 (V3 product selection)
      await tester.tap(find.text('המשך'));
      await tester.pumpAndSettle();
      expect(find.text('קרם לחות'), findsOneWidget);

      // Step 3: p1 is pre-selected → "סידור המדף שלי" is enabled
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      // Category review
      expect(find.text('סידרנו את המוצרים לפי שלבים'), findsOneWidget);
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();

      // amSchedule
      expect(find.text('תזמון שבועי'), findsOneWidget);
      await tester.tap(find.text('המשך לסדר המריחה'));
      await tester.pumpAndSettle();

      // amOrder
      expect(find.text('סדר המריחה בבוקר'), findsOneWidget);
      await tester.tap(find.text('נראה טוב, נמשיך לשגרת הערב'));
      await tester.pumpAndSettle();
      await tester.pump(Duration.zero); // flush _handleFinish async continuation

      // No evening products → finish directly
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
      final preSel = [
        ProductSelection(
          id: 's1',
          productId: 'p1',
          slot: Slot.morning,
          isSelected: true,
          lastModified: DateTime(2024),
        ),
      ];

      final settings = _FakeSettings(failOnProfileSave: true);
      bool onFinishCalled = false;

      await tester.pumpWidget(_wrap(
        master: master,
        onFinish: () => onFinishCalled = true,
        settings: settings,
        morningSelections: preSel,
      ));
      await tester.pumpAndSettle();

      await _selectHebrew(tester);
      await _advanceToProductSelection(tester);
      await tester.tap(find.text('סידור המדף שלי'));
      await tester.pumpAndSettle();

      // Category review
      await tester.tap(find.text('המשך לבחירת ימים'));
      await tester.pumpAndSettle();

      // amSchedule
      await tester.tap(find.text('המשך לסדר המריחה'));
      await tester.pumpAndSettle();

      // amOrder — tap finish
      await tester.tap(find.text('נראה טוב, נמשיך לשגרת הערב'));
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
