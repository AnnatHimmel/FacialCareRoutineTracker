import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/l10n/hebrew_date_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/order_override.dart';
import '../../domain/services/product_sorter.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';

const _uuid = Uuid();

class OrderCustomizationScreen extends ConsumerStatefulWidget {
  final bool fromSetup;

  // Onboarding single-slot mode. When set, renders only the given slot with a
  // custom header and a slot-specific CTA. The caller manages navigation.
  final Slot? onboardingSlot;
  final VoidCallback? onContinue;
  final VoidCallback? onBack;

  const OrderCustomizationScreen({
    super.key,
    this.fromSetup = false,
    this.onboardingSlot,
    this.onContinue,
    this.onBack,
  });

  @override
  ConsumerState<OrderCustomizationScreen> createState() =>
      _OrderCustomizationScreenState();
}

class _OrderCustomizationScreenState
    extends ConsumerState<OrderCustomizationScreen> {
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

  bool get _isOnboarding => widget.onboardingSlot != null;

  // Advanced options panel is collapsed by default in onboarding mode
  bool _advancedExpanded = false;

  final Map<Slot, List<String>?> _localOrder = {};

  Future<void> _reorder(
    Slot slot,
    List<String> currentIds,
    int oldIndex,
    int newIndex,
    OrderOverride? existing,
  ) async {
    final ids = List<String>.from(currentIds);
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);

    setState(() => _localOrder[slot] = ids);

    final repo = ref.read(userDataRepositoryProvider);
    await repo.upsertOrderOverride(
      OrderOverride(
        id: existing?.id ?? _uuid.v4(),
        slot: slot,
        orderedProductIds: ids,
        lastModified: DateTime.now(),
      ),
    );
  }

  Future<void> _resetOrder(Slot slot) async {
    setState(() => _localOrder[slot] = null);
    final repo = ref.read(userDataRepositoryProvider);
    await repo.deleteOrderOverride(slot);
  }

  Future<void> _save(BuildContext context) async {
    if (_isOnboarding) {
      // Orchestrator manages navigation and completion; just call the callback.
      widget.onContinue?.call();
    } else if (widget.fromSetup) {
      await ref
          .read(settingsRepositoryProvider)
          .setOnboardingCompleted(true);
      if (context.mounted) context.go('/today');
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.morning));
    final eveningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.evening));
    final morningOverrideAsync =
        ref.watch(_orderOverrideProvider(Slot.morning));
    final eveningOverrideAsync =
        ref.watch(_orderOverrideProvider(Slot.evening));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _isOnboarding ? null : GlowAppBar(showBack: !widget.fromSetup),
      bottomNavigationBar:
          _isOnboarding ? null : AppBottomNav.setup(context),
      body: masterAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final morningSelections =
              morningSelectionsAsync.valueOrNull ?? [];
          final eveningSelections =
              eveningSelectionsAsync.valueOrNull ?? [];
          final morningOverride = morningOverrideAsync.valueOrNull;
          final eveningOverride = eveningOverrideAsync.valueOrNull;

          final morningSelectedIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningSelectedIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          final morningProducts = _sortedProducts(
            master,
            morningSelectedIds,
            Slot.morning,
            morningOverride,
            _localOrder[Slot.morning],
          );
          final eveningProducts = _sortedProducts(
            master,
            eveningSelectedIds,
            Slot.evening,
            eveningOverride,
            _localOrder[Slot.evening],
          );

          if (_isOnboarding) {
            // Onboarding mode: single slot, custom header, advanced options panel
            final slot = widget.onboardingSlot!;
            final products =
                slot == Slot.morning ? morningProducts : eveningProducts;
            final override =
                slot == Slot.morning ? morningOverride : eveningOverride;
            return SafeArea(
              child: Column(
                children: [
                  _OnboardingOrderHeader(
                    slot: slot,
                    onBack: widget.onBack!,
                    l: l,
                  ),
                  Expanded(
                    child: ListView(
                      padding:
                          const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      children: [
                        // Static "general order" label
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.format_list_bulleted_rounded,
                                size: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l.orderViewGeneral,
                                style: AppTypography.labelMd.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Reorderable list for this slot
                        GlowCard(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 0),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: products.length,
                            onReorderItem: (oldIndex, newIndex) {
                              final currentIds =
                                  products.map((p) => p.id).toList();
                              _reorder(
                                  slot, currentIds, oldIndex, newIndex, override);
                            },
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return RoutineItemRow(
                                key: ValueKey(product.id),
                                product: product,
                                isToggled: false,
                                onToggle: () {},
                                isDraggable: true,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Advanced options collapsible (collapsed by default)
                        _AdvancedOptionsPanel(
                          slot: slot,
                          expanded: _advancedExpanded,
                          hasCustomOrder: _localOrder[slot] != null ||
                              override != null,
                          onToggle: () => setState(
                              () => _advancedExpanded = !_advancedExpanded),
                          onReset: () => _resetOrder(slot),
                          products: products,
                          globalOverride: override,
                          l: l,
                        ),
                      ],
                    ),
                  ),
                  // Bottom CTA
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      boxShadow: AppColors.navGlow,
                    ),
                    padding:
                        const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: PrimaryButton(
                      label: slot == Slot.morning
                          ? l.orderCtaMorning
                          : l.orderCtaFinish,
                      onTap: () => _save(context),
                      trailingIcon: Icons.arrow_forward,
                      height: 56,
                    ),
                  ),
                ],
              ),
            );
          }

          // Standard (non-onboarding) mode
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  Text(
                    l.orderInstruction,
                    textAlign: TextAlign.start,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  if (morningProducts.isNotEmpty)
                    _buildSlotSection(
                      slot: Slot.morning,
                      products: morningProducts,
                      override: morningOverride,
                      l: l,
                    ),

                  if (morningProducts.isNotEmpty && eveningProducts.isNotEmpty)
                    const SizedBox(height: 16),

                  if (eveningProducts.isNotEmpty)
                    _buildSlotSection(
                      slot: Slot.evening,
                      products: eveningProducts,
                      override: eveningOverride,
                      l: l,
                    ),

                  if (morningProducts.isEmpty && eveningProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          l.orderNoProducts,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: AppColors.navGlow,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: PrimaryButton(
                    label: widget.fromSetup ? l.orderSaveFinish : l.orderSaveNew,
                    onTap: () => _save(context),
                    height: 56,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MasterProduct> _sortedProducts(
    MasterContent master,
    Set<String> selectedIds,
    Slot slot,
    OrderOverride? override,
    List<String>? localOrder,
  ) {
    final products = master.products
        .where((p) => !p.isDeprecated && selectedIds.contains(p.id) && p.configForSlot(slot) != null)
        .toList();

    final adminCmp = ProductSorter.adminComparator(
      categories: master.categories,
      subcategories: master.subcategories,
      slot: slot,
    );

    final orderIds = localOrder ?? override?.orderedProductIds;
    if (orderIds != null) {
      products.sort((a, b) {
        final ai = orderIds.indexOf(a.id);
        final bi = orderIds.indexOf(b.id);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return adminCmp(a, b);
      });
    } else {
      products.sort(adminCmp);
    }
    return products;
  }

  Widget _buildSlotSection({
    required Slot slot,
    required List<MasterProduct> products,
    required OrderOverride? override,
    required AppLocalizations l,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();
    final isExpanded = _sectionExpanded[slot] ?? true;
    final localIds = _localOrder[slot];
    final hasCustomOrder = localIds != null || override != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SlotSectionHeader(
          slot: slot,
          productCount: products.length,
          isExpanded: isExpanded,
          onToggle: () =>
              setState(() => _sectionExpanded[slot] = !isExpanded),
        ),

        if (isExpanded) ...[
          if (hasCustomOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () => _resetOrder(slot),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: Text(l.orderResetToRecommended,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primaryFixed,
                      width: 1.5,
                    ),
                    textStyle: AppTypography.labelMd
                        .copyWith(fontWeight: FontWeight.w700),
                    backgroundColor: AppColors.surfaceLow,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),

          GlowCard(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              onReorderItem: (oldIndex, newIndex) {
                final currentIds =
                    products.map((p) => p.id).toList();
                _reorder(slot, currentIds, oldIndex, newIndex, override);
              },
              itemBuilder: (context, index) {
                final product = products[index];
                return RoutineItemRow(
                  key: ValueKey(product.id),
                  product: product,
                  isToggled: false,
                  onToggle: () {},
                  isDraggable: true,
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

final _orderOverrideProvider =
    StreamProvider.family<OrderOverride?, Slot>(
  (ref, slot) =>
      ref.watch(userDataRepositoryProvider).watchOrderOverride(slot),
);

final _perDayOverridesProvider =
    StreamProvider.family<List<OrderOverride>, Slot>(
  (ref, slot) =>
      ref.watch(userDataRepositoryProvider).watchPerDayOrderOverrides(slot),
);

// ── Onboarding single-slot header ────────────────────────────────────────────
// Matches the _Header style from CategoryReviewScreen: back arrow + title +
// step label + subtitle.

class _OnboardingOrderHeader extends StatelessWidget {
  final Slot slot;
  final VoidCallback onBack;
  final AppLocalizations l;

  const _OnboardingOrderHeader({
    required this.slot,
    required this.onBack,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final isMorning = slot == Slot.morning;
    final slotText = isMorning ? l.slotMorning : l.slotEvening;
    final title =
        isMorning ? l.orderHeaderMorning : l.orderHeaderEvening;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLow,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: AppColors.onSurface, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.headlineMd.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.orderStepLabel(slotText),
            style: AppTypography.labelMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l.orderSubtitleV3,
            style: AppTypography.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Advanced options collapsible (onboarding order screen) ───────────────────
// Collapsed by default. Header shows orderAdvancedTitle + sub.
// When expanded: global reset button (if custom order exists) + per-day section
// with 7 tappable weekday rows that open a drag-to-reorder bottom sheet.

class _AdvancedOptionsPanel extends ConsumerWidget {
  final Slot slot;
  final bool expanded;
  final bool hasCustomOrder;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final List<MasterProduct> products;
  final OrderOverride? globalOverride;
  final AppLocalizations l;

  const _AdvancedOptionsPanel({
    required this.slot,
    required this.expanded,
    required this.hasCustomOrder,
    required this.onToggle,
    required this.onReset,
    required this.products,
    required this.globalOverride,
    required this.l,
  });

  String _dayName(int ourDay, BuildContext context) {
    final isHe = Localizations.localeOf(context).languageCode == 'he';
    // ourDay: 0=Sun…6=Sat; HebrewDateStrings/EnglishDateStrings: 0=Mon…6=Sun
    final idx = (ourDay + 6) % 7;
    return isHe
        ? 'יום ${HebrewDateStrings.weekdays[idx]}'
        : EnglishDateStrings.weekdays[idx];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perDayAsync = ref.watch(_perDayOverridesProvider(slot));
    final perDayOverrides = perDayAsync.valueOrNull ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.orderAdvancedTitle,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.orderAdvancedSub,
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: AppColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),

                  // Global reset button
                  if (hasCustomOrder) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: onReset,
                        icon: const Icon(Icons.restart_alt_rounded, size: 16),
                        label: Text(l.orderResetToRecommended,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primaryFixed,
                            width: 1.5,
                          ),
                          textStyle: AppTypography.labelMd
                              .copyWith(fontWeight: FontWeight.w700),
                          backgroundColor: AppColors.surfaceLow,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                      height: 1,
                      color: AppColors.outlineVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Per-day section title
                  Text(
                    l.orderPerDayTitle,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Seven weekday rows: Sun=0 … Sat=6
                  for (int day = 0; day < 7; day++) ...[
                    _WeekdayRow(
                      dayName: _dayName(day, context),
                      hasPerDayOverride: perDayOverrides.any(
                        (o) => o.weekday == day,
                      ),
                      customBadgeLabel: l.orderPerDayCustomBadge,
                      onTap: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _PerDayOrderSheet(
                          slot: slot,
                          weekday: day,
                          dayName: _dayName(day, context),
                          products: products,
                          perDayOverride: perDayOverrides
                              .where((o) => o.weekday == day)
                              .firstOrNull,
                          globalOverride: globalOverride,
                          l: l,
                        ),
                      ),
                    ),
                    if (day < 6)
                      Divider(
                        height: 1,
                        indent: 0,
                        color:
                            AppColors.outlineVariant.withValues(alpha: 0.25),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Single weekday row inside the advanced panel ──────────────────────────────

class _WeekdayRow extends StatelessWidget {
  final String dayName;
  final bool hasPerDayOverride;
  final String customBadgeLabel;
  final VoidCallback onTap;

  const _WeekdayRow({
    required this.dayName,
    required this.hasPerDayOverride,
    required this.customBadgeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Text(
                dayName,
                style: AppTypography.bodyMd.copyWith(
                  fontSize: 13,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (hasPerDayOverride) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  customBadgeLabel,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSecondaryContainer,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_left_rounded,
              textDirection: TextDirection.ltr,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-day order bottom sheet ────────────────────────────────────────────────

class _PerDayOrderSheet extends ConsumerStatefulWidget {
  final Slot slot;
  final int weekday; // 0=Sun…6=Sat
  final String dayName;
  final List<MasterProduct> products;
  final OrderOverride? perDayOverride;
  final OrderOverride? globalOverride;
  final AppLocalizations l;

  const _PerDayOrderSheet({
    required this.slot,
    required this.weekday,
    required this.dayName,
    required this.products,
    required this.perDayOverride,
    required this.globalOverride,
    required this.l,
  });

  @override
  ConsumerState<_PerDayOrderSheet> createState() => _PerDayOrderSheetState();
}

class _PerDayOrderSheetState extends ConsumerState<_PerDayOrderSheet> {
  late List<String> _ids;
  String? _overrideId;

  @override
  void initState() {
    super.initState();
    _overrideId = widget.perDayOverride?.id;

    // Initial order: per-day override > global override > admin order
    final sourceIds = widget.perDayOverride?.orderedProductIds ??
        widget.globalOverride?.orderedProductIds;

    if (sourceIds != null) {
      final sorted = List<MasterProduct>.from(widget.products);
      sorted.sort((a, b) {
        final ai = sourceIds.indexOf(a.id);
        final bi = sourceIds.indexOf(b.id);
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (ai >= 0) return -1;
        if (bi >= 0) return 1;
        return 0;
      });
      _ids = sorted.map((p) => p.id).toList();
    } else {
      _ids = widget.products.map((p) => p.id).toList();
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    setState(() {
      final id = _ids.removeAt(oldIndex);
      _ids.insert(newIndex, id);
    });

    _overrideId ??= _uuid.v4();
    final repo = ref.read(userDataRepositoryProvider);
    await repo.upsertOrderOverride(
      OrderOverride(
        id: _overrideId!,
        slot: widget.slot,
        weekday: widget.weekday,
        orderedProductIds: List<String>.from(_ids),
        lastModified: DateTime.now(),
      ),
    );
  }

  Future<void> _clearDayOrder() async {
    final repo = ref.read(userDataRepositoryProvider);
    await repo.deletePerDayOrderOverride(widget.slot, widget.weekday);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasPerDayOrder = _overrideId != null;

    final orderedProducts = widget.products
        .where((p) => _ids.contains(p.id))
        .toList()
      ..sort((a, b) => _ids.indexOf(a.id).compareTo(_ids.indexOf(b.id)));

    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.l.orderPerDaySheetTitle(widget.dayName),
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                children: [
                  GlowCard(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 0),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: orderedProducts.length,
                      onReorderItem: _onReorder,
                      itemBuilder: (context, index) {
                        final product = orderedProducts[index];
                        return RoutineItemRow(
                          key: ValueKey(product.id),
                          product: product,
                          isToggled: false,
                          onToggle: () {},
                          isDraggable: true,
                        );
                      },
                    ),
                  ),
                  if (hasPerDayOrder) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: _clearDayOrder,
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        label: Text(
                          widget.l.orderPerDayClearDay,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.primaryFixed,
                            width: 1.5,
                          ),
                          textStyle: AppTypography.labelMd
                              .copyWith(fontWeight: FontWeight.w700),
                          backgroundColor: AppColors.surfaceLow,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 16,
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
