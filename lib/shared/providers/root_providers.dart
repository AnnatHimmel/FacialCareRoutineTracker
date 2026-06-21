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

/// Runs reconciliation silently on every cold start, then fires a background
/// Supabase refresh so brand values (and any fields only in Supabase) flow in
/// automatically without requiring the user to open the product-selection screen.
/// Override in tests to verify it is watched by AppEntryPoint.
final silentStartupProvider = FutureProvider<void>((ref) async {
  final svc = ref.read(reconciliationServiceProvider);
  final result = await svc.reconcile();
  await svc.acknowledgeUpdate(result.currentContentVersion);
  // Fire-and-forget — does not block startup.
  ref.read(masterContentRefreshProvider)();
});

/// Silently resolves any product conflicts that exist in the user's selections
/// on cold start, before the home screen renders.
///
/// Delegates to [RoutineScheduler.ensureDefaultSchedules] and
/// [RoutineScheduler.fixProblems] — this corrects conflicts that were
/// missed at selection time (e.g. when sub-category data was first added).
/// Returns the number of conflicting pairs that were resolved.
final conflictAutoFixProvider = FutureProvider<int>((ref) async {
  final master = await ref.read(masterContentProvider.future);
  final s = ref.read(routineSchedulerProvider);

  await s.ensureDefaultSchedules(master: master);

  final morningResult = await s.fixProblems(master: master, slot: Slot.morning);
  final eveningResult = await s.fixProblems(master: master, slot: Slot.evening);

  return morningResult.applied.length + eveningResult.applied.length;
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

// ── Week glance & day warnings ────────────────────────────────────────────────

final weekGlanceProvider = FutureProvider<WeekGlance>((ref) async {
  final master = await ref.watch(masterContentProvider.future);
  return ref.watch(routineSchedulerProvider).weekGlance(master: master);
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
