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
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
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

const _catEn = <String, String>{
  'cat-cleanser-step1': 'Cleanse 1',
  'cat-cleanser-step2': 'Cleanse 2',
  'cat-retinoid': 'Retinoid',
  'cat-toner': 'Toner / Essence',
  'cat-serum': 'Serum / Active',
  'cat-moisturizer': 'Moisturize',
  'cat-oil': 'Oil',
  'cat-spf': 'Protect',
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

enum _SelectionView { guided, summary }

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
  _SelectionView _view = _SelectionView.guided;
  int _catStep = 0;

  String _slotFilter = 'all';
  String? _openCategoryId;

  void _goToSummary() => setState(() {
        _view = _SelectionView.summary;
        _openCategoryId = null;
      });

  void _backToGuided() => setState(() => _view = _SelectionView.guided);

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
    final match = existing
        .where((s) => s.productId == product.id && s.slot == slot)
        .firstOrNull;
    if (match != null) {
      await repo.upsertSelection(
        match.copyWith(isSelected: isSelected, lastModified: DateTime.now()),
      );
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final morning = morningAsync.valueOrNull ?? [];
          final evening = eveningAsync.valueOrNull ?? [];
          final selMap = _buildSelMap(morning, evening);
          final categories = [...master.categories]
            ..sort((a, b) => a.order.compareTo(b.order));

          return _view == _SelectionView.guided
              ? _buildGuided(context, master, categories, selMap, morning, evening, l)
              : _buildSummary(context, master, categories, selMap, morning, evening, l);
        },
      ),
    );
  }

  Widget _buildGuided(
    BuildContext context,
    MasterContent master,
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

    final catProducts = master.products
        .where((p) => !p.isDeprecated && p.categoryId == cat.id)
        .toList()
      ..sort((a, b) {
        final ao = a.morningConfig?.order ?? a.eveningConfig?.order ?? 9999;
        final bo = b.morningConfig?.order ?? b.eveningConfig?.order ?? 9999;
        return ao.compareTo(bo);
      });

    final catSel = catProducts.where((p) => selMap.containsKey(p.id)).length;
    final ctaLabel = isLast
        ? l.productSelToSummary
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
                    Row(
                      children: [
                        TextButton(
                          key: const Key('skip_to_summary'),
                          onPressed: _goToSummary,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: AppTypography.labelMd.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                            ),
                          ),
                          child: Text(l.productSelSkipToSummary),
                        ),
                        const Spacer(),
                        Text(
                          l.productSelStepCounter(step + 1, total),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

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
                                (_catEn[cat.id] ?? '').toUpperCase(),
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  letterSpacing: 0.12,
                                ),
                              ),
                              Text(
                                cat.name,
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
                        l: l,
                      ),
                    ),
                    childCount: catProducts.length,
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const AddCustomProductSheet(),
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed.withAlpha(153),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          child: const Icon(Icons.arrow_back_rounded,
                              color: AppColors.onSurface, size: 20),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: PrimaryButton(
                        label: ctaLabel,
                        leadingIcon: Icons.arrow_forward_rounded,
                        onTap: () {
                          if (isLast) {
                            _goToSummary();
                          } else {
                            setState(() => _catStep++);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    BuildContext context,
    MasterContent master,
    List<Category> categories,
    Map<String, Set<Slot>> selMap,
    List<ProductSelection> morning,
    List<ProductSelection> evening,
    AppLocalizations l,
  ) {
    final amCount =
        selMap.values.where((s) => s.contains(Slot.morning)).length;
    final pmCount =
        selMap.values.where((s) => s.contains(Slot.evening)).length;
    final totalCount = selMap.length;

    final filterSlot = _slotFilter == 'AM'
        ? Slot.morning
        : _slotFilter == 'PM'
            ? Slot.evening
            : null;

    final visibleCats = categories.where((cat) {
      return master.products.any((p) {
        if (p.isDeprecated || p.categoryId != cat.id) return false;
        if (_slotFilter == 'AM') return p.morningConfig != null;
        if (_slotFilter == 'PM') return p.eveningConfig != null;
        return true;
      });
    }).toList();

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.productSelSummaryTitle,
                      style: AppTypography.headlineMd.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.productSelSummarySubtitle,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _SlotFilter(
                      value: _slotFilter,
                      onChanged: (v) =>
                          setState(() => _slotFilter = v),
                      counts: {
                        'all': totalCount,
                        'AM': amCount,
                        'PM': pmCount
                      },
                      l: l,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final cat = visibleCats[idx];
                    final catProducts = master.products.where((p) {
                      if (p.isDeprecated || p.categoryId != cat.id) return false;
                      if (_slotFilter == 'AM') return p.morningConfig != null;
                      if (_slotFilter == 'PM') return p.eveningConfig != null;
                      return true;
                    }).toList();
                    final catSel = catProducts.where((p) {
                      if (filterSlot != null) {
                        return selMap[p.id]?.contains(filterSlot) ?? false;
                      }
                      return selMap.containsKey(p.id);
                    }).length;

                    return Padding(
                      padding: EdgeInsets.only(
                          bottom: idx < visibleCats.length - 1 ? 10 : 0),
                      child: _CategorySection(
                        category: cat,
                        products: catProducts,
                        selMap: selMap,
                        slotFilter: _slotFilter,
                        isOpen: _openCategoryId == cat.id,
                        catSelCount: catSel,
                        categoryUsage: _getCatUsage(cat.id, l),
                        onToggleOpen: () => setState(() {
                          _openCategoryId =
                              _openCategoryId == cat.id ? null : cat.id;
                        }),
                        onToggleProduct: (p) => _toggleProduct(
                          p, selMap, morning, evening,
                          filterSlot: filterSlot,
                        ),
                        onTimingChange: (p, slot, enabled) =>
                            _setTiming(p, slot, enabled, morning, evening),
                        l: l,
                      ),
                    );
                  },
                  childCount: visibleCats.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
                GestureDetector(
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddCustomProductSheet(),
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed.withAlpha(153),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _backToGuided,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLow,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: AppColors.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: PrimaryButton(
                    label: l.productSelContinueToSchedule,
                    leadingIcon: Icons.event_rounded,
                    onTap: () => _goToSchedule(context),
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
  final AppLocalizations l;

  const _SelectRow({
    super.key,
    required this.product,
    required this.selectedSlots,
    required this.categoryUsage,
    required this.onToggle,
    required this.onTimingChange,
    required this.l,
  });

  @override
  State<_SelectRow> createState() => _SelectRowState();
}

class _SelectRowState extends State<_SelectRow> {
  bool _infoOpen = false;

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
                                textAlign: TextAlign.right,
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
                  margin: const EdgeInsets.only(right: 8),
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
                  if (p.comment != null && p.comment!.isNotEmpty)
                    Text(
                      p.comment!,
                      textAlign: TextAlign.right,
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
                            textAlign: TextAlign.right,
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
                      Text(
                        l.productSelFrequencyLabel,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _frequencyLabel(),
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
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

// ── Slot filter ────────────────────────────────────────────────────────────────

class _SlotFilter extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final Map<String, int>? counts;
  final AppLocalizations l;

  const _SlotFilter({
    required this.value,
    required this.onChanged,
    this.counts,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final opts = [
      (key: 'all', label: l.productSelFilterAll, icon: Icons.apps_rounded, active: AppColors.primary),
      (key: 'AM', label: l.slotMorning, icon: Icons.wb_sunny_rounded, active: AppColors.primaryContainer),
      (key: 'PM', label: l.slotEvening, icon: Icons.dark_mode_rounded, active: AppColors.tertiary),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        children: opts.map((opt) {
          final isActive = value == opt.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 40,
                decoration: BoxDecoration(
                  color: isActive ? opt.active : Colors.transparent,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: isActive ? AppColors.glowSm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(opt.icon,
                        size: 16,
                        color:
                            isActive ? Colors.white : AppColors.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      opt.label,
                      style: AppTypography.labelMd.copyWith(
                        color: isActive
                            ? Colors.white
                            : AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (counts?[opt.key] != null) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withAlpha(64)
                              : AppColors.primaryFixed.withAlpha(153),
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        child: Text(
                          '${counts![opt.key]}',
                          style: AppTypography.labelSm.copyWith(
                            color: isActive ? Colors.white : AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Category section (summary view) ───────────────────────────────────────────

class _CategorySection extends StatelessWidget {
  final Category category;
  final List<MasterProduct> products;
  final Map<String, Set<Slot>> selMap;
  final String slotFilter;
  final bool isOpen;
  final int catSelCount;
  final String categoryUsage;
  final VoidCallback onToggleOpen;
  final Future<void> Function(MasterProduct) onToggleProduct;
  final Future<void> Function(MasterProduct, Slot, bool) onTimingChange;
  final AppLocalizations l;

  const _CategorySection({
    required this.category,
    required this.products,
    required this.selMap,
    required this.slotFilter,
    required this.isOpen,
    required this.catSelCount,
    required this.categoryUsage,
    required this.onToggleOpen,
    required this.onToggleProduct,
    required this.onTimingChange,
    required this.l,
  });

  Set<Slot> _rowSlots(MasterProduct p) => selMap[p.id] ?? {};

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isOpen
              ? AppColors.primaryFixed.withAlpha(153)
              : Colors.transparent,
        ),
        boxShadow: isOpen ? AppColors.glowSm : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggleOpen,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  _CategoryGlyph(
                      categoryId: category.id, size: 40, active: isOpen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          catSelCount == 0
                              ? l.productSelCategoryOptions(products.length)
                              : l.productSelCategorySelected(catSelCount),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (catSelCount > 0) ...[
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      height: 24,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Center(
                        child: Text(
                          '$catSelCount',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.outline, size: 22),
                  ),
                ],
              ),
            ),
          ),

          if (isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
              child: Column(
                children: [
                  for (int i = 0; i < products.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _SelectRow(
                      product: products[i],
                      selectedSlots: _rowSlots(products[i]),
                      categoryUsage: categoryUsage,
                      onToggle: () => onToggleProduct(products[i]),
                      onTimingChange: (slot, enabled) =>
                          onTimingChange(products[i], slot, enabled),
                      l: l,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
