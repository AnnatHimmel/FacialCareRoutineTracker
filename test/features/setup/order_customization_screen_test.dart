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
import 'package:skincare_tracker/features/setup/order_customization_screen.dart';
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
  final OrderOverride? morningOverride;
  final List<OrderOverride> morningPerDayOverrides;
  final List<WeekdaySchedule> schedules;
  final List<UserCustomProduct> customProducts;
  bool deleteOverrideCalled = false;
  bool deletePerDayOverrideCalled = false;
  int? deletedPerDayWeekday;

  _FakeUDR({
    this.morningSelections = const [],
    this.eveningSelections = const [],
    this.morningOverride,
    this.morningPerDayOverrides = const [],
    this.schedules = const [],
    this.customProducts = const [],
  });

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value(
        slot == Slot.morning ? morningSelections : eveningSelections,
      );

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(
        slot == Slot.morning ? morningOverride : null,
      );

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value(
        slot == Slot.morning ? morningPerDayOverrides : const [],
      );

  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async {
    final perDay = (slot == Slot.morning ? morningPerDayOverrides : const <OrderOverride>[])
        .where((o) => o.weekday == weekday)
        .firstOrNull;
    if (perDay != null) return perDay;
    return slot == Slot.morning ? morningOverride : null;
  }

  @override
  Future<void> deleteOrderOverride(Slot slot) async {
    deleteOverrideCalled = true;
  }

  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {
    deletePerDayOverrideCalled = true;
    deletedPerDayWeekday = weekday;
  }

  @override
  Future<void> upsertOrderOverride(OrderOverride o) async {}

  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value(schedules);
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
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
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value(customProducts);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

class _FakeSR implements SettingsRepository {
  bool onboardingCompleted = false;

  @override
  Future<void> setOnboardingCompleted(bool value) async {
    onboardingCompleted = value;
  }

  @override Future<bool> getOnboardingCompleted() async => false;
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String name) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String gender) async {}
  @override Future<String?> getLastExportDate() => throw UnimplementedError();
  @override Future<void> setLastExportDate(String d) => throw UnimplementedError();
  @override Future<String?> getLastKnownMasterVersion() => throw UnimplementedError();
  @override Future<void> setLastKnownMasterVersion(String v) => throw UnimplementedError();
  @override Future<int> getUserSchemaVersion() => throw UnimplementedError();
  @override Future<void> setUserSchemaVersion(int v) => throw UnimplementedError();
  @override Future<int> getLongestStreak() => throw UnimplementedError();
  @override Future<void> setLongestStreak(int s) => throw UnimplementedError();
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

// ── Test data ─────────────────────────────────────────────────────────────────

