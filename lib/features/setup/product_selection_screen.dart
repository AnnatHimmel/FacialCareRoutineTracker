import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/fixed_slot_chip.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import 'add_custom_product_sheet.dart';

const _uuid = Uuid();

const _catIcon = <String, IconData>{
  'cat-cleanser-step1': Icons.wash,
  'cat-cleanser-step2': Icons.soap,
  'cat-retinoid': Icons.biotech,
  'cat-toner': Icons.water_drop,
  'cat-serum': Icons.science,
  'cat-moisturizer': Icons.spa,
  'cat-oil': Icons.opacity,
  'cat-spf': Icons.wb_sunny,
};


String? _getCatHint(String catId, AppLocalizations l) => switch (catId) {
  'cat-cleanser-step1' => l.catHintCleanser1,
  'cat-cleanser-step2' => l.catHintCleanser2,
  'cat-retinoid' => l.catHintRetinoid,
  'cat-toner' => l.catHintToner,
  'cat-serum' => l.catHintSerum,
  'cat-moisturizer' => l.catHintMoisturizer,
  'cat-oil' => l.catHintOil,
  'cat-spf' => l.catHintSpf,
  _ => null,
};

String _getCatUsage(String catId, AppLocalizations l) => switch (catId) {
  'cat-cleanser-step1' => l.catUsageCleanser1,
  'cat-cleanser-step2' => l.catUsageCleanser2,
  'cat-retinoid' => l.catUsageRetinoid,
  'cat-toner' => l.catUsageToner,
  'cat-serum' => l.catUsageSerum,
  'cat-moisturizer' => l.catUsageMoisturizer,
  'cat-oil' => l.catUsageOil,
  'cat-spf' => l.catUsageSpf,
  _ => '',
};

class ProductSelectionScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool isTabDestination;
  /// When provided the screen renders without its own Scaffold/AppBar and
  /// the summary CTA calls this instead of navigating to the schedule screen.
  final VoidCallback? onDone;

  const ProductSelectionScreen({
    super.key,
    this.fromSetup = false,
    this.isTabDestination = false,
    this.onDone,
  });

  @override
  ConsumerState<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState
    extends ConsumerState<ProductSelectionScreen> {
  int _catStep = 0;

  void _goToSchedule(BuildContext context) {
    if (widget.fromSetup) {
      context.push('/setup/schedule?from=setup');
    } else {
      context.push('/products/schedule');
    }
  }

  Map<String, Set<Slot>> _buildSelMap(
    List<ProductSelection> morning,
    List<ProductSelection> evening,
  ) {
    final map = <String, Set<Slot>>{};
    for (final s in morning.where((s) => s.isSelected)) {
      map.putIfAbsent(s.productId, () => {}).add(Slot.morning);
    }
    for (final s in evening.where((s) => s.isSelected)) {
      map.putIfAbsent(s.productId, () => {}).add(Slot.evening);
    }
    return map;
  }

  Future<void> _toggleProduct(
    MasterProduct product,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morningSelections,
    List<ProductSelection> eveningSelections, {
    Slot? filterSlot,
  }) async {
    final isOn = selMap.containsKey(product.id);
    if (isOn) {
      await _setSlot(product, Slot.morning, false, morningSelections);
      await _setSlot(product, Slot.evening, false, eveningSelections);
    } else {
      if (filterSlot != null && product.configForSlot(filterSlot) != null) {
        final list = filterSlot == Slot.morning ? morningSelections : eveningSelections;
        await _setSlot(product, filterSlot, true, list);
      } else {
        if (product.morningConfig != null) {
          await _setSlot(product, Slot.morning, true, morningSelections);
        }
        if (product.eveningConfig != null) {
          await _setSlot(product, Slot.evening, true, eveningSelections);
        }
      }
    }
  }

  Future<void> _setTiming(
    MasterProduct product,
    Slot slot,
    bool enabled,
    List<ProductSelection> morningSelections,
    List<ProductSelection> eveningSelections,
  ) async {
    final list = slot == Slot.morning ? morningSelections : eveningSelections;
    await _setSlot(product, slot, enabled, list);
  }

  Future<void> _setSlot(
    MasterProduct product,
    Slot slot,
    bool isSelected,
    List<ProductSelection> existing,
  ) async {
    final repo = ref.read(userDataRepositoryProvider);
    final matches = existing
        .where((s) => s.productId == product.id && s.slot == slot)
        .toList();
    if (matches.isNotEmpty) {
      for (final match in matches) {
        await repo.upsertSelection(
          match.copyWith(isSelected: isSelected, lastModified: DateTime.now()),
        );
      }
    } else if (isSelected) {
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

  void _editCustomProduct(BuildContext context, MasterProduct product) {
    final customProds = ref.read(customProductsProvider).valueOrNull ?? [];
    final UserCustomProduct? customProd = customProds
        .cast<UserCustomProduct?>()
        .firstWhere((p) => p?.id == product.id, orElse: () => null);
    if (customProd == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCustomProductSheet(initialProduct: customProd),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));

    final customAsync = ref.watch(customProductsProvider);

    final body = masterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.genericError(e))),
      data: (master) {
        final morning = morningAsync.valueOrNull ?? [];
        final evening = eveningAsync.valueOrNull ?? [];
        final selMap = _buildSelMap(morning, evening);
        final categories = [...master.categories]
          ..sort((a, b) => a.order.compareTo(b.order));
        final customProds = customAsync.valueOrNull ?? [];
        final allProducts = [
          ...master.products,
          ...customProds.map((p) => p.toMasterProduct()),
        ];

        return _buildGuided(context, allProducts, categories, selMap, morning, evening, l);
      },
    );

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: body,
    );
  }

  Widget _buildGuided(
    BuildContext context,
    List<MasterProduct> allProducts,
    List<Category> categories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
    AppLocalizations l,
  ) {
    if (categories.isEmpty) {
      return Center(
        child: Text(l.productSelNoCategories,
            style: AppTypography.bodyMd
                .copyWith(color: AppColors.onSurfaceVariant)),
      );
    }

    final step = _catStep.clamp(0, categories.length - 1);
    final cat = categories[step];
    final total = categories.length;
    final isLast = step == total - 1;

    final catProducts = allProducts
        .where((p) => !p.isDeprecated && p.categoryId == cat.id)
        .toList()
      ..sort((a, b) {
        final ao = a.morningConfig?.order ?? a.eveningConfig?.order ?? 9999;
        final bo = b.morningConfig?.order ?? b.eveningConfig?.order ?? 9999;
        return ao.compareTo(bo);
      });

    final catSel = catProducts.where((p) => selMap.containsKey(p.id)).length;
    final ctaLabel = isLast
        ? l.productSelContinueToSchedule
        : catSel > 0
            ? l.continueAction
            : l.productSelSkipStep;
    final hint = _getCatHint(cat.id, l);

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressBar(step: step, total: total),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        _CategoryGlyph(
                            categoryId: cat.id, size: 48, active: true),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.localizedName(l.localeName).toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  letterSpacing: 0.12,
                                ),
                              ),
                              Text(
                                cat.localizedName(l.localeName),
                                style: AppTypography.headlineMd.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurface,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (hint != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        hint,
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  l.productSelListHint,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),

            if (catProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(
                    l.productSelNoProducts,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: EdgeInsets.only(
                          bottom: i < catProducts.length - 1 ? 10 : 0),
                      child: _SelectRow(
                        key: Key('select_row_${catProducts[i].id}'),
                        product: catProducts[i],
                        selectedSlots: selMap[catProducts[i].id] ?? {},
                        categoryUsage: _getCatUsage(cat.id, l),
                        onToggle: () => _toggleProduct(
                            catProducts[i], selMap, morning, evening),
                        onTimingChange: (slot, enabled) => _setTiming(
                            catProducts[i], slot, enabled, morning, evening),
                        onEdit: () => _editCustomProduct(context, catProducts[i]),
                        l: l,
                      ),
                    ),
                    childCount: catProducts.length,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: _AddCustomProductCTA(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddCustomProductSheet(),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),

        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: AppColors.surface.withAlpha(242),
              boxShadow: AppColors.navGlow,
              border: const Border(
                  top: BorderSide(color: AppColors.primaryFixed, width: 0.5)),
            ),
            child: Row(
              children: [
                if (step > 0) ...[
                  GestureDetector(
                    onTap: () => setState(() => _catStep--),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLow,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: AppColors.onSurface, size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: PrimaryButton(
                    label: ctaLabel,
                    trailingIcon: Icons.arrow_forward,
                    onTap: () {
                      if (isLast) {
                        if (widget.onDone != null) {
                          widget.onDone!();
                        } else {
                          _goToSchedule(context);
                        }
                      } else {
                        setState(() => _catStep++);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Progress bar ───────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int step;
  final int total;

  const _ProgressBar({required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 6,
              decoration: BoxDecoration(
                color: i <= step
                    ? AppColors.primary
                    : AppColors.primaryFixed.withAlpha(102),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Category glyph ─────────────────────────────────────────────────────────────

class _CategoryGlyph extends StatelessWidget {
  final String categoryId;
  final double size;
  final bool active;

  const _CategoryGlyph({
    required this.categoryId,
    this.size = 40,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _catIcon[categoryId] ?? Icons.category;
    final iconSize = size >= 48 ? 26.0 : size >= 40 ? 22.0 : 18.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.primaryFixed.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon,
          size: iconSize, color: active ? Colors.white : AppColors.primary),
    );
  }
}

// ── SelectRow ──────────────────────────────────────────────────────────────────

class _SelectRow extends StatefulWidget {
  final MasterProduct product;
  final Set<Slot> selectedSlots;
  final String categoryUsage;
  final VoidCallback onToggle;
  final void Function(Slot slot, bool enabled) onTimingChange;
  final VoidCallback? onEdit;
  final AppLocalizations l;

  const _SelectRow({
    super.key,
    required this.product,
    required this.selectedSlots,
    required this.categoryUsage,
    required this.onToggle,
    required this.onTimingChange,
    this.onEdit,
    required this.l,
  });

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  bool _infoOpen = false;

  bool get _isCustom => widget.product.addedInVersion == 'custom';

  bool get _isFlexible =>
      widget.product.morningConfig != null &&
      widget.product.eveningConfig != null;

  bool get _isOn => widget.selectedSlots.isNotEmpty;
  bool get _showTiming => _isFlexible && _isOn;
  bool get _isExpanded => _showTiming || _infoOpen;

  String _frequencyLabel() {
    final config =
        widget.product.morningConfig ?? widget.product.eveningConfig;
    if (config == null) return widget.l.onboardingFrequencyDaily;
    final f = config.frequencyRule;
    return f is WeeklyMaxRule
        ? widget.l.onboardingFrequencyWeekly(f.maxPerWeek)
        : widget.l.onboardingFrequencyDaily;
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.l;
    final p = widget.product;
    final isOn = _isOn;
    final isExpanded = _isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.primaryFixed.withAlpha(77)
            : AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(isExpanded ? 26 : 9999),
        border: Border.all(
          color: isOn
              ? AppColors.primary.withAlpha(77)
              : Colors.transparent,
        ),
        boxShadow: isOn ? null : AppColors.glowSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onToggle,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
                    child: Row(
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProductThumb(imageAsset: p.imageAsset, size: 50),
                            if (isOn)
                              Positioned(
                                bottom: -2,
                                left: -2,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 12),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.start,
                                style: AppTypography.bodyMd.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              if (!_isFlexible) ...[
                                const SizedBox(height: 4),
                                FixedSlotChip(product: p),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _infoOpen = !_infoOpen),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    turns: _infoOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (_infoOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Divider(height: 1, color: AppColors.outlineVariant),
                  const SizedBox(height: 10),
                  if (p.localizedComment(l.localeName).isNotEmpty)
                    Text(
                      p.localizedComment(l.localeName),
                      textAlign: TextAlign.start,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 12.5,
                        height: 1.5,
                      ),
                    ),
                  if (widget.categoryUsage.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.categoryUsage,
                            textAlign: TextAlign.start,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.event_repeat_rounded,
                          size: 14, color: AppColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          l.productSelFrequencyLabel + _frequencyLabel(),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_isCustom && widget.onEdit != null) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1, color: AppColors.outlineVariant),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            l.customProductEditButton,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          if (_showTiming)
            _TimingControl(
              amSelected: widget.selectedSlots.contains(Slot.morning),
              pmSelected: widget.selectedSlots.contains(Slot.evening),
              onToggleAm: () => widget.onTimingChange(
                  Slot.morning,
                  !widget.selectedSlots.contains(Slot.morning)),
              onTogglePm: () => widget.onTimingChange(
                  Slot.evening,
                  !widget.selectedSlots.contains(Slot.evening)),
              l: l,
            ),
        ],
      ),
    );
  }
}

// ── Timing control ─────────────────────────────────────────────────────────────

class _TimingControl extends StatelessWidget {
  final bool amSelected;
  final bool pmSelected;
  final VoidCallback onToggleAm;
  final VoidCallback onTogglePm;
  final AppLocalizations l;

  const _TimingControl({
    required this.amSelected,
    required this.pmSelected,
    required this.onToggleAm,
    required this.onTogglePm,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 13, color: AppColors.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                l.productSelTimingLabel,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _TimingPill(
                    label: l.slotMorning,
                    icon: Icons.wb_sunny_rounded,
                    isSelected: amSelected,
                    activeColor: AppColors.primaryContainer,
                    onTap: onToggleAm,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _TimingPill(
                    label: l.slotEvening,
                    icon: Icons.dark_mode_rounded,
                    isSelected: pmSelected,
                    activeColor: AppColors.tertiary,
                    onTap: onTogglePm,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimingPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TimingPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : AppColors.outlineVariant.withAlpha(128),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? Icons.check_rounded : icon,
              size: 14,
              color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTypography.labelSm.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add Custom Product CTA card ───────────────────────────────────────────────

class _AddCustomProductCTA extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCustomProductCTA({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(128),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: AppColors.primaryFixed,
            width: 3.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.addCustomProductCtaTitle,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.addCustomProductCtaSub,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

