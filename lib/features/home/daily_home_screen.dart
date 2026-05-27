import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';
import '../../shared/widgets/streak_widget.dart';

class DailyHomeScreen extends ConsumerStatefulWidget {
  const DailyHomeScreen({super.key});

  @override
  ConsumerState<DailyHomeScreen> createState() => _DailyHomeScreenState();
}

class _DailyHomeScreenState extends ConsumerState<DailyHomeScreen> {
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

  // Tracks whether we've called snapshot for each slot today
  final Set<String> _snapshotted = {};

  String get _todayStr {
    final boundary = ref.read(dayBoundaryServiceProvider);
    return boundary.formatDate(ref.read(effectiveDateProvider));
  }

  Future<void> _ensureRecord(
    String date,
    Slot slot,
    List<MasterProduct> products,
    DayRecord? existing,
  ) async {
    final key = '${date}_${slot.name}';
    if (existing != null || _snapshotted.contains(key)) return;
    _snapshotted.add(key);

    final userRepo = ref.read(userDataRepositoryProvider);
    final masterAsync = ref.read(masterContentProvider);
    final masterVersion =
        masterAsync.valueOrNull?.manifest.contentVersion ?? '1.0.0';

    await userRepo.snapshotAndGetDayRecord(
      date,
      slot,
      products.map((p) => p.id).toList(),
      masterVersion,
    );
  }

  Future<void> _toggleProduct(
    DayRecord record,
    String productId,
  ) async {
    final repo = ref.read(userDataRepositoryProvider);
    final recorded = List<String>.from(record.recordedProductIds);
    if (recorded.contains(productId)) {
      recorded.remove(productId);
    } else {
      recorded.add(productId);
    }
    await repo.updateDayRecord(
      record.copyWith(
        recordedProductIds: recorded,
        lastModified: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateStr = _todayStr;

    final morningRoutineAsync =
        ref.watch(dailyRoutineProvider((date: dateStr, slot: Slot.morning)));
    final eveningRoutineAsync =
        ref.watch(dailyRoutineProvider((date: dateStr, slot: Slot.evening)));
    final morningRecordAsync =
        ref.watch(_dayRecordProvider((date: dateStr, slot: Slot.morning)));
    final eveningRecordAsync =
        ref.watch(_dayRecordProvider((date: dateStr, slot: Slot.evening)));
    final allRecordsAsync = ref.watch(allDayRecordsProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);
    final masterAsync = ref.watch(masterContentProvider);

    final morningProducts = morningRoutineAsync.valueOrNull ?? [];
    final eveningProducts = eveningRoutineAsync.valueOrNull ?? [];
    final morningRecord = morningRecordAsync.valueOrNull;
    final eveningRecord = eveningRecordAsync.valueOrNull;
    final allRecords = allRecordsAsync.valueOrNull ?? [];
    final mutedIds =
        (mutedAsync.valueOrNull ?? []).map((m) => m.ruleId).toSet();

    // Ensure day records exist once products are resolved
    if (morningProducts.isNotEmpty) {
      _ensureRecord(dateStr, Slot.morning, morningProducts, morningRecord);
    }
    if (eveningProducts.isNotEmpty) {
      _ensureRecord(dateStr, Slot.evening, eveningProducts, eveningRecord);
    }

    // Compute streak
    final boundary = ref.read(dayBoundaryServiceProvider);
    final calculator = ref.read(streakCalculatorProvider);
    final streakResult = calculator.compute(
      allRecords: allRecords,
      asOf: DateTime.now(),
      boundary: boundary,
    );

    // Conflict info
    final List<ConflictInfo> conflicts = masterAsync.valueOrNull != null
        ? ref.read(incompatibilityCheckerProvider).getConflictsForDay(
            morningProducts: morningProducts,
            eveningProducts: eveningProducts,
            rules: masterAsync.valueOrNull!.rules,
            categories: masterAsync.valueOrNull!.categories,
            mutedRuleIds: mutedIds,
          )
        : [];

    final Set<String> conflictProductIds = {
      for (final c in conflicts) ...<String>[c.productA.id, c.productB.id],
    };

    final isLoading = morningRoutineAsync.isLoading && eveningRoutineAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _formatDateHebrew(ref.read(effectiveDateProvider)),
          style: AppTypography.headlineMd,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_camera_outlined),
            tooltip: l10n.navJournal,
            onPressed: () => context.push('/skin-log/$dateStr'),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Streak widget
                if (allRecords.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: StreakWidget(
                        currentStreak: streakResult.currentStreak,
                        longestStreak: streakResult.longestStreak,
                        weekMissesUsed: streakResult.missesThisWeek,
                      ),
                    ),
                  ),

                // Morning slot
                _buildSlotSection(
                  slot: Slot.morning,
                  products: morningProducts,
                  record: morningRecord,
                  conflictProductIds: conflictProductIds,
                ),

                // Evening slot
                _buildSlotSection(
                  slot: Slot.evening,
                  products: eveningProducts,
                  record: eveningRecord,
                  conflictProductIds: conflictProductIds,
                ),

                // Empty state
                if (morningProducts.isEmpty && eveningProducts.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.wb_sunny_outlined,
                            size: 64,
                            color: AppColors.secondaryContainer,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'אין מוצרים להיום',
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () =>
                                context.push('/setup/selection'),
                            child: const Text('הוסף מוצרים'),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  Widget _buildSlotSection({
    required Slot slot,
    required List<MasterProduct> products,
    required DayRecord? record,
    required Set<String> conflictProductIds,
  }) {
    if (products.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    final isExpanded = _sectionExpanded[slot] ?? true;
    final recorded = record?.recordedProductIds.toSet() ?? {};

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SlotSectionHeader(
            slot: slot,
            productCount: products.length,
            isExpanded: isExpanded,
            onToggle: () =>
                setState(() => _sectionExpanded[slot] = !isExpanded),
          ),
        ),
        if (isExpanded)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                final isToggled = recorded.contains(product.id);
                final hasConflict =
                    conflictProductIds.contains(product.id);

                return RoutineItemRow(
                  product: product,
                  isToggled: isToggled,
                  onToggle: () {
                    if (record != null) {
                      _toggleProduct(record, product.id);
                    }
                  },
                  hasConflict: hasConflict,
                );
              },
              childCount: products.length,
            ),
          ),
      ],
    );
  }

  String _formatDateHebrew(DateTime date) {
    const months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    return '${date.day} ב${months[date.month - 1]}';
  }
}

final _dayRecordProvider =
    StreamProvider.family<DayRecord?, ({String date, Slot slot})>(
  (ref, params) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecord(params.date, params.slot),
);
