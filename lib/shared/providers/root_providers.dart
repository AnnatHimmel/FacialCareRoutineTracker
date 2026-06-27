import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/bundled/master_content_repository_impl.dart';
import '../../data/cache/shared_prefs_master_content_cache.dart';
import '../../data/local/database/app_database.dart';
import '../../data/remote/supabase_master_content_data_source.dart';
import '../../data/remote_cached/remote_cached_master_content_repository_impl.dart';
import '../../data/local/photo_storage/photo_repository_android.dart';
import '../../data/local/photo_storage/photo_repository_web.dart';
import '../../data/local/preferences/settings_repository_impl.dart';
import '../../data/repositories_impl/user_data_repository_impl.dart';
import '../../domain/entities/category_override.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/muted_conflict.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/services/schedule_days.dart';
import '../../domain/entities/order_override.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/services/pao_calculator.dart';
import '../../domain/services/product_classifier.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/repositories/refreshable_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/user_data_repository.dart';
import '../../data/remote/barcode_lookup_service.dart';
import '../../data/remote/scrapers/open_beauty_facts_name_search_scraper.dart';
import '../../data/remote/scrapers/incidecoder_scraper.dart';
import '../../data/remote/scrapers/olive_young_global_scraper.dart';
import '../../data/remote/scrapers/yes_style_scraper.dart';
import '../../data/remote/scrapers/iherb_scraper.dart';
import '../../domain/services/day_boundary_service.dart';
import '../../domain/services/export_import_service.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../domain/services/reconciliation_service.dart';
import '../../domain/services/routine_resolver.dart';
import '../../domain/services/routine_scheduler.dart';
import '../../domain/services/streak_calculator.dart';
import '../../domain/services/week_glance_builder.dart';

// ── Database (singleton, initialized in main.dart via override) ──────────────

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('AppDatabase must be provided via override'),
);

// ── Repositories ─────────────────────────────────────────────────────────────

final masterContentRepositoryProvider = Provider<MasterContentRepository>(
  (ref) => RemoteCachedMasterContentRepositoryImpl(
    bundled: MasterContentRepositoryImpl(),
    remote: SupabaseMasterContentDataSource(Supabase.instance.client),
    cache: SharedPrefsMasterContentCache(),
  ),
);

/// Returns a callback that triggers a background remote refresh and
/// invalidates [masterContentProvider] when fresh data arrives.
/// In tests that override [masterContentRepositoryProvider] with a fake
/// that does not implement [RefreshableRepository], returns a no-op.
final masterContentRefreshProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.watch(masterContentRepositoryProvider);
  if (repo is RefreshableRepository) {
    return () async {
      await (repo as RefreshableRepository).refresh();
      ref.invalidate(masterContentProvider);
    };
  }
  return () async {};
});

final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => UserDataRepositoryImpl(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepositoryImpl(),
);

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  if (kIsWeb) return PhotoRepositoryWeb();
  return PhotoRepositoryAndroid();
});

// ── Services ──────────────────────────────────────────────────────────────────

final dayBoundaryServiceProvider = Provider(
  (ref) => DayBoundaryService(),
);

final routineResolverProvider = Provider(
  (ref) => RoutineResolver(),
);

final routineSchedulerProvider = Provider<RoutineScheduler>(
  (ref) => RoutineScheduler(ref.watch(userDataRepositoryProvider)),
);

final streakCalculatorProvider = Provider(
  (ref) => StreakCalculator(),
);

final incompatibilityCheckerProvider = Provider(
  (ref) => IncompatibilityChecker(),
);

