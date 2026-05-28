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
import '../../shared/widgets/glow_app_bar.dart';
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

    // Done counts for slot headers
    final morningRecorded = morningRecord?.recordedProductIds.toSet() ?? {};
    final eveningRecorded = eveningRecord?.recordedProductIds.toSet() ?? {};
    final morningDone =
        morningProducts.where((p) => morningRecorded.contains(p.id)).length;
    final eveningDone =
        eveningProducts.where((p) => eveningRecorded.contains(p.id)).length;

    final isLoading = morningRoutineAsync.isLoading && eveningRoutineAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        action: IconButton(
          icon: const Icon(Icons.photo_camera_outlined),
          color: AppColors.onSurfaceVariant,
          tooltip: l10n.navJournal,
          onPressed: () => context.push('/skin-log/$dateStr'),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // ── Streak banner ──────────────────────────────────────────
                if (allRecords.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: StreakWidget(
                        currentStreak: streakResult.currentStreak,
                        longestStreak: streakResult.longestStreak,
                        weekMissesUsed: streakResult.missesThisWeek,
                      ),
                    ),
                  ),

                // ── Page title ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDateHebrew(ref.read(effectiveDateProvider)),
                          textAlign: TextAlign.right,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'טקסי טיפוח יומיים',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'התמקדי בבריאות העור שלך היום.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Morning slot ───────────────────────────────────────────
                if (morningProducts.isNotEmpty)
                  _buildSlotSection(
                    slot: Slot.morning,
                    products: morningProducts,
                    record: morningRecord,
                    conflictProductIds: conflictProductIds,
                    doneCount: morningDone,
                  ),

                // ── Evening slot ───────────────────────────────────────────
                if (eveningProducts.isNotEmpty)
                  _buildSlotSection(
                    slot: Slot.evening,
                    products: eveningProducts,
                    record: eveningRecord,
                    conflictProductIds: conflictProductIds,
                    doneCount: eveningDone,
                  ),

                // ── Empty state ────────────────────────────────────────────
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

                // ── Journal CTA card ───────────────────────────────────────
                if (morningProducts.isNotEmpty || eveningProducts.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: _JournalCtaCard(dateStr: dateStr),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
    );
  }

  SliverMainAxisGroup _buildSlotSection({
    required Slot slot,
    required List<MasterProduct> products,
    required DayRecord? record,
    required Set<String> conflictProductIds,
    required int doneCount,
  }) {
    final isExpanded = _sectionExpanded[slot] ?? true;
    final recorded = record?.recordedProductIds.toSet() ?? {};

    return SliverMainAxisGroup(
      slivers: [
        // Section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SlotSectionHeader(
              slot: slot,
              productCount: products.length,
              doneCount: doneCount,
              isExpanded: isExpanded,
              onToggle: () =>
                  setState(() => _sectionExpanded[slot] = !isExpanded),
            ),
          ),
        ),
        // Product rows
        if (isExpanded)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  final isToggled = recorded.contains(product.id);
                  final hasConflict = conflictProductIds.contains(product.id);

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < products.length - 1 ? 8.0 : 0.0,
                    ),
                    child: RoutineItemRow(
                      product: product,
                      isToggled: isToggled,
                      onToggle: () {
                        if (record != null) {
                          _toggleProduct(record, product.id);
                        }
                      },
                      hasConflict: hasConflict,
                    ),
                  );
                },
                childCount: products.length,
              ),
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

// ── Journal CTA card ──────────────────────────────────────────────────────────

class _JournalCtaCard extends StatelessWidget {
  final String dateStr;

  const _JournalCtaCard({required this.dateStr});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.glowLg,
      ),
      child: Row(
        children: [
          // Text (leading in RTL = visual right)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'איך העור מרגיש?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyLg.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'תעדי את התקדמותך',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelMd.copyWith(
                    color: const Color(0xCCFFFFFF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // CTA button (trailing in RTL = visual left)
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () => context.push('/skin-log/$dateStr'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.inverseSurface,
                foregroundColor: AppColors.inverseOnSurface,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: Text(
                'תיעוד עכשיו',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.inverseOnSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _dayRecordProvider =
    StreamProvider.family<DayRecord?, ({String date, Slot slot})>(
  (ref, params) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecord(params.date, params.slot),
);
