import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/incompatibility_rule.dart';
import 'package:skincare_tracker/domain/entities/master_list_manifest.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/enums/rule_scope.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/master_content_repository.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/home/week_glance_screen.dart';
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

  _FakeUDR({
    this.morningSelections = const [],
    this.eveningSelections = const [],
  });

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) => Stream.value(
        slot == Slot.morning ? morningSelections : eveningSelections,
      );

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() => Stream.value([]);

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) => Stream.value(null);

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() => Stream.value([]);

  @override
  Stream<DayRecord?> watchDayRecord(String date, Slot slot) =>
      Stream.value(null);

  @override
  Future<DayRecord> snapshotAndGetDayRecord(
    String date,
    Slot slot,
    List<String> resolvedIds,
    String version,
  ) async =>
      DayRecord(
        id: 'snap',
        date: date,
        slot: slot,
        resolvedProductIds: resolvedIds,
        recordedProductIds: [],
        resolvedAtMasterVersion: version,
        lastModified: DateTime(2024, 1, 15),
      );

  @override
  Future<void> updateDayRecord(DayRecord r) async {}

  @override
  Future<void> upsertSelection(ProductSelection s) =>
      throw UnimplementedError();

  @override
  Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) =>
      throw UnimplementedError();

  @override
  Future<void> upsertOrderOverride(OrderOverride o) =>
      throw UnimplementedError();

  @override
  Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      Stream.value([]);

  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) =>
      Future.value(null);

  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}

  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();

  @override
  Stream<List<DayRecord>> watchAllDayRecords() => Stream.value([]);

  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) => throw UnimplementedError();

  @override
  Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();

  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();

  @override
  Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();

  @override
  Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();

  @override
  Future<UserDataExport> exportAllData() => throw UnimplementedError();

  @override
  Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();

  @override
  Future<void> clearRoutineData() async {}

  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);

  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) async {}

  @override
  Future<void> deleteCustomProduct(String id) async {}

  @override
  Stream<List<CollectionItem>> watchCollectionItems() => Stream.value([]);

  @override
  Future<void> upsertCollectionItem(CollectionItem item) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCollectionItem(String id) => throw UnimplementedError();

  @override
  Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);

  @override
  Future<void> upsertCategoryOverride(CategoryOverride o) async {}

  @override
  Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Test data ─────────────────────────────────────────────────────────────────

// Real data fixtures: DISTINCT product names to guarantee failure against hardcoded screen
final _morningProductRealData = MasterProduct(
  id: 'pm1',
  name: 'RealData Morning Cleanser',
  categoryId: 'cat-cleanser',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
);

final _eveningProductARealData = MasterProduct(
  id: 'pe1',
  name: 'RealData Evening Serum A',
  categoryId: 'cat-serum',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  eveningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
);

final _eveningProductBRealData = MasterProduct(
  id: 'pe2',
  name: 'RealData Evening Serum B',
  categoryId: 'cat-serum',
  isDeprecated: false,
  addedInVersion: '1.0.0',
  eveningConfig: const SlotConfig(order: 2, frequencyRule: DailyRule()),
);

final _masterWithConflict = MasterContent(
  products: [_morningProductRealData, _eveningProductARealData, _eveningProductBRealData],
  categories: [
    const Category(id: 'cat-cleanser', name: 'קלינזר', order: 1),
    const Category(id: 'cat-serum', name: 'סרום', order: 2),
  ],
  rules: [
    IncompatibilityRule(
      id: 'rule-test',
      entityA: RuleTarget(type: RuleTargetType.product, id: 'pe1'),
      entityB: RuleTarget(type: RuleTargetType.product, id: 'pe2'),
      scope: RuleScope.withinSlot,
      reason: 'בדיקת התנגשות ערב',
    ),
  ],
  manifest: const MasterListManifest(
    contentVersion: '1.0.0',
    appVersion: '1.0.0',
    changelog: [],
  ),
);

final _masterNoConflicts = MasterContent(
  products: [_morningProductRealData, _eveningProductARealData, _eveningProductBRealData],
  categories: [
    const Category(id: 'cat-cleanser', name: 'קלינזר', order: 1),
    const Category(id: 'cat-serum', name: 'סרום', order: 2),
  ],
  rules: [],
  manifest: const MasterListManifest(
    contentVersion: '1.0.0',
    appVersion: '1.0.0',
    changelog: [],
  ),
);

ProductSelection _sel(String productId, Slot slot) => ProductSelection(
      id: 'sel_$productId',
      productId: productId,
      slot: slot,
      isSelected: true,
      lastModified: DateTime(2024, 1, 1),
    );

Widget _wrap({
  required MasterContent master,
  required _FakeUDR udr,
}) {
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
    ],
    child: MaterialApp(
      locale: const Locale('he'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: const WeekGlanceScreen(),
      ),
    ),
  );
}

// ── Router-based wrapper for onboarding tests ─────────────────────────────────

