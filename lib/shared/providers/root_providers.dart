import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
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
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/services/conflict_resolver.dart';
import '../../domain/services/day_boundary_service.dart';
import '../../domain/services/export_import_service.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../domain/services/reconciliation_service.dart';
import '../../domain/services/routine_resolver.dart';
import '../../domain/services/streak_calculator.dart';

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
/// Override in tests to verify it is watched by AppEntryPoint.
final silentStartupProvider = FutureProvider<void>((ref) async {
  final svc = ref.read(reconciliationServiceProvider);
  final result = await svc.reconcile();
  await svc.acknowledgeUpdate(result.currentContentVersion);
});

/// Silently resolves any product conflicts that exist in the user's selections
/// on cold start, before the home screen renders.
///
/// Uses the same [ConflictResolver] as the manual auto-fix in the schedule
/// screen, but without an undo affordance — this corrects conflicts that were
/// missed at selection time (e.g. when sub-category data was first added).
/// Returns the number of conflicting pairs that were resolved.
final conflictAutoFixProvider = FutureProvider<int>((ref) async {
  final master = await ref.read(masterContentProvider.future);
  final userRepo = ref.read(userDataRepositoryProvider);

  debugPrint('[ConflictAutoFix] contentVersion=${master.manifest.contentVersion}');
  debugPrint('[ConflictAutoFix] subcategories=${master.subcategories.length}');

  final morningSelections = await userRepo.watchSelections(Slot.morning).first;
  final eveningSelections = await userRepo.watchSelections(Slot.evening).first;
  var schedules = await userRepo.watchAllSchedules().first;
  final customProds = await userRepo.watchCustomProducts().first;
  final mutedConflicts = await userRepo.watchMutedConflicts().first;

  final allProducts = [
    ...master.products,
    ...customProds.map((p) => p.toMasterProduct()),
  ];

  final classified = allProducts.where((p) => p.subCategoryId != null).length;
  debugPrint('[ConflictAutoFix] classified=$classified/${allProducts.length}');

  final argireline = allProducts.where((p) => p.id == 'prod-037').firstOrNull;
  final vitc = allProducts.where((p) => p.id == 'prod-016').firstOrNull;
  debugPrint('[ConflictAutoFix] argireline.subCategoryId=${argireline?.subCategoryId}');
  debugPrint('[ConflictAutoFix] vitc.subCategoryId=${vitc?.subCategoryId}');

  Set<String> _selectedIds(List<ProductSelection> sels) =>
      sels.where((s) => s.isSelected).map((s) => s.productId).toSet();

  List<MasterProduct> _productsForSlot(Slot slot, Set<String> ids) =>
      allProducts
          .where((p) =>
              ids.contains(p.id) &&
              (slot == Slot.morning
                  ? p.morningConfig != null
                  : p.eveningConfig != null))
          .toList();

  final morningIds = _selectedIds(morningSelections);
  final eveningIds = _selectedIds(eveningSelections);
  debugPrint('[ConflictAutoFix] morning_selected=${morningIds.length} evening_selected=${eveningIds.length}');
  debugPrint('[ConflictAutoFix] argireline in morning=${morningIds.contains("prod-037")} evening=${eveningIds.contains("prod-037")}');
  debugPrint('[ConflictAutoFix] vitc in morning=${morningIds.contains("prod-016")}');

  final morningProds = _productsForSlot(Slot.morning, morningIds);
  final eveningProds = _productsForSlot(Slot.evening, eveningIds);
  final mutedRuleIds = mutedConflicts.map((m) => m.ruleId).toSet();

  debugPrint('[ConflictAutoFix] morningProds=${morningProds.map((p) => p.id).join(",")}');

  // ── Phase 0: ensure capped products have a default spread schedule ──────────
  // After clearRoutineData (logout), schedules are wiped but product selections
  // are kept. WeeklyMaxRule products with no schedule would show 0 effective days
  // and never surface as conflicts (conflict detection is schedule-agnostic but
  // the UI shows 0 days). Write the spread default here so Phase 1 conflict
  // detection always sees a valid starting state.
  Set<int> _spreadN7(int n) {
    final result = <int>{};
    for (var i = 0; i < n; i++) {
      result.add((i * 7 ~/ n));
    }
    return result;
  }

  final allSlotPairs = [
    ...[for (final p in morningProds) (prod: p, slot: Slot.morning)],
    ...[for (final p in eveningProds) (prod: p, slot: Slot.evening)],
  ];
  for (final pair in allSlotPairs) {
    final p = pair.prod;
    final slot = pair.slot;
    final rule = p.configForSlot(slot)?.frequencyRule;
    if (rule is! WeeklyMaxRule) continue;
    final existing =
        schedules.where((s) => s.productId == p.id && s.slot == slot).firstOrNull;
    if (existing != null) continue; // already scheduled (or explicitly excluded)
    final defaultDays = _spreadN7(rule.maxPerWeek);
    debugPrint('[ConflictAutoFix] ensure-default ${p.id}@${slot.name} → $defaultDays');
    final newSchedule = WeekdaySchedule(
      id: 'autofix-default-${p.id}-${slot.name}',
      productId: p.id,
      slot: slot,
      weekdays: defaultDays,
      lastModified: DateTime.now(),
    );
    await userRepo.upsertSchedule(newSchedule);
    schedules = [...schedules, newSchedule];
  }

  final checker = IncompatibilityChecker();
  final conflicts = checker.getConflictsForDay(
    morningProducts: morningProds,
    eveningProducts: eveningProds,
    rules: master.rules,
    categories: master.categories,
    mutedRuleIds: mutedRuleIds,
  );

  debugPrint('[ConflictAutoFix] raw_conflicts=${conflicts.length}');
  for (final c in conflicts) {
    debugPrint('[ConflictAutoFix]   conflict: ${c.productA.id}(${c.productA.subCategoryId}) × ${c.productB.id}(${c.productB.subCategoryId}) rule=${c.ruleId} muted=${c.isMuted}');
  }

  // Deduplicate: multiple rules can match the same product pair (e.g. a
  // product-level rule AND a sub-category rule both cover Argireline×VitC).
  // Process each unique unordered {productA, productB} pair only once.
  final seen = <String>{};
  final active = conflicts.where((c) {
    if (c.isMuted) return false;
    final key = ([c.productA.id, c.productB.id]..sort()).join('|');
    return seen.add(key);
  }).toList();

  debugPrint('[ConflictAutoFix] deduped_active=${active.length}');
  if (active.isEmpty) return 0;

  const resolver = ConflictResolver();
  int fixCount = 0;

  for (final conflict in active) {
    final inMorning = morningProds.any((p) => p.id == conflict.productA.id) &&
        morningProds.any((p) => p.id == conflict.productB.id);
    final conflictSlot = inMorning ? Slot.morning : Slot.evening;

    debugPrint('[ConflictAutoFix] resolving ${conflict.productA.id} × ${conflict.productB.id} in $conflictSlot');

    final resolution = resolver.resolve(
      productA: conflict.productA,
      productB: conflict.productB,
      slot: conflictSlot,
      schedules: schedules,
    );

    debugPrint('[ConflictAutoFix] mutations=${resolution.mutations.length}: ${resolution.mutations.map((m) => "${m.productId}@${m.slot.name}→${m.days}").join(", ")}');

    for (final m in resolution.mutations) {
      final existing = schedules
          .where((s) => s.productId == m.productId && s.slot == m.slot)
          .firstOrNull;

      // Don't overwrite a non-empty schedule the user explicitly set.
      // An empty schedule (written by a prior auto-fix pass) is safe to
      // re-write because an empty set means "excluded", not "user-chosen days".
      if (existing != null && existing.weekdays.isNotEmpty) {
        debugPrint('[ConflictAutoFix] skip mutation ${m.productId}@${m.slot.name}: user has schedule=${existing.weekdays}');
        continue;
      }

      final updated = WeekdaySchedule(
        id: existing?.id ?? 'autofix-${m.productId}-${m.slot.name}',
        productId: m.productId,
        slot: m.slot,
        weekdays: m.days,
        lastModified: DateTime.now(),
      );
      await userRepo.upsertSchedule(updated);
      // Update local snapshot so later iterations see the new state.
      final idx = schedules.indexWhere(
          (s) => s.productId == m.productId && s.slot == m.slot);
      if (idx >= 0) {
        schedules = [...schedules]..[idx] = updated;
      } else {
        schedules = [...schedules, updated];
      }
    }
    fixCount++;
  }

  debugPrint('[ConflictAutoFix] done — fixed $fixCount pairs');
  return fixCount;
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
      ref.watch(userDataRepositoryProvider).watchSelections(slot),
);

final mutedConflictsProvider = StreamProvider<List<MutedConflict>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchMutedConflicts(),
);

