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
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/soft_warning_banner.dart';

const _uuid = Uuid();

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSetup;

  const ProductSelectionScreen({super.key, this.fromSetup = false});

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  // ── active slot (AM/PM toggle) ────────────────────────────────────────────
  Slot _activeSlot = Slot.morning;

  // ── search query ──────────────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // ── active category filter (null = all) ───────────────────────────────────
  String? _activeCategoryId;

  // ── slot-section expand state (kept for parity with old behavior) ─────────
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

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
    final repo = ref.read(userDataRepositoryProvider);
    await repo.muteConflict(
      MutedConflict(id: _uuid.v4(), ruleId: ruleId, mutedAt: DateTime.now()),
    );
  }

  Future<void> _unmuteConflict(String ruleId) async {
    final repo = ref.read(userDataRepositoryProvider);
    await repo.unmuteConflict(ruleId);
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
      appBar: GlowAppBar(
        showBack: !widget.fromSetup,
        onBack: () => context.pop(),
        action: !widget.fromSetup
            ? TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'שמור',
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
              )
            : null,
      ),
      bottomNavigationBar: _buildSetupNav(context),
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

          final allSelections = [...morningSelections, ...eveningSelections];
          final totalSelected = allSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet()
              .length;

          return _buildBody(
            context: context,
            master: master,
            morningSelections: morningSelections,
            eveningSelections: eveningSelections,
            currentSelections: currentSelections,
            mutedIds: mutedIds,
            checker: checker,
            totalSelected: totalSelected,
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
    required int totalSelected,
  }) {
    // Products for the active slot, not deprecated
    final slotProducts = master.products
        .where(
          (p) =>
              !p.isDeprecated && p.configForSlot(_activeSlot) != null,
        )
        .toList();

    // Apply search filter
    final afterSearch = _query.isEmpty
        ? slotProducts
        : slotProducts
            .where(
              (p) =>
                  p.name.toLowerCase().contains(_query.toLowerCase()),
            )
            .toList();

    // Apply category filter
    final filtered = _activeCategoryId == null
        ? afterSearch
        : afterSearch
            .where((p) => p.categoryId == _activeCategoryId)
            .toList();

    // Conflict detection for current slot
    final selectedIds = currentSelections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    final selectedInSlot =
        slotProducts.where((p) => selectedIds.contains(p.id)).toList();

    final otherSlot = _activeSlot == Slot.morning ? Slot.evening : Slot.morning;
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

    // Categories that appear in the current slot
    final slotCategoryIds = slotProducts.map((p) => p.categoryId).toSet();
    final slotCategories = master.categories
        .where((c) => slotCategoryIds.contains(c.id))
        .toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // ── controls ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Step wizard indicator (onboarding flow only)
                    if (widget.fromSetup) ...[
                      const _StepIndicator(
                        currentStep: 1,
                        steps: ['בחירה', 'תזמון'],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // AM / PM toggle
                    _SlotToggle(
                      activeSlot: _activeSlot,
                      onChanged: (slot) =>
                          setState(() => _activeSlot = slot),
                    ),
                    const SizedBox(height: 8),
                    // subtitle
                    Text(
                      'בניית שגרת ${_activeSlot == Slot.morning ? 'הבוקר' : 'הערב'} שלך • $totalSelected מוצרים נבחרו',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search field
                    _SearchField(controller: _searchController),
                    const SizedBox(height: 12),
                    // Category chip rail
                    _CategoryChipRail(
                      categories: slotCategories,
                      activeCategoryId: _activeCategoryId,
                      onSelect: (id) =>
                          setState(() => _activeCategoryId = id),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── conflict banners ──────────────────────────────────────────────
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

            // ── empty state ───────────────────────────────────────────────────
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Text(
                      'לא נמצאו מוצרים תואמים.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),

            // ── flat product list ─────────────────────────────────────────────
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

            // bottom padding so last card clears the sticky CTA
            SliverToBoxAdapter(
              child: SizedBox(
                height: widget.fromSetup ? 96 : 32,
              ),
            ),
          ],
        ),

        // ── sticky bottom CTA (fromSetup only) ────────────────────────────────
        if (widget.fromSetup)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _BottomCta(
              onPressed: () => context.go('/setup/schedule?from=setup'),
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
      onToggle: () => _toggleSelection(
        product,
        _activeSlot,
        currentSelections,
      ),
      isOwnershipContext: true,
      hasConflict: hasConflict,
      onConflictTap: hasConflict ? () => _expandAllSections() : null,
    );
  }

  void _expandAllSections() {
    setState(() {
      _sectionExpanded[Slot.morning] = true;
      _sectionExpanded[Slot.evening] = true;
    });
  }

  Widget _buildSetupNav(BuildContext context) => GlassBottomNav(
        currentIndex: -1,
        onDestinationSelected: (i) {
          const routes = ['/today', '/calendar', '/journal', '/settings'];
          if (i < routes.length) context.go(routes[i]);
        },
        items: const [
          GlassNavItem(
            icon: Icons.wb_sunny_outlined,
            selectedIcon: Icons.wb_sunny_rounded,
            label: 'היום',
          ),
          GlassNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: 'לוח שנה',
          ),
          GlassNavItem(
            icon: Icons.auto_stories_outlined,
            selectedIcon: Icons.auto_stories_rounded,
            label: 'יומן',
          ),
          GlassNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'הגדרות',
          ),
        ],
      );
}

// ── Step wizard indicator ──────────────────────────────────────────────────────

enum _StepState { active, done, inactive }

class _StepIndicator extends StatelessWidget {
  final int currentStep; // 1-indexed
  final List<String> steps;

  const _StepIndicator({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      // RTL: first child appears visually on the right
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

// ── AM / PM segmented pill toggle ─────────────────────────────────────────────

class _SlotToggle extends StatelessWidget {
  final Slot activeSlot;
  final ValueChanged<Slot> onChanged;

  const _SlotToggle({required this.activeSlot, required this.onChanged});

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
          _ToggleTab(
            label: 'בוקר',
            icon: Icons.wb_sunny_rounded,
            active: activeSlot == Slot.morning,
            activeColor: AppColors.primaryContainer,
            onTap: () => onChanged(Slot.morning),
          ),
          _ToggleTab(
            label: 'ערב',
            icon: Icons.dark_mode_rounded,
            active: activeSlot == Slot.evening,
            activeColor: AppColors.tertiary,
            onTap: () => onChanged(Slot.evening),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: active ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.labelMd.copyWith(
                  color: active
                      ? AppColors.onPrimary
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                icon,
                size: 18,
                color: active
                    ? AppColors.onPrimary
                    : AppColors.onSurfaceVariant,
              ),
            ],
          ),
        ),
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
          const Icon(
            Icons.search_rounded,
            color: AppColors.outline,
            size: 20,
          ),
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
        reverse: true, // RTL — chips read right-to-left
        children: [
          const SizedBox(width: 4),
          // "הכל" chip
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
              onTap: () => onSelect(
                activeCategoryId == cat.id ? null : cat.id,
              ),
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

  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            color: active ? AppColors.onPrimary : AppColors.onPrimaryContainer,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Bottom CTA ────────────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final VoidCallback onPressed;

  const _BottomCta({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withAlpha(230),
        boxShadow: AppColors.navGlow,
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGlowGradient,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: AppColors.glowSm,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(9999),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'המשך לתזמון',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: AppColors.onPrimary, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
