import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/muted_conflict.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../domain/entities/category.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/soft_warning_banner.dart';
import 'add_custom_product_sheet.dart';

const _uuid = Uuid();

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool isTabDestination;

  const ProductSelectionScreen({
    super.key,
    this.fromSetup = false,
    this.isTabDestination = false,
  });

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  // ── 3-step wizard state: 1=morning, 2=evening ─────────────────────────────
  int _currentStep = 1;

  Slot get _activeSlot =>
      _currentStep == 1 ? Slot.morning : Slot.evening;

  // ── filters ───────────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _activeCategoryId;
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── step navigation ───────────────────────────────────────────────────────

  void _goToEvening() {
    setState(() {
      _currentStep = 2;
      _searchController.clear();
      _activeCategoryId = null;
      _onlyMine = false;
    });
    // Scroll to top if possible — handled by key reset via setState
  }

  void _backToMorning() {
    setState(() {
      _currentStep = 1;
      _searchController.clear();
      _activeCategoryId = null;
      _onlyMine = false;
    });
  }

  void _goToSchedule(BuildContext context) {
    if (widget.fromSetup) {
      context.push('/setup/schedule?from=setup');
    } else {
      context.push('/products/schedule');
    }
  }

  // ── data mutations ────────────────────────────────────────────────────────

  Future<void> _toggleSelection(
    MasterProduct product,
    Slot slot,
    List<ProductSelection> currentSelections,
  ) async {
    final repo = ref.read(userDataRepositoryProvider);
    final existing = currentSelections
        .where((s) => s.productId == product.id && s.slot == slot)
        .firstOrNull;

    if (existing != null) {
      await repo.upsertSelection(
        existing.copyWith(
          isSelected: !existing.isSelected,
          lastModified: DateTime.now(),
        ),
      );
    } else {
      await repo.upsertSelection(
        ProductSelection(
          id: _uuid.v4(),
          productId: product.id,
          slot: slot,
          isSelected: true,
          lastModified: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _muteConflict(String ruleId) async {
    await ref.read(userDataRepositoryProvider).muteConflict(
          MutedConflict(
              id: _uuid.v4(), ruleId: ruleId, mutedAt: DateTime.now()),
        );
  }

  Future<void> _unmuteConflict(String ruleId) async {
    await ref.read(userDataRepositoryProvider).unmuteConflict(ruleId);
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelectionsAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningSelectionsAsync = ref.watch(selectionsProvider(Slot.evening));
    final mutedAsync = ref.watch(mutedConflictsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      // The shell scaffold provides the bottom nav when isTabDestination.
      // During setup / onboarding there is no bottom nav (matches JSX).
      bottomNavigationBar: null,
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final morningSelections = morningSelectionsAsync.valueOrNull ?? [];
          final eveningSelections = eveningSelectionsAsync.valueOrNull ?? [];
          final muted = mutedAsync.valueOrNull ?? [];
          final mutedIds = muted.map((m) => m.ruleId).toSet();
          final checker = ref.read(incompatibilityCheckerProvider);

          final currentSelections = _activeSlot == Slot.morning
              ? morningSelections
              : eveningSelections;

          final slotSelectedCount = (_activeSlot == Slot.morning
                  ? morningSelections
                  : eveningSelections)
              .where((s) => s.isSelected)
              .length;

          return _buildBody(
            context: context,
            master: master,
            morningSelections: morningSelections,
            eveningSelections: eveningSelections,
            currentSelections: currentSelections,
            mutedIds: mutedIds,
            checker: checker,
            slotSelectedCount: slotSelectedCount,
          );
        },
      ),
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required MasterContent master,
    required List<ProductSelection> morningSelections,
    required List<ProductSelection> eveningSelections,
    required List<ProductSelection> currentSelections,
    required Set<String> mutedIds,
    required IncompatibilityChecker checker,
    required int slotSelectedCount,
  }) {
    final slotProducts = master.products
        .where(
          (p) => !p.isDeprecated && p.configForSlot(_activeSlot) != null,
        )
        .toList();

    // "Only mine" filter
    final selectedIds = currentSelections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    final afterMine = _onlyMine
        ? slotProducts.where((p) => selectedIds.contains(p.id)).toList()
        : slotProducts;

    final afterSearch = _query.isEmpty
        ? afterMine
        : afterMine
            .where((p) =>
                p.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    final categoryOrderById = {
      for (final cat in master.categories) cat.id: cat.order,
    };

    final filtered = List<MasterProduct>.of(
      _activeCategoryId == null
          ? afterSearch
          : afterSearch.where((p) => p.categoryId == _activeCategoryId),
    )..sort((a, b) {
        final catA = categoryOrderById[a.categoryId] ?? 9999;
        final catB = categoryOrderById[b.categoryId] ?? 9999;
        if (catA != catB) return catA.compareTo(catB);
        final orderA = a.configForSlot(_activeSlot)?.order ?? 9999;
        final orderB = b.configForSlot(_activeSlot)?.order ?? 9999;
        return orderA.compareTo(orderB);
      });

    // Conflict detection for current slot
    final selectedInSlot =
        slotProducts.where((p) => selectedIds.contains(p.id)).toList();

    final otherSlot =
        _activeSlot == Slot.morning ? Slot.evening : Slot.morning;
    final otherSelections =
        _activeSlot == Slot.morning ? eveningSelections : morningSelections;
    final otherSelectedIds = otherSelections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();
    final selectedInOtherSlot = master.products
        .where((p) =>
            !p.isDeprecated &&
            p.configForSlot(otherSlot) != null &&
            otherSelectedIds.contains(p.id))
        .toList();

    final conflicts = checker.getConflictsForSelection(
      activeSlot: _activeSlot,
      slotProducts: selectedInSlot,
      otherSlotProducts: selectedInOtherSlot,
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedIds,
    );

    // Categories for the current slot
    final slotCategoryIds = slotProducts.map((p) => p.categoryId).toSet();
    final slotCategories = master.categories
        .where((c) => slotCategoryIds.contains(c.id))
        .toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 3-step indicator (always shown) ─────────────────────
                    _StepIndicator(
                      currentStep: _currentStep,
                      steps: const ['בוקר', 'ערב', 'תזמון'],
                    ),
                    const SizedBox(height: 16),

                    // ── Slot progress toggle ─────────────────────────────────
                    _SlotProgressToggle(
                      currentStep: _currentStep,
                      onBackToMorning: _currentStep == 2 ? _backToMorning : null,
                    ),
                    const SizedBox(height: 8),

                    // ── Subtitle ─────────────────────────────────────────────
                    Text(
                      'שלב $_currentStep — בחירת מוצרי ${_activeSlot == Slot.morning ? 'הבוקר' : 'הערב'} שלך • $slotSelectedCount נבחרו',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Search field + add custom product button ────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SearchField(controller: _searchController),
                        ),
                        const SizedBox(width: 8),
                        _AddProductButton(
                          onTap: () => showModalBottomSheet<void>(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const AddCustomProductSheet(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Category chip rail ───────────────────────────────────
                    _CategoryChipRail(
                      categories: slotCategories,
                      activeCategoryId: _activeCategoryId,
                      onSelect: (id) =>
                          setState(() => _activeCategoryId = id),
                    ),
                    const SizedBox(height: 12),

                    // ── All / Mine filter row ────────────────────────────────
                    _AllMineFilterRow(
                      onlyMine: _onlyMine,
                      totalSelected: selectedInSlot.length,
                      onToggle: (v) => setState(() => _onlyMine = v),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),

            // ── Conflict banners ──────────────────────────────────────────────
            for (final conflict in conflicts.where((c) => !c.isMuted))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SoftWarningBanner(
                    message:
                        '${conflict.productA.name} ו${conflict.productB.name} לא מומלץ להשתמש יחד',
                    muteLabel: 'השתק',
                    onMute: () => _muteConflict(conflict.ruleId),
                  ),
                ),
              ),
            for (final conflict in conflicts.where((c) => c.isMuted))
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: SoftWarningBanner(
                    message:
                        '${conflict.productA.name} ו${conflict.productB.name} — אזהרה מושתקת',
                    customAction: TextButton(
                      onPressed: () => _unmuteConflict(conflict.ruleId),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.onSurfaceVariant,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        textStyle: AppTypography.labelSm,
                      ),
                      child: const Text('בטל השתקה'),
                    ),
                  ),
                ),
              ),

            // ── Empty state ───────────────────────────────────────────────────
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      _onlyMine
                          ? 'עדיין לא בחרת מוצרים בשגרה זו.'
                          : 'לא נמצאו מוצרים תואמים.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Product list ──────────────────────────────────────────────────
            if (filtered.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Column(
                    children: [
                      for (int i = 0; i < filtered.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _buildProductRow(
                          product: filtered[i],
                          selectedIds: selectedIds,
                          conflicts: conflicts,
                          currentSelections: currentSelections,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // Bottom padding clears the sticky CTA
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),

        // ── Sticky bottom CTA ─────────────────────────────────────────────────
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _BottomCta(
            currentStep: _currentStep,
            onStep1: _goToEvening,
            onStep2: () => _goToSchedule(context),
          ),
        ),
      ],
    );
  }

  Widget _buildProductRow({
    required MasterProduct product,
    required Set<String> selectedIds,
    required List<ConflictInfo> conflicts,
    required List<ProductSelection> currentSelections,
  }) {
    final isToggled = selectedIds.contains(product.id);
    final hasConflict = conflicts.any(
      (c) =>
          !c.isMuted &&
          (c.productA.id == product.id || c.productB.id == product.id),
    );
    return RoutineItemRow(
      product: product,
      isToggled: isToggled,
      onToggle: () => _toggleSelection(product, _activeSlot, currentSelections),
      isOwnershipContext: true,
      hasConflict: hasConflict,
    );
  }
}

// ── 3-step indicator ──────────────────────────────────────────────────────────

enum _StepState { active, done, inactive }

class _StepIndicator extends StatelessWidget {
  final int currentStep; // 1-indexed; max 2 for this screen (3 is on schedule screen)
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      textDirection: TextDirection.rtl,
      children: [
        for (int i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Container(
              width: 24,
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: i < currentStep
                  ? AppColors.secondary
                  : AppColors.outlineVariant.withAlpha(128),
            ),
          _StepChip(
            number: i + 1,
            label: steps[i],
            state: i + 1 == currentStep
                ? _StepState.active
                : i + 1 < currentStep
                    ? _StepState.done
                    : _StepState.inactive,
          ),
        ],
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final int number;
  final String label;
  final _StepState state;

  const _StepChip({
    required this.number,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleBg = switch (state) {
      _StepState.active => AppColors.primary,
      _StepState.done => AppColors.secondary,
      _StepState.inactive => AppColors.surfaceHigh,
    };
    final Color circleText = switch (state) {
      _StepState.active || _StepState.done => AppColors.onPrimary,
      _StepState.inactive => AppColors.onSurfaceVariant,
    };
    final Color labelColor = switch (state) {
      _StepState.active => AppColors.primary,
      _StepState.done => AppColors.onSurface,
      _StepState.inactive => AppColors.onSurfaceVariant.withAlpha(178),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
          child: state == _StepState.done
              ? Icon(Icons.check, size: 14, color: circleText)
              : Center(
                  child: Text(
                    '$number',
                    style: AppTypography.labelSm.copyWith(
                      color: circleText,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ── Slot progress toggle (forward-only progress indicator) ────────────────────

class _SlotProgressToggle extends StatelessWidget {
  final int currentStep; // 1 or 2
  final VoidCallback? onBackToMorning; // null when already on morning

  const _SlotProgressToggle({
    required this.currentStep,
    required this.onBackToMorning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: AppColors.soft,
      ),
      child: Row(
        children: [
          // Morning tab — clickable to go back when on evening
          Expanded(
            child: GestureDetector(
              onTap: onBackToMorning,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: currentStep == 1
                      ? AppColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow:
                      currentStep == 1 ? AppColors.glowSm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'בוקר',
                      style: AppTypography.labelMd.copyWith(
                        color: currentStep >= 1
                            ? (currentStep == 1
                                ? AppColors.onPrimary
                                : AppColors.onSurface)
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (currentStep == 1)
                      const Icon(Icons.wb_sunny_rounded,
                          size: 18, color: AppColors.onPrimary)
                    else
                      const Icon(Icons.check_rounded,
                          size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ),
          ),

          // Evening tab — visual indicator only (not interactive from step 1)
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: currentStep == 2
                    ? AppColors.tertiary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(9999),
                boxShadow: currentStep == 2 ? AppColors.glowSm : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ערב',
                    style: AppTypography.labelMd.copyWith(
                      color: currentStep == 2
                          ? AppColors.onPrimary
                          : AppColors.onSurfaceVariant
                              .withValues(alpha: 0.6),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.dark_mode_rounded,
                    size: 18,
                    color: currentStep == 2
                        ? AppColors.onPrimary
                        : AppColors.onSurfaceVariant
                            .withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;

  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(9999),
        boxShadow: AppColors.soft,
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.search_rounded, color: AppColors.outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
              decoration: InputDecoration(
                hintText: 'חיפוש במוצרי המערכת...',
                hintStyle: AppTypography.bodyMd.copyWith(
                  color: AppColors.outline.withAlpha(153),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// ── Category chip rail ────────────────────────────────────────────────────────

class _CategoryChipRail extends StatelessWidget {
  final List<Category> categories;
  final String? activeCategoryId;
  final ValueChanged<String?> onSelect;

  const _CategoryChipRail({
    required this.categories,
    required this.activeCategoryId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          const SizedBox(width: 4),
          _CategoryChip(
            label: 'הכל',
            active: activeCategoryId == null,
            onTap: () => onSelect(null),
          ),
          for (final cat in categories) ...[
            const SizedBox(width: 8),
            _CategoryChip(
              label: cat.name,
              active: activeCategoryId == cat.id,
              onTap: () =>
                  onSelect(activeCategoryId == cat.id ? null : cat.id),
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CategoryChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.primaryFixed,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: active ? AppColors.glowSm : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.labelMd.copyWith(
            color:
                active ? AppColors.onPrimary : AppColors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── All / Mine segmented filter row ──────────────────────────────────────────

class _AllMineFilterRow extends StatelessWidget {
  final bool onlyMine;
  final int totalSelected;
  final ValueChanged<bool> onToggle;

  const _AllMineFilterRow({
    required this.onlyMine,
    required this.totalSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Segmented control (RTL: first item is visually rightmost)
        Container(
          height: 40,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLow,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterTab(
                label: 'כל המוצרים',
                icon: Icons.apps_rounded,
                active: !onlyMine,
                onTap: () => onToggle(false),
              ),
              const SizedBox(width: 4),
              _FilterTab(
                label: 'שלי',
                icon: Icons.check_circle_rounded,
                active: onlyMine,
                onTap: () => onToggle(true),
                badge: totalSelected > 0 ? '$totalSelected' : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final String? badge;

  const _FilterTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: active ? AppColors.glowSm : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color:
                    active ? AppColors.primary : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primaryFixed,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  badge!,
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 10,
                    color: active
                        ? AppColors.onPrimary
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Sticky bottom CTA ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final int currentStep;
  final VoidCallback onStep1;
  final VoidCallback onStep2;

  const _BottomCta({
    required this.currentStep,
    required this.onStep1,
    required this.onStep2,
  });

  @override
  Widget build(BuildContext context) {
    final isStep1 = currentStep == 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(230),
        boxShadow: AppColors.navGlow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary CTA
          Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGlowGradient,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: AppColors.glowSm,
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: isStep1 ? onStep1 : onStep2,
                borderRadius: BorderRadius.circular(9999),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isStep1) ...[
                        const Icon(Icons.event_rounded,
                            color: AppColors.onPrimary, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isStep1 ? 'המשך לבחירת הערב' : 'המשך לתזמון',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (isStep1) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.dark_mode_rounded,
                            color: AppColors.onPrimary, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add product button ────────────────────────────────────────────────────────

class _AddProductButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddProductButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.primaryFixed,
          shape: BoxShape.circle,
          boxShadow: AppColors.glowSm,
        ),
        child: const Icon(
          Icons.add_rounded,
          color: AppColors.primary,
          size: 24,
        ),
      ),
    );
  }
}