MasterProduct _product(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

// A product configured for both slots (bi-slot), like Argireline.
MasterProduct _biSlotProduct(String id, String name) => MasterProduct(
      id: id,
      name: name,
      categoryId: 'cat1',
      isDeprecated: false,
      addedInVersion: '1.0.0',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
    );

WeekdaySchedule _emptySchedule(String productId, Slot slot) => WeekdaySchedule(
      id: 'sched-$productId-${slot.name}',
      productId: productId,
      slot: slot,
      weekdays: const {},
      lastModified: DateTime(2024, 1, 1),
    );

MasterContent _master(List<MasterProduct> products) => MasterContent(
      products: products,
      categories: [const Category(id: 'cat1', name: 'לחות', order: 1)],
      rules: [],
      manifest: const MasterListManifest(
        contentVersion: '1.0.0',
        appVersion: '1.0.0',
        changelog: [],
      ),
    );

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 's1',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

OrderOverride _override(Slot slot, List<String> ids) => OrderOverride(
      id: 'ov1',
      slot: slot,
      orderedProductIds: ids,
      lastModified: DateTime(2024, 1, 1),
    );

Widget _wrap({
  required MasterContent master,
  required _FakeUDR udr,
  _FakeSR? sr,
  bool fromSetup = false,
}) {
  final router = GoRouter(
    initialLocation: '/setup/order',
    routes: [
      GoRoute(
        path: '/setup/order',
        builder: (_, _) => OrderCustomizationScreen(fromSetup: fromSetup),
      ),
      GoRoute(
        path: '/today',
        builder: (_, _) => const Scaffold(body: Text('home-screen')),
      ),
      GoRoute(
        path: '/routine-ready',
        builder: (_, _) => const Scaffold(body: Text('routine-ready')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
      settingsRepositoryProvider.overrideWithValue(sr ?? _FakeSR()),
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
  group('OrderCustomizationScreen', () {
    testWidgets('morning product shown when selected', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם לחות')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('קרם לחות'), findsOneWidget);
    });

    testWidgets('no products → shows לא נבחרו מוצרים', (tester) async {
      final udr = _FakeUDR();
      final master = _master([_product('p1', 'קרם לחות')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('לא נבחרו מוצרים'), findsOneWidget);
    });

    testWidgets('fromSetup: true → CTA text is סיום והתחלה', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      expect(find.text('סיום והתחלה'), findsOneWidget);
    });

    testWidgets('fromSetup: false → CTA text is שמירת הסדר החדש', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, fromSetup: false),
      );
      await tester.pumpAndSettle();

      expect(find.text('שמירת הסדר החדש'), findsOneWidget);
    });

    testWidgets(
        'fromSetup: true → save sets onboardingCompleted and navigates to /routine-ready',
        (tester) async {
      final sr = _FakeSR();
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(
        _wrap(master: master, udr: udr, sr: sr, fromSetup: true),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('סיום והתחלה'));
      await tester.pumpAndSettle();

      expect(sr.onboardingCompleted, isTrue);
      expect(find.text('routine-ready'), findsOneWidget);
    });

    testWidgets('reset button visible when order override exists', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        morningOverride: _override(Slot.morning, ['p1']),
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('איפוס לסדר המומלץ'), findsOneWidget);
    });

    testWidgets('tapping reset button calls deleteOrderOverride', (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        morningOverride: _override(Slot.morning, ['p1']),
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('איפוס לסדר המומלץ'));
      await tester.pumpAndSettle();

      expect(udr.deleteOverrideCalled, isTrue);
    });

    // Regression: the Order screen was the only routine surface that ignored
    // custom products (built its list from master.products alone), so an owned
    // custom product appeared in Week Glance / Daily Home but vanished here.
    testWidgets('custom product shown in the order list', (tester) async {
      final custom = UserCustomProduct(
        id: 'c1',
        name: 'מוצר מותאם אישית',
        categoryId: 'cat1',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2024, 1, 1),
      );
      final udr = _FakeUDR(
        morningSelections: [_sel('c1', Slot.morning)],
        customProducts: [custom],
      );
      final master = _master([_product('p1', 'קרם לחות')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('מוצר מותאם אישית'), findsOneWidget);
    });

    // Regression: conflict resolver clears a product's morning schedule (sets
    // weekdays={}) but leaves the morning ProductSelection isSelected=true.
    // The order screen must not show the product in the morning list.
    testWidgets(
        'product with empty morning schedule excluded from morning order list',
        (tester) async {
      // Argireline-like: selected for morning AND evening, but morning schedule
      // was cleared to {} by the conflict resolver.
      // Without the fix the product would appear in BOTH sections (findsNWidgets(2)).
      // With the fix it must appear only in the evening section (findsOneWidget).
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        eveningSelections: [_sel('p1', Slot.evening)],
        schedules: [_emptySchedule('p1', Slot.morning)],
      );
      final master = _master([_biSlotProduct('p1', 'ארגירלין')]);

      await tester.pumpWidget(_wrap(master: master, udr: udr));
      await tester.pumpAndSettle();

      // Appears exactly once — evening section only, not morning.
      expect(find.text('ארגירלין'), findsOneWidget);
    });
  });

  group('OrderCustomizationScreen — per-day panel (onboarding mode)', () {
    Widget wrapOnboarding({
      required MasterContent master,
      required _FakeUDR udr,
      _FakeSR? sr,
    }) {
      return ProviderScope(
        overrides: [
          masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
          userDataRepositoryProvider.overrideWithValue(udr),
          settingsRepositoryProvider.overrideWithValue(sr ?? _FakeSR()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('he', 'MA'),
          home: OrderCustomizationScreen(
            onboardingSlot: Slot.morning,
            onContinue: () {},
            onBack: () {},
          ),
        ),
      );
    }

    testWidgets('advanced panel toggle is present', (tester) async {
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(wrapOnboarding(master: master, udr: udr));
      await tester.pumpAndSettle();

      expect(find.text('אפשרויות מתקדמות'), findsOneWidget);
    });

    testWidgets('per-day section visible after expanding advanced panel', (tester) async {
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(wrapOnboarding(master: master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('אפשרויות מתקדמות'));
      await tester.pumpAndSettle();

      // Should show the per-day section title
      expect(find.text('שינוי סדר לפי יום'), findsOneWidget);
    });

    testWidgets('seven weekday rows shown when advanced panel expanded', (tester) async {
      final udr = _FakeUDR(morningSelections: [_sel('p1', Slot.morning)]);
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(wrapOnboarding(master: master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('אפשרויות מתקדמות'));
      await tester.pumpAndSettle();

      // Should show all 7 day rows (ראשון, שני, שלישי, רביעי, חמישי, שישי, שבת)
      expect(find.text('יום ראשון'), findsOneWidget);
      expect(find.text('יום שני'), findsOneWidget);
      expect(find.text('יום שבת'), findsOneWidget);
    });

    testWidgets('custom-order badge shown for day that has per-day override', (tester) async {
      final perDayOverride = OrderOverride(
        id: 'pd1',
        slot: Slot.morning,
        weekday: 1, // Monday
        orderedProductIds: ['p1'],
        lastModified: DateTime(2024),
      );
      final udr = _FakeUDR(
        morningSelections: [_sel('p1', Slot.morning)],
        morningPerDayOverrides: [perDayOverride],
      );
      final master = _master([_product('p1', 'קרם')]);

      await tester.pumpWidget(wrapOnboarding(master: master, udr: udr));
      await tester.pumpAndSettle();

      await tester.tap(find.text('אפשרויות מתקדמות'));
      await tester.pumpAndSettle();

      expect(find.text('סדר מותאם'), findsOneWidget);
    });
  });
}