final allSchedulesProvider = StreamProvider(
  (ref) => ref.watch(userDataRepositoryProvider).watchAllSchedules(),
);

/// The global (all-day) custom product order for a slot, as set on the Order
/// Customization screen (S3). Used so the week overview reflects the order the
/// routine already uses rather than re-deriving admin order.
final orderOverrideProvider =
    StreamProvider.family<OrderOverride?, Slot>(
  (ref, slot) =>
      ref.watch(userDataRepositoryProvider).watchOrderOverride(slot),
);

final allDayRecordsProvider = StreamProvider(
  (ref) => ref.watch(userDataRepositoryProvider).watchAllDayRecords(),
);

final customProductsProvider = StreamProvider<List<UserCustomProduct>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchCustomProducts(),
);

// ── Barcode lookup ────────────────────────────────────────────────────────────

final barcodeProductLookupServiceProvider = Provider<BarcodeProductLookupService>(
  (ref) => BarcodeProductLookupService(),
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
    final userRepo = ref.watch(userDataRepositoryProvider);

    final effectiveDate = boundary.parseDate(params.date);
    final dayOfWeek = effectiveDate.weekday % 7; // Sun=0…Sat=6

    await for (final selections in userRepo.watchSelections(params.slot)) {
      final customProds = await userRepo.watchCustomProducts().first;
      final schedules = await userRepo.watchAllSchedules().first;
      final orderOverride =
          await userRepo.getEffectiveOrderOverride(params.slot, dayOfWeek);
      final catOverrideList = await userRepo.watchCategoryOverrides().first;
      final catOverrides = {
        for (final o in catOverrideList) o.productId: o.categoryId,
      };

      final allProducts = [
        ...masterContent.products,
        ...customProds.map((p) => p.toMasterProduct()),
      ];

      if (params.slot == Slot.morning) {
        final p037 = schedules
            .where((s) => s.productId == 'prod-037' && s.slot == Slot.morning)
            .firstOrNull;
        debugPrint('[DailyRoutine] morning: p037@morning='
            '${p037 != null ? "weekdays=${p037.weekdays}" : "NO ROW"}');
        debugPrint('[DailyRoutine] morning: all_schedules=${schedules.length}');
      }

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

      if (params.slot == Slot.morning) {
        debugPrint('[DailyRoutine] morning: p037 in result='
            '${resolved.any((p) => p.id == "prod-037")}');
        debugPrint('[DailyRoutine] morning: result=${resolved.map((p) => p.id).join(",")}');
      }

      yield resolved;
    }
  },
);
