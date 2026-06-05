import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/bundled/master_content_repository_impl.dart';
import '../../data/local/database/app_database.dart';
import '../../data/local/photo_storage/photo_repository_android.dart';
import '../../data/local/photo_storage/photo_repository_web.dart';
import '../../data/local/preferences/settings_repository_impl.dart';
import '../../data/repositories_impl/user_data_repository_impl.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/muted_conflict.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/repositories/photo_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/user_data_repository.dart';
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
  (ref) => MasterContentRepositoryImpl(),
);

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

final exportImportServiceProvider = Provider(
  (ref) => ExportImportService(
    ref.watch(userDataRepositoryProvider),
    ref.watch(photoRepositoryProvider),
    ref.watch(settingsRepositoryProvider),
  ),
);

// ── Derived async providers ───────────────────────────────────────────────────

final onboardingCompletedProvider = FutureProvider<bool>(
  (ref) => ref.watch(settingsRepositoryProvider).getOnboardingCompleted(),
);

/// Current app locale. Defaults to feminine Hebrew; switches to `he_MA`
/// for masculine Hebrew, or `en` for English.
/// Update by reading `.notifier` and setting `.state`.
final appLocaleProvider = StateProvider<Locale>((ref) => const Locale('he'));

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

final allDayRecordsProvider = StreamProvider(
  (ref) => ref.watch(userDataRepositoryProvider).watchAllDayRecords(),
);

final customProductsProvider = StreamProvider<List<UserCustomProduct>>(
  (ref) => ref.watch(userDataRepositoryProvider).watchCustomProducts(),
);

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

    await for (final selections in userRepo.watchSelections(params.slot)) {
      final customProds = await userRepo.watchCustomProducts().first;
      final schedules = await userRepo.watchAllSchedules().first;
      final orderOverride =
          await userRepo.watchOrderOverride(params.slot).first;

      final allProducts = [
        ...masterContent.products,
        ...customProds.map((p) => p.toMasterProduct()),
      ];

      yield resolver.resolve(
        date: boundary.parseDate(params.date),
        slot: params.slot,
        allProducts: allProducts,
        categories: masterContent.categories,
        selections: selections,
        schedules: schedules,
        orderOverride: orderOverride,
        boundary: boundary,
      );
    }
  },
);