final reconciliationServiceProvider = Provider(
  (ref) => ReconciliationService(
    ref.watch(masterContentRepositoryProvider),
    ref.watch(userDataRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);

/// Runs reconciliation silently on every cold start.
/// masterContentProvider already fetches from Supabase on first load, so no
/// explicit background refresh is needed here.
/// Override in tests to verify it is watched by AppEntryPoint.
final silentStartupProvider = FutureProvider<void>((ref) async {
  final svc = ref.read(reconciliationServiceProvider);
  final result = await svc.reconcile();
  await svc.acknowledgeUpdate(result.currentContentVersion);
});

/// Seeds any missing default schedules on cold start, before the home screen
/// renders.
///
/// Bug 1 fix: [RoutineScheduler.fixProblems] is intentionally NOT called here.
/// Conflict resolution is advisory only (PRD §UC-4b) — it must never silently
/// overwrite a schedule the user has deliberately set. The "Fix problems"
/// action is surfaced explicitly in the UI when the user opts in.
///
/// Also heals "selected but scheduled nowhere" products that lack any active
/// days across all slots (e.g. orphaned rows from a previous bug), by removing
/// their empty WeekdaySchedule rows so the scheduler can re-seed them cleanly
/// via ensureDefaultSchedules. Products that are active in at least one slot
/// are left untouched.
final conflictAutoFixProvider = FutureProvider<int>((ref) async {
  final master = await ref.read(masterContentProvider.future);
  final s = ref.read(routineSchedulerProvider);

  await s.ensureDefaultSchedules(master: master);

  // Heal: for each selected product that has zero effective days across all
  // slots (selected-but-active-nowhere), seed the default schedule directly.
  // This covers orphaned empty rows that ensureDefaultSchedules skips because
  // it only seeds products with NO row at all (if (existing != null) continue).
  // Products that are active in at least one slot are left untouched.
  final repo = ref.read(userDataRepositoryProvider);
  final allSchedules = await repo.watchAllSchedules().first;
  final morningSels = await repo.watchSelections(Slot.morning).first;
  final eveningSels = await repo.watchSelections(Slot.evening).first;

  final selectedBySlot = {
    Slot.morning: morningSels.where((s) => s.isSelected).toList(),
    Slot.evening: eveningSels.where((s) => s.isSelected).toList(),
  };

  for (final entry in selectedBySlot.entries) {
    final slot = entry.key;
    for (final sel in entry.value) {
      final productId = sel.productId;
      // Compute effective days across ALL slots for this product.
      final totalEffectiveDays = [Slot.morning, Slot.evening]
          .expand((sl) {
            final row = allSchedules
                .where((sch) => sch.productId == productId && sch.slot == sl)
                .firstOrNull;
            if (row != null) return row.weekdays;
            // No row = DailyRule product, which is always active.
            final mp = master.products
                .where((p) => p.id == productId)
                .firstOrNull;
            if (mp == null) return <int>{};
            return defaultDaysFor(mp, sl);
          })
          .toSet();

      if (totalEffectiveDays.isNotEmpty) continue;

      // All slots are empty — seed this slot with the default schedule.
      final mp = master.products
          .where((p) => p.id == productId)
          .firstOrNull;
      if (mp == null) continue;

      final existing = allSchedules
          .where((sch) => sch.productId == productId && sch.slot == slot)
          .firstOrNull;
      if (existing != null && existing.weekdays.isNotEmpty) continue;

      final defaults = defaultDaysFor(mp, slot);
      if (defaults.isEmpty) continue; // no default to apply

      final rowToWrite = existing != null
          ? existing.copyWith(weekdays: defaults, lastModified: DateTime.now())
          : WeekdaySchedule(
              id: 'heal-$productId-${slot.name}',
              productId: productId,
              slot: slot,
              weekdays: defaults,
              lastModified: DateTime.now(),
            );
      await repo.upsertSchedule(rowToWrite);
    }
  }

  return 0;
});

final exportImportServiceProvider = Provider(
  (ref) => ExportImportService(
    ref.watch(userDataRepositoryProvider),
    ref.watch(photoRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);

// ── Derived async providers ───────────────────────────────────────────────────

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

final onboardingCompletedProvider = FutureProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).getOnboardingCompleted(),
);

/// Current app locale. Defaults to feminine Hebrew; switches to `he_MA`
/// for masculine Hebrew, or `en` for English.
/// Update by reading `.notifier` and setting `.state`.
final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('he'));

// ── Demo-only PRO toggle (Settings → "תצוגת הדגמה") ──────────────────────────
/// Toggles the Glow PRO experience across screens. In-memory: resets on restart.
final isProDemoProvider = StateProvider<bool>((ref) => false);

/// Forces the day-7 streak milestone / conversion banner on the Today screen.
final milestoneDemoProvider = StateProvider<bool>((ref) => false);

/// Reads saved language and gender from settings and syncs [appLocaleProvider].
/// - English → Locale('en') regardless of gender
/// - Hebrew + male → Locale('he', 'MA')
/// - Hebrew (default) → Locale('he')
/// Watch this in AppEntryPoint to ensure locale is set before routing.
final localeSyncProvider = FutureProvider<void>((ref) async {
  final settings = ref.read(settingsRepositoryProvider);
  final language = await settings.getAppLanguage();
  if (language == 'en') {
    ref.read(appLocaleProvider.notifier).state = const Locale('en');
    return;
  }
  final gender = await settings.getUserGender();
  ref.read(appLocaleProvider.notifier).state =
      gender == 'male' ? const Locale('he', 'MA') : const Locale('he');
});

final masterContentProvider = FutureProvider<MasterContent>(
  (ref) => ref.watch(masterContentRepositoryProvider).load(),
);

final effectiveDateProvider = Provider<DateTime>(
  (ref) => ref.watch(dayBoundaryServiceProvider).todayEffectiveDate,
);

final selectionsProvider =
    StreamProvider.family<List<ProductSelection>, Slot>(
  (ref, slot) =>
      ref.watch(routineSchedulerProvider).watchSelections(slot),
);

final mutedConflictsProvider = StreamProvider<List<MutedConflict>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchMutedConflicts(),
);

