import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
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

class _DailyHomeScreenState extends ConsumerState<DailyHomeScreen>
    with WidgetsBindingObserver {
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

  _ViewMode _viewMode = _ViewMode.list;
  bool _showNames = false;

  final Set<String> _snapshotted = {};
  String _lastDateStr = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadViewPrefs();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _checkForDayChange();
    }
  }

  void _checkForDayChange() {
    final boundary = ref.read(dayBoundaryServiceProvider);
    final currentDate = boundary.formatDate(boundary.todayEffectiveDate);
    if (currentDate != _lastDateStr) {
      setState(() {
        _snapshotted.clear();
        _lastDateStr = currentDate;
      });
    }
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
    return boundary.formatDate(boundary.todayEffectiveDate);
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

  Future<void> _toggleProduct(DayRecord record, String productId) async {
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
    final l = AppLocalizations.of(context)!;
    final dateStr = _todayStr;

    if (dateStr != _lastDateStr) {
      _lastDateStr = dateStr;
      _snapshotted.clear();
    }

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

    if (morningProducts.isNotEmpty) {
      _ensureRecord(dateStr, Slot.morning, morningProducts, morningRecord);
    }
    if (eveningProducts.isNotEmpty) {
      _ensureRecord(dateStr, Slot.evening, eveningProducts, eveningRecord);
    }

    final boundary = ref.read(dayBoundaryServiceProvider);
    final calculator = ref.read(streakCalculatorProvider);
    final streakResult = calculator.compute(
      allRecords: allRecords,
      asOf: DateTime.now(),
      boundary: boundary,
    );

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

    final morningRecorded = morningRecord?.recordedProductIds.toSet() ?? {};
    final eveningRecorded = eveningRecord?.recordedProductIds.toSet() ?? {};
    final morningDone =
        morningProducts.where((p) => morningRecorded.contains(p.id)).length;
    final eveningDone =
        eveningProducts.where((p) => eveningRecorded.contains(p.id)).length;

    final isLoading =
        morningRoutineAsync.isLoading && eveningRoutineAsync.isLoading;

    // Build day label from current date + user name
    final effectiveDate = boundary.todayEffectiveDate;
    final userName = ref.watch(_userNameProvider).valueOrNull;
    final dayName = HebrewDateStrings.weekdays[effectiveDate.weekday - 1];
    final dayLabel = (userName != null && userName.trim().isNotEmpty)
        ? l.homeDayLabelGreeting(dayName, userName.trim().split(' ').first)
        : l.homeDayLabel(dayName);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                if (allRecords.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: StreakWidget(
                        currentStreak: streakResult.currentStreak,
                        longestStreak: streakResult.longestStreak,
                        gracesUsed: streakResult.missesThisWeek,
                      ),
                    ),
                  ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          dayLabel,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.homeTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _viewMode == _ViewMode.images
                              ? l.homeTapImageToDone
                              : l.homeTapProductToDone,
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ViewModeControl(
                          viewMode: _viewMode,
                          showNames: _showNames,
                          onViewModeChanged: _setViewMode,
                          onShowNamesChanged: _setShowNames,
                        ),
                      ],
                    ),
                  ),
                ),

                if (morningProducts.isNotEmpty)
                  _buildSlotSection(
                    slot: Slot.morning,
                    products: morningProducts,
                    record: morningRecord,
                    conflictProductIds: conflictProductIds,
                    doneCount: morningDone,
                  ),

                if (morningProducts.isNotEmpty && eveningProducts.isNotEmpty)
                  const SliverToBoxAdapter(child: SizedBox(height: 72)),

                if (eveningProducts.isNotEmpty)
                  _buildSlotSection(
                    slot: Slot.evening,
                    products: eveningProducts,
                    record: eveningRecord,
                    conflictProductIds: conflictProductIds,
                    doneCount: eveningDone,
                  ),

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
                            l.homeEmptyToday,
                            style: AppTypography.headlineMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.push('/setup/selection'),
                            child: Text(l.homeAddProducts),
                          ),
                        ],
                      ),
                    ),
                  ),

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
                          key: ValueKey('tile_${product.id}'),
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
}

// ── View mode control row ─────────────────────────────────────────────────────

TextStyle get _controlLabel =>
    GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, height: 1.0);

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
      children: [
        Expanded(
          child: _ViewModeSegmentedPill(
              viewMode: viewMode, onChanged: onViewModeChanged),
        ),
        if (viewMode == _ViewMode.images) ...[
          const SizedBox(width: 8),
          _NamesToggleChip(showNames: showNames, onChanged: onShowNamesChanged),
        ],
      ],
    );
  }
}

// ── Segmented pill ────────────────────────────────────────────────────────────

class _ViewModeSegmentedPill extends StatelessWidget {
  final _ViewMode viewMode;
  final ValueChanged<_ViewMode> onChanged;

  const _ViewModeSegmentedPill({
    required this.viewMode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: viewMode == _ViewMode.list
          ? l.homeViewListSemantics
          : l.homeViewImagesSemantics,
      child: Container(
        height: 66,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh.withAlpha(179),
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: AppColors.outlineVariant),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _Segment(
                label: l.homeViewList,
                icon: viewMode == _ViewMode.list
                    ? Icons.view_agenda
                    : Icons.view_agenda_outlined,
                isActive: viewMode == _ViewMode.list,
                onTap: () => onChanged(_ViewMode.list),
              ),
            ),
            Expanded(
              child: _Segment(
                label: l.homeViewImages,
                icon: Icons.grid_view_rounded,
                isActive: viewMode == _ViewMode.images,
                onTap: () => onChanged(_ViewMode.images),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatefulWidget {
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
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: double.infinity,
          decoration: BoxDecoration(
            color: widget.isActive
                ? AppColors.surfaceContainerLowest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: widget.isActive ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: widget.isActive
                    ? AppColors.primary
                    : AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: _controlLabel.copyWith(
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Names toggle chip ─────────────────────────────────────────────────────────

class _NamesToggleChip extends StatefulWidget {
  final bool showNames;
  final ValueChanged<bool> onChanged;

  const _NamesToggleChip({
    required this.showNames,
    required this.onChanged,
  });

  @override
  State<_NamesToggleChip> createState() => _NamesToggleChipState();
}

class _NamesToggleChipState extends State<_NamesToggleChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: widget.showNames ? l.homeNamesToggleHide : l.homeNamesToggleShow,
      button: true,
      child: GestureDetector(
        onTap: () => widget.onChanged(!widget.showNames),
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: widget.showNames
                  ? AppColors.primary
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(9999),
              border: widget.showNames
                  ? null
                  : Border.all(
                      color: AppColors.outlineVariant.withAlpha(102)),
              boxShadow: widget.showNames ? AppColors.glowSm : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  widget.showNames ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                  color: widget.showNames
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  l.homeNames,
                  style: _controlLabel.copyWith(
                    color: widget.showNames
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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
    super.key,
    required this.product,
    required this.stepNumber,
    required this.isDone,
    required this.showName,
    this.onTap,
  });

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      label: isDone
          ? l.homeProductStepDone(product.name, stepNumber)
          : l.homeProductStepNotDone(product.name, stepNumber),
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
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.glowLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l.journalCtaTitle,
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
                  l.journalCtaSubtitle,
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
                l.journalCtaButton,
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
