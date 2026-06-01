import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/hebrew_date_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';
import '../../shared/widgets/streak_widget.dart';

enum _ViewMode { list, images }

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

  _ViewMode _viewMode = _ViewMode.list;
  bool _showNames = false;

  // Tracks whether we've called snapshot for each slot today
  final Set<String> _snapshotted = {};

  @override
  void initState() {
    super.initState();
    _loadViewPrefs();
  }

  Future<void> _loadViewPrefs() async {
    final settings = ref.read(settingsRepositoryProvider);
    final mode = await settings.getRoutineViewMode();
    final names = await settings.getRoutineShowNames();
    if (mounted) {
      setState(() {
        _viewMode = mode == 'images' ? _ViewMode.images : _ViewMode.list;
        _showNames = names;
      });
    }
  }

  Future<void> _setViewMode(_ViewMode mode) async {
    setState(() => _viewMode = mode);
    await ref
        .read(settingsRepositoryProvider)
        .setRoutineViewMode(mode == _ViewMode.images ? 'images' : 'list');
  }

  Future<void> _setShowNames(bool value) async {
    setState(() => _showNames = value);
    await ref.read(settingsRepositoryProvider).setRoutineShowNames(value);
  }

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

    final isLoading =
        morningRoutineAsync.isLoading && eveningRoutineAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _buildDayLabel(
                            ref.read(effectiveDateProvider),
                            ref.watch(_userNameProvider).valueOrNull,
                          ),
                          textAlign: TextAlign.right,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'השגרה שלך היום',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTypography.headlineMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ViewModeControl(
                          viewMode: _viewMode,
                          showNames: _showNames,
                          onViewModeChanged: _setViewMode,
                          onShowNamesChanged: _setShowNames,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _viewMode == _ViewMode.images
                              ? 'הקישי על התמונה לסימון בוצע'
                              : 'הקישי על מוצר לסימון בוצע',
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
                            onPressed: () => context.push('/setup/selection'),
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
        // Product content — list or grid depending on view mode
        if (isExpanded)
          _viewMode == _ViewMode.images
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: _showNames ? 0.75 : 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        final isDone = recorded.contains(product.id);
                        return _ProductGridTile(
                          product: product,
                          stepNumber: index + 1,
                          isDone: isDone,
                          showName: _showNames,
                          onTap: record != null
                              ? () => _toggleProduct(record, product.id)
                              : null,
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = products[index];
                        final isToggled = recorded.contains(product.id);
                        final hasConflict =
                            conflictProductIds.contains(product.id);

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

  static String _buildDayLabel(DateTime date, String? userName) {
    final day = HebrewDateStrings.weekdays[date.weekday - 1];
    final name = userName != null && userName.trim().isNotEmpty
        ? userName.trim().split(' ').first
        : null;
    return name != null ? 'יום $day • שלום $name' : 'יום $day';
  }
}

// ── View mode control row ─────────────────────────────────────────────────────

class _ViewModeControl extends StatelessWidget {
  final _ViewMode viewMode;
  final bool showNames;
  final ValueChanged<_ViewMode> onViewModeChanged;
  final ValueChanged<bool> onShowNamesChanged;

  const _ViewModeControl({
    required this.viewMode,
    required this.showNames,
    required this.onViewModeChanged,
    required this.onShowNamesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Leading (right in RTL): segmented pill
        _ViewModeSegmentedPill(viewMode: viewMode, onChanged: onViewModeChanged),
        // Trailing (left in RTL): names chip, only in images mode
        if (viewMode == _ViewMode.images)
          _NamesToggleChip(showNames: showNames, onChanged: onShowNamesChanged)
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

class _ViewModeSegmentedPill extends StatelessWidget {
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewModeSegmentedPill({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: viewMode == _ViewMode.list
          ? 'תצוגת רשימה פעילה'
          : 'תצוגת תמונות פעילה',
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Segment(
              label: 'רשימה',
              icon: Icons.view_agenda_outlined,
              isActive: viewMode == _ViewMode.list,
              onTap: () => onChanged(_ViewMode.list),
            ),
            _Segment(
              label: 'תמונות',
              icon: Icons.grid_view_rounded,
              isActive: viewMode == _ViewMode.images,
              onTap: () => onChanged(_ViewMode.images),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.surfaceContainerLowest : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: isActive ? AppColors.glowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NamesToggleChip extends StatelessWidget {
  final bool showNames;
  final ValueChanged<bool> onChanged;

  const _NamesToggleChip({
    required this.showNames,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: showNames ? 'הסתר שמות מוצרים' : 'הצג שמות מוצרים',
      button: true,
      child: GestureDetector(
        onTap: () => onChanged(!showNames),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: showNames
                ? AppColors.primaryFixed
                : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(9999),
            border: Border.all(
              color: showNames
                  ? AppColors.primary.withAlpha(77)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showNames ? Icons.visibility : Icons.visibility_off,
                size: 16,
                color: showNames
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'שמות',
                style: AppTypography.labelMd.copyWith(
                  color: showNames
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product grid tile (images mode) ──────────────────────────────────────────

class _ProductGridTile extends ConsumerWidget {
  final MasterProduct product;
  final int stepNumber;
  final bool isDone;
  final bool showName;
  final VoidCallback? onTap;

  const _ProductGridTile({
    required this.product,
    required this.stepNumber,
    required this.isDone,
    required this.showName,
    this.onTap,
  });

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      label:
          '${product.name}, שלב $stepNumber, ${isDone ? "בוצע" : "לא בוצע"}',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primaryFixed.withAlpha(77)
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            boxShadow: isDone ? null : AppColors.glowSm,
            border: Border.all(
              color: isDone
                  ? AppColors.primary.withAlpha(77)
                  : Colors.transparent,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPhoto(ref),
                    if (isDone)
                      Container(
                        color: AppColors.primary.withAlpha(130),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    PositionedDirectional(
                      top: 8,
                      start: 8,
                      child: _StepBadge(number: stepNumber, isDone: isDone),
                    ),
                  ],
                ),
              ),
              if (showName)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
                  child: Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    textDirection: _isLikelyLatin(product.name)
                        ? TextDirection.ltr
                        : TextDirection.rtl,
                    style: AppTypography.bodyLg.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto(WidgetRef ref) {
    final asset = product.imageAsset;
    if (asset != null && asset.startsWith('user_photo:')) {
      final key = asset.substring('user_photo:'.length);
      final photoAsync = ref.watch(userPhotoProvider(key));
      return photoAsync.when(
        data: (bytes) => bytes != null
            ? Image.memory(bytes, fit: BoxFit.cover)
            : _fallback(),
        loading: _fallback,
        error: (_, _) => _fallback(),
      );
    } else if (asset != null) {
      return Image.asset(
        asset,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      return _fallback();
    }
  }

  Widget _fallback() => Container(
        color: AppColors.primaryFixed,
        child: const Center(
          child: Icon(
            Icons.spa_outlined,
            size: 48,
            color: AppColors.onPrimaryFixedVariant,
          ),
        ),
      );
}

// ── Step number badge ─────────────────────────────────────────────────────────

class _StepBadge extends StatelessWidget {
  final int number;
  final bool isDone;

  const _StepBadge({required this.number, required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isDone ? AppColors.primary : Colors.white,
        shape: BoxShape.circle,
        boxShadow: AppColors.soft,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: AppTypography.labelMd.copyWith(
          color: isDone ? Colors.white : AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.start,
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

final _userNameProvider = FutureProvider<String?>(
  (ref) => ref.watch(settingsRepositoryProvider).getUserName(),
);