final allSchedulesProvider = StreamProvider(
  (ref) => ref.watch(routineSchedulerProvider).watchAllSchedules(),
);

/// The global (all-day) custom product order for a slot, as set on the Order
/// Customization screen (S3). Used so the week overview reflects the order the
/// routine already uses rather than re-deriving admin order.
final orderOverrideProvider =
    StreamProvider.family<OrderOverride?, Slot>(
  (ref, slot) =>
      ref.watch(routineSchedulerProvider).watchOrderOverride(slot),
);

final allDayRecordsProvider = StreamProvider(
  (ref) => ref.watch(userDataRepositoryProvider).watchAllDayRecords(),
);

final customProductsProvider = StreamProvider<List<UserCustomProduct>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchCustomProducts(),
);

// ── Barcode lookup ────────────────────────────────────────────────────────────

final barcodeProductLookupServiceProvider = Provider<BarcodeProductLookupService>(
  (ref) => BarcodeProductLookupService(
    scrapers: [
      OpenBeautyFactsNameSearchScraper(),
      OliveYoungGlobalScraper(),
      YesStyleScraper(),
      IHerbScraper(),
      IncidecoderScraper(), // last — fills ingredients/images when others miss, but lowest brand confidence
    ],
  ),
);

// ── Collection items (product lifecycle) ─────────────────────────────────────

final collectionItemsProvider = StreamProvider<List<CollectionItem>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchCollectionItems(),
);

final categoryOverridesProvider = StreamProvider<List<CategoryOverride>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchCategoryOverrides(),
);

final paoCalculatorProvider = Provider((ref) => const PaoCalculator());

/// Builds a [ProductClassifier] from the RAW bundled subcategories (which carry
/// the `keywords` / `brandLines` the classifier matches on — these are stripped
/// from [MasterContent.subcategories]). Used by the add-product flow to
/// auto-assign a sub-category from a typed/scanned product name.
/// Override in tests with a classifier built from a fixed subcategory list.
final productClassifierProvider = FutureProvider<ProductClassifier>((ref) async {
  final raw = await rootBundle.loadString('assets/data/master_products.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final subs = ((data['subcategories'] as List<dynamic>?) ?? const [])
      .cast<Map<String, dynamic>>();
  return ProductClassifier.fromSubcategories(subs);
});

final userNameProvider = FutureProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).getUserName(),
);

/// Master on/off switch for the weekly skin-tracking reminder card (S4).
/// Toggled by the card's "never show again" action and the Settings switch.
final weeklyReminderEnabledProvider = FutureProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).getWeeklyReminderEnabled(),
);

/// Effective date the weekly reminder was last snoozed ("אחר כך"), or null.
/// Reactive so the debug "resume" reset (and the dismiss action) reflect on the
/// home screen immediately without a restart.
final weeklyReminderDismissedDateProvider = FutureProvider<String?>(
  (ref) =>
      ref.watch(settingsRepositoryProvider).getWeeklyPhotoReminderDismissedDate(),
);

/// Debug-only: forces the weekly reminder card to show even when a skin-log
/// photo within the last 7 days would normally suppress it. In-memory only
/// (resets on app restart); set true by the Settings "Resume reminder" debug
/// action and cleared once a photo is captured. Does **not** override the
/// "snoozed today" or "disabled" rules — only the recent-photo gate.
final weeklyReminderForceShowProvider = StateProvider<bool>((ref) => false);

/// Debug-only callback that empties the shelf (all owned products + their
/// routine wiring) via [UserDataRepositoryImpl.clearShelf]. No-op when the
/// repository is a test fake. Used by the debug Settings tool.
final debugClearShelfProvider = Provider<Future<void> Function()>((ref) {
  final repo = ref.watch(userDataRepositoryProvider);
  return () async {
    if (repo is UserDataRepositoryImpl) await repo.clearShelf();
  };
});