Widget _wrapWithRouter({
  required MasterContent master,
  required _FakeUDR udr,
  required bool onboarding,
}) {
  final router = GoRouter(
    initialLocation: '/week-glance',
    routes: [
      GoRoute(
        path: '/week-glance',
        builder: (context, state) => WeekGlanceScreen(onboarding: onboarding),
      ),
      GoRoute(
        path: '/today',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('TODAY_SENTINEL'))),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      masterContentRepositoryProvider.overrideWithValue(_FakeMCR(master)),
      userDataRepositoryProvider.overrideWithValue(udr),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('he'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  group('WeekGlanceScreen (real data)', () {
    testWidgets('should_render_morning_and_evening_slot_labels',
        (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
        eveningSelections: [_sel('pe1', Slot.evening)],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('בוקר'), findsOneWidget);
      expect(find.text('ערב'), findsOneWidget);
    });

    testWidgets('should_display_real_morning_product_name_when_expanded',
        (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('RealData Morning Cleanser'), findsOneWidget);
    });

    testWidgets('should_display_real_evening_product_names_when_expanded',
        (tester) async {
      final udr = _FakeUDR(
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('RealData Evening Serum A'), findsOneWidget);
      expect(find.text('RealData Evening Serum B'), findsOneWidget);
    });

    testWidgets('should_hide_morning_product_when_morning_section_collapsed',
        (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      // Product should be visible initially
      expect(find.text('RealData Morning Cleanser'), findsOneWidget);

      // Find and tap the chevron in the morning header to collapse
      final morningChevron = find.byIcon(Icons.expand_less).first;
      await tester.tap(morningChevron);
      await tester.pumpAndSettle();

      // Product should be hidden after collapse
      expect(find.text('RealData Morning Cleanser'), findsNothing);
    });

    testWidgets('should_show_status_ok_banner_when_morning_has_no_issues',
        (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('השגרה נראית תקינה'), findsOneWidget);
    });

    testWidgets('should_show_check_issues_button_when_evening_has_conflicts',
        (tester) async {
      final udr = _FakeUDR(
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('בדיקת הערות'), findsOneWidget);
    });

    testWidgets('should_display_real_conflict_reason_in_bottom_sheet',
        (tester) async {
      final udr = _FakeUDR(
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
      );
      await tester.pumpWidget(_wrap(
        master: _masterWithConflict,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      // Tap the "בדיקת הערות" button
      await tester.tap(find.text('בדיקת הערות'));
      await tester.pumpAndSettle();

      // Bottom sheet should contain the edit routine button text
      expect(find.textContaining('עריכת שגרת'), findsOneWidget);
      // And the REAL conflict reason from the fixture
      expect(find.text('בדיקת התנגשות ערב'), findsOneWidget);
    });
  });

  group('WeekGlanceScreen (no conflicts)', () {
    testWidgets('should_show_status_ok_for_both_slots_when_no_rules_exist',
        (tester) async {
      final udr = _FakeUDR(
        morningSelections: [_sel('pm1', Slot.morning)],
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
      );
      await tester.pumpWidget(_wrap(
        master: _masterNoConflicts,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      // Both slots should show the "all good" status
      expect(find.text('השגרה נראית תקינה'), findsNWidgets(2));
    });

    testWidgets(
        'should_not_show_check_issues_button_when_no_conflicts_exist',
        (tester) async {
      final udr = _FakeUDR(
        eveningSelections: [
          _sel('pe1', Slot.evening),
          _sel('pe2', Slot.evening),
        ],
      );
      await tester.pumpWidget(_wrap(
        master: _masterNoConflicts,
        udr: udr,
      ));
      await tester.pumpAndSettle();

      expect(find.text('בדיקת הערות'), findsNothing);
    });
  });

  group('WeekGlanceScreen (onboarding mode)', () {
    testWidgets('onboarding_true_shows_cta_and_hides_back_button',
        (tester) async {
      final udr = _FakeUDR();
      await tester.pumpWidget(_wrapWithRouter(
        master: _masterNoConflicts,
        udr: udr,
        onboarding: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('הכול מוכן, מתחילים לזרוח!'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
    });

    testWidgets('onboarding_true_cta_tap_navigates_to_today', (tester) async {
      final udr = _FakeUDR();
      await tester.pumpWidget(_wrapWithRouter(
        master: _masterNoConflicts,
        udr: udr,
        onboarding: true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('הכול מוכן, מתחילים לזרוח!'));
      await tester.pumpAndSettle();

      expect(find.text('TODAY_SENTINEL'), findsOneWidget);
    });

    testWidgets('onboarding_false_no_cta_and_shows_back_button',
        (tester) async {
      final udr = _FakeUDR();
      await tester.pumpWidget(_wrapWithRouter(
        master: _masterNoConflicts,
        udr: udr,
        onboarding: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('הכול מוכן, מתחילים לזרוח!'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    });
  });
}