// ── Per-day routine provider ──────────────────────────────────────────────────

typedef _DailyRoutineParams = ({String date, Slot slot});

final dailyRoutineProvider =
    StreamProvider.family<List<MasterProduct>, _DailyRoutineParams>(
  (ref, params) async* {
    final masterContent = await ref.watch(masterContentProvider.future);
    final boundary = ref.watch(dayBoundaryServiceProvider);
    final resolver = ref.watch(routineResolverProvider);
    final scheduler = ref.watch(routineSchedulerProvider);
    final userRepo = ref.watch(userDataRepositoryProvider);
    // Re-run this stream generator whenever the order override changes so the
    // daily routine immediately reflects a new drag order without requiring a
    // selection change to trigger re-emission.
    ref.watch(orderOverrideProvider(params.slot));

    final effectiveDate = boundary.parseDate(params.date);
    final dayOfWeek = effectiveDate.weekday % 7; // Sun=0…Sat=6

    await for (final selections in scheduler.watchSelections(params.slot)) {
      final customProds = await userRepo.watchCustomProducts().first;
      final schedules = await scheduler.watchAllSchedules().first;
      final orderOverride =
          await scheduler.getEffectiveOrderOverride(params.slot, dayOfWeek);
      final catOverrideList = await userRepo.watchCategoryOverrides().first;
      final catOverrides = {
        for (final o in catOverrideList) o.productId: o.categoryId,
      };

      final allProducts = [
        ...masterContent.products,
        ...customProds.map((p) => p.toMasterProduct()),
      ];

      final resolved = resolver.resolve(
        date: effectiveDate,
        slot: params.slot,
        allProducts: allProducts,
        categories: masterContent.categories,
        subcategories: masterContent.subcategories,
        selections: selections,
        schedules: schedules,
        orderOverride: orderOverride,
        boundary: boundary,
        categoryOverrides: catOverrides.isNotEmpty ? catOverrides : null,
      );

      yield resolved;
    }
  },
);

// ── Manual order changes (Order Customization chip + revert sheet) ────────────

/// Describes how a slot's global manual order deviates from the recommended
/// order, over the full set of selected products for that slot. Drives the
/// Order Customization screen's "manual changes" chip (count of moved products)
/// and the revert sheet. Recomputes when the slot's order override, selections,
/// schedules, or category overrides change.
final slotManualOrderChangesProvider =
    FutureProvider.family<ManualOrderChanges, Slot>(
  (ref, slot) async {
    final masterContent = await ref.watch(masterContentProvider.future);
    final scheduler = ref.watch(routineSchedulerProvider);

    // Recompute whenever anything that affects the order or product set changes.
    ref.watch(orderOverrideProvider(slot));
    ref.watch(selectionsProvider(slot));
    ref.watch(allSchedulesProvider);
    ref.watch(categoryOverridesProvider);

    return scheduler.manualOrderChangesForSlot(
      master: masterContent,
      slot: slot,
    );
  },
);

// ── Week glance & day warnings ────────────────────────────────────────────────

/// Bug 4 fix: watch all backing stream providers so Riverpod re-runs the future
/// whenever selections, schedules, custom products, or muted conflicts change.
/// Without these watches, the FutureProvider only re-evaluates when
/// masterContentProvider changes (which is almost never), so freshly-added
/// products were invisible in the week glance until app restart.
final weekGlanceProvider = FutureProvider<WeekGlance>((ref) async {
  final master = await ref.watch(masterContentProvider.future);
  ref.watch(selectionsProvider(Slot.morning));
  ref.watch(selectionsProvider(Slot.evening));
  ref.watch(allSchedulesProvider);
  final customProds = ref.watch(customProductsProvider).valueOrNull ?? [];
  ref.watch(mutedConflictsProvider);
  ref.watch(orderOverrideProvider(Slot.morning));
  ref.watch(orderOverrideProvider(Slot.evening));
  return ref.watch(routineSchedulerProvider).weekGlance(
    master: master,
    extraProducts: customProds.map((p) => p.toMasterProduct()).toList(),
  );
});

final dayWarningsProvider =
    FutureProvider.family<DayWarnings, ({Slot slot, int weekday})>(
  (ref, p) async {
    final master = await ref.watch(masterContentProvider.future);
    return ref
        .watch(routineSchedulerProvider)
        .warningsForDay(master: master, slot: p.slot, weekday: p.weekday);
  },
);
