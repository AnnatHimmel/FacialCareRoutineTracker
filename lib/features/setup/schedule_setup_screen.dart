import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/incompatibility_rule.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/rule_scope.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/weekday_picker.dart';

const _uuid = Uuid();

const _dayLabels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];
const _dayNames = ['ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי', 'שבת'];

class ScheduleSetupScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  final bool fromProducts;

  const ScheduleSetupScreen({
    super.key,
    this.fromSetup = false,
    this.fromProducts = false,
  });

  @override
  ConsumerState<ScheduleSetupScreen> createState() =>
      _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends ConsumerState<ScheduleSetupScreen> {
  Slot _activeSlot = Slot.morning;
  int? _openConflictDay;

  Future<void> _updateSchedule(
    String productId,
    Slot slot,
    Set<int> weekdays,
    WeekdaySchedule? existing,
  ) async {
    await ref.read(userDataRepositoryProvider).upsertSchedule(
          WeekdaySchedule(
            id: existing?.id ?? _uuid.v4(),
            productId: productId,
            slot: slot,
            weekdays: weekdays,
            lastModified: DateTime.now(),
          ),
        );
  }

  Future<void> _toggleDay(String productId, int dayId) async {
    final schedules = ref.read(allSchedulesProvider).valueOrNull ?? [];
    final existing = schedules
        .where((s) => s.productId == productId && s.slot == _activeSlot)
        .firstOrNull;
    final Set<int> current;
    if (existing != null && existing.weekdays.isNotEmpty) {
      current = Set.from(existing.weekdays);
    } else {
      current = {0, 1, 2, 3, 4, 5, 6};
    }
    current.remove(dayId);
    await _updateSchedule(productId, _activeSlot, current, existing);
  }

  void _handleContinue(BuildContext context) {
    if (widget.fromSetup) {
      context.go('/setup/order?from=setup');
    } else {
      context.pop();
    }
  }

  bool get _isProductsFlow => widget.fromProducts && !widget.fromSetup;

  void _switchSlot(Slot slot) {
    setState(() {
      _activeSlot = slot;
      _openConflictDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);
    final customAsync = ref.watch(customProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(showBack: !widget.fromSetup),
      bottomNavigationBar: _isProductsFlow ? null : _buildSetupNav(context, l),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final morningSelections = morningAsync.valueOrNull ?? [];
          final eveningSelections = eveningAsync.valueOrNull ?? [];
          final schedules = schedulesAsync.valueOrNull ?? [];
          final mutedIds =
              (mutedAsync.valueOrNull ?? []).map((m) => m.ruleId).toSet();
          final customProds = customAsync.valueOrNull ?? [];

          final allProducts = [
            ...master.products,
            ...customProds.map((p) => p.toMasterProduct()),
          ];

          final morningSelectedIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningSelectedIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          final categoryOrderById = {
            for (final cat in master.categories) cat.id: cat.order,
          };

          int slotOrder(MasterProduct p, Slot slot) =>
              (slot == Slot.morning
                  ? p.morningConfig?.order
                  : p.eveningConfig?.order) ??
              999;

          int categoryThenSlotOrder(
              MasterProduct a, MasterProduct b, Slot slot) {
            final catA = categoryOrderById[a.categoryId] ?? 9999;
            final catB = categoryOrderById[b.categoryId] ?? 9999;
            if (catA != catB) return catA.compareTo(catB);
            return slotOrder(a, slot).compareTo(slotOrder(b, slot));
          }

          final morningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  morningSelectedIds.contains(p.id) &&
                  p.morningConfig != null)
              .toList()
            ..sort((a, b) => categoryThenSlotOrder(a, b, Slot.morning));
          final eveningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  eveningSelectedIds.contains(p.id) &&
                  p.eveningConfig != null)
              .toList()
            ..sort((a, b) => categoryThenSlotOrder(a, b, Slot.evening));

          final activeProducts = _activeSlot == Slot.morning
              ? morningProducts
              : eveningProducts;

          final occasional = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is WeeklyMaxRule)
              .toList();
          final daily = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is DailyRule)
              .toList();

          final isEmpty =
              morningProducts.isEmpty && eveningProducts.isEmpty;

          final checker = ref.read(incompatibilityCheckerProvider);
          final withinSlotRules = master.rules
              .where((r) => r.scope == RuleScope.withinSlot)
              .toList();

          List<int> conflictDaysFor(
              Slot slot, List<MasterProduct> slotProducts) {
            final result = <int>[];
            for (int d = 0; d < 7; d++) {
              final onDay = slotProducts.where((p) {
                final sched = schedules
                    .where((s) => s.productId == p.id && s.slot == slot)
                    .firstOrNull;
                if (sched != null && sched.weekdays.isNotEmpty) {
                  return sched.weekdays.contains(d);
                }
                return p.configForSlot(slot)?.frequencyRule is DailyRule;
              }).toList();
              final conflicts = checker.getConflictsForSelection(
                activeSlot: slot,
                slotProducts: onDay,
                otherSlotProducts: [],
                rules: withinSlotRules,
                categories: master.categories,
                mutedRuleIds: mutedIds,
              );
              if (conflicts.any((c) => !c.isMuted)) result.add(d);
            }
            return result;
          }

          final activeConflictDays =
              conflictDaysFor(_activeSlot, activeProducts);
          final otherSlot =
              _activeSlot == Slot.morning ? Slot.evening : Slot.morning;
          final otherProducts =
              _activeSlot == Slot.morning ? eveningProducts : morningProducts;
          final otherConflictDays =
              conflictDaysFor(otherSlot, otherProducts);

          return Column(
            children: [
              if (!isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _SlotTabSwitcher(
                    activeSlot: _activeSlot,
                    hasMorning: morningProducts.isNotEmpty,
                    hasEvening: eveningProducts.isNotEmpty,
                    morningHasConflict: conflictDaysFor(Slot.morning, morningProducts).isNotEmpty,
                    eveningHasConflict: conflictDaysFor(Slot.evening, eveningProducts).isNotEmpty,
                    onSelect: _switchSlot,
                    l: l,
                  ),
                ),

              Expanded(
                child: isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            l.scheduleNoProducts,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        key: ValueKey(_activeSlot),
                        slivers: [
                          if (activeProducts.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                child: _WeekAtAGlanceCard(
                                  slot: _activeSlot,
                                  products: activeProducts,
                                  schedules: schedules,
                                  conflictDays: activeConflictDays,
                                  openDay: _openConflictDay,
                                  onDayTap: (d) => setState(() {
                                    _openConflictDay =
                                        _openConflictDay == d ? null : d;
                                  }),
                                  onCloseDetail: () =>
                                      setState(() => _openConflictDay = null),
                                  onToggleDay: _toggleDay,
                                  checker: checker,
                                  withinSlotRules: withinSlotRules,
                                  categories: master.categories,
                                  mutedIds: mutedIds,
                                  l: l,
                                ),
                              ),
                            ),

                          if (activeConflictDays.isEmpty &&
                              otherConflictDays.isNotEmpty)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                child: GestureDetector(
                                  onTap: () => _switchSlot(otherSlot),
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.errorContainer
                                          .withAlpha(128),
                                      borderRadius:
                                          BorderRadius.circular(18),
                                      border: Border.all(
                                          color: AppColors.error
                                              .withAlpha(64)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.warning_rounded,
                                            size: 17,
                                            color: AppColors.error),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            otherSlot == Slot.morning
                                                ? l.scheduleConflictInMorning
                                                : l.scheduleConflictInEvening,
                                            style:
                                                AppTypography.labelSm.copyWith(
                                              color: AppColors.onSurface,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_left_rounded,
                                            size: 18,
                                            color: AppColors.error),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          if (occasional.isNotEmpty)
                            _buildSubSection(
                              label: '${l.scheduleOccasional} (${occasional.length})',
                              products: occasional,
                              slot: _activeSlot,
                              schedules: schedules,
                              l: l,
                            ),

                          if (daily.isNotEmpty)
                            _buildSubSection(
                              label: '${l.scheduleDaily} (${daily.length})',
                              products: daily,
                              slot: _activeSlot,
                              schedules: schedules,
                              l: l,
                            ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 32)),
                        ],
                      ),
              ),

              _BottomCta(
                fromSetup: widget.fromSetup,
                isProductsFlow: _isProductsFlow,
                hasConflicts: activeConflictDays.isNotEmpty,
                activeSlotLabel:
                    _activeSlot == Slot.morning ? l.slotMorning : l.slotEvening,
                l: l,
                onTap: () => _handleContinue(context),
              ),
            ],
          );
        },
      ),
    );
  }

  SliverMainAxisGroup _buildSubSection({
    required String label,
    required List<MasterProduct> products,
    required Slot slot,
    required List<WeekdaySchedule> schedules,
    required AppLocalizations l,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(
                    bottom: index < products.length - 1 ? 12 : 0),
                child: _ProductScheduleCard(
                  product: products[index],
                  slot: slot,
                  schedules: schedules,
                  l: l,
                  onChanged: (weekdays, existing) => _updateSchedule(
                    products[index].id,
                    slot,
                    weekdays,
                    existing,
                  ),
                ),
              ),
              childCount: products.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSetupNav(BuildContext context, AppLocalizations l) =>
      GlassBottomNav(
        currentIndex: -1,
        onDestinationSelected: (i) {
          const routes = ['/today', '/calendar', '/journal', '/settings'];
          if (i < routes.length) context.go(routes[i]);
        },
        items: [
          GlassNavItem(
            icon: Icons.wb_sunny_outlined,
            selectedIcon: Icons.wb_sunny_rounded,
            label: l.navToday,
          ),
          GlassNavItem(
            icon: Icons.calendar_today_outlined,
            selectedIcon: Icons.calendar_today_rounded,
            label: l.navCalendar,
          ),
          GlassNavItem(
            icon: Icons.auto_stories_outlined,
            selectedIcon: Icons.auto_stories_rounded,
            label: l.navJournal,
          ),
          GlassNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: l.navSettings,
          ),
        ],
      );
}

// ── Week-at-a-glance card ──────────────────────────────────────────────────────

class _WeekAtAGlanceCard extends StatelessWidget {
  final Slot slot;
  final List<MasterProduct> products;
  final List<WeekdaySchedule> schedules;
  final List<int> conflictDays;
  final int? openDay;
  final ValueChanged<int> onDayTap;
  final VoidCallback onCloseDetail;
  final Future<void> Function(String productId, int dayId) onToggleDay;
  final IncompatibilityChecker checker;
  final List<IncompatibilityRule> withinSlotRules;
  final List<Category> categories;
  final Set<String> mutedIds;
  final AppLocalizations l;

  const _WeekAtAGlanceCard({
    required this.slot,
    required this.products,
    required this.schedules,
    required this.conflictDays,
    required this.openDay,
    required this.onDayTap,
    required this.onCloseDetail,
    required this.onToggleDay,
    required this.checker,
    required this.withinSlotRules,
    required this.categories,
    required this.mutedIds,
    required this.l,
  });

  int _countOnDay(int dayId) {
    return products.where((p) {
      final sched = schedules
          .where((s) => s.productId == p.id && s.slot == slot)
          .firstOrNull;
      if (sched != null && sched.weekdays.isNotEmpty) {
        return sched.weekdays.contains(dayId);
      }
      return p.configForSlot(slot)?.frequencyRule is DailyRule;
    }).length;
  }

  List<ConflictInfo> _conflictInfoOnDay(int dayId) {
    final onDay = products.where((p) {
      final sched = schedules
          .where((s) => s.productId == p.id && s.slot == slot)
          .firstOrNull;
      if (sched != null && sched.weekdays.isNotEmpty) {
        return sched.weekdays.contains(dayId);
      }
      return p.configForSlot(slot)?.frequencyRule is DailyRule;
    }).toList();
    return checker
        .getConflictsForSelection(
          activeSlot: slot,
          slotProducts: onDay,
          otherSlotProducts: const [],
          rules: withinSlotRules,
          categories: categories,
          mutedRuleIds: mutedIds,
        )
        .where((c) => !c.isMuted)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasConflicts = conflictDays.isNotEmpty;

    return GlowCard(
      padding: const EdgeInsets.all(12),
      shadow: AppColors.glowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                l.scheduleWeeklyView,
                style: AppTypography.labelMd.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              if (hasConflicts)
                Row(
                  children: [
                    const Icon(Icons.touch_app_rounded,
                        size: 12, color: AppColors.error),
                    const SizedBox(width: 4),
                    Text(
                      l.scheduleTapConflictDay,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l.scheduleProductsPerDay,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              for (int d = 0; d < 7; d++) ...[
                if (d > 0) const SizedBox(width: 6),
                Expanded(
                  child: _DayCell(
                    label: _dayLabels[d],
                    count: _countOnDay(d),
                    isConflict: conflictDays.contains(d),
                    isOpen: openDay == d,
                    onTap: conflictDays.contains(d) ? () => onDayTap(d) : null,
                  ),
                ),
              ],
            ],
          ),

          if (openDay != null && conflictDays.contains(openDay!))
            _ConflictDetailPanel(
              dayLabel: _dayNames[openDay!],
              conflicts: _conflictInfoOnDay(openDay!),
              categories: categories,
              onClose: onCloseDetail,
              onToggleDay: (productId) => onToggleDay(productId, openDay!),
              l: l,
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final int count;
  final bool isConflict;
  final bool isOpen;
  final VoidCallback? onTap;

  const _DayCell({
    required this.label,
    required this.count,
    required this.isConflict,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            fontSize: 10,
            color: isConflict
                ? AppColors.error
                : AppColors.onSurfaceVariant,
            fontWeight: isConflict ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isConflict
                    ? AppColors.error
                    : count > 0
                        ? AppColors.neutralFill
                        : AppColors.neutralFill.withAlpha(8),
                borderRadius: BorderRadius.circular(12),
                border: isOpen
                    ? Border.all(
                        color: AppColors.error, width: 2)
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    count > 0 ? '$count' : '·',
                    style: AppTypography.labelMd.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isConflict
                          ? Colors.white
                          : count > 0
                              ? AppColors.onSurface
                              : AppColors.onSurfaceVariant.withAlpha(102),
                    ),
                  ),
                  if (isConflict)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppColors.error, width: 1),
                        ),
                        child: const Icon(Icons.priority_high_rounded,
                            size: 9, color: AppColors.error),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ConflictDetailPanel extends StatelessWidget {
  final String dayLabel;
  final List<ConflictInfo> conflicts;
  final List<Category> categories;
  final VoidCallback onClose;
  final void Function(String productId) onToggleDay;
  final AppLocalizations l;

  const _ConflictDetailPanel({
    required this.dayLabel,
    required this.conflicts,
    required this.categories,
    required this.onClose,
    required this.onToggleDay,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppColors.error.withValues(alpha: 0.25)),
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 10),
              for (int i = 0; i < conflicts.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _buildPairCard(conflicts[i]),
              ],
              const SizedBox(height: 10),
              Text(
                l.scheduleProductWillRemain,
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                  fontSize: 10,
                  height: 1.375,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: AppColors.error,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.priority_high_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.scheduleConflictHeader(dayLabel),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.scheduleConflictInstruction,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10.5,
                    height: 1.375,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
        Semantics(
          label: l.scheduleClose,
          button: true,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPairCard(ConflictInfo conflict) {
    final catA = categories
        .where((c) => c.id == conflict.productA.categoryId)
        .firstOrNull;
    final catB = categories
        .where((c) => c.id == conflict.productB.categoryId)
        .firstOrNull;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.error.withValues(alpha: 0.15)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProductRow(conflict.productA, catA,
              () => onToggleDay(conflict.productA.id)),
          _buildConnector(),
          _buildProductRow(conflict.productB, catB,
              () => onToggleDay(conflict.productB.id)),
          if (conflict.reason != null) _buildReasonRow(conflict.reason!),
        ],
      ),
    );
  }

  Widget _buildProductRow(
    MasterProduct product,
    Category? cat,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ProductThumb(imageAsset: product.imageAsset, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelSm.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: AppColors.onSurface,
                    height: 1.375,
                  ),
                ),
                if (cat != null) ...[
                  const SizedBox(height: 4),
                  _buildCategoryChip(cat),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildFixButton(onRemove),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(Category cat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryFixed.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (cat.icon != null) ...[
            Icon(
              _iconData(cat.icon!),
              size: 10,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            cat.name,
            style: AppTypography.labelSm.copyWith(
              fontSize: 9,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixButton(VoidCallback onRemove) {
    return GestureDetector(
      onTap: onRemove,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: AppColors.glowSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_rounded,
                color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              l.scheduleRemoveFrom(dayLabel),
              style: AppTypography.labelSm.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox(height: 1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block_rounded,
                    size: 11,
                    color: AppColors.error.withValues(alpha: 0.9)),
                const SizedBox(width: 4),
                Text(
                  l.scheduleNoMix,
                  style: AppTypography.labelSm.copyWith(
                    fontSize: 8.5,
                    color: AppColors.error.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomPaint(
              painter: _DashedLinePainter(),
              child: const SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonRow(String reason) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withValues(alpha: 0.35),
        border: Border(
          top: BorderSide(
              color: AppColors.error.withValues(alpha: 0.10)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.info_rounded,
                size: 13, color: AppColors.error),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              reason,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 10.5,
                height: 1.375,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconData(String name) => switch (name) {
        'soap' => Icons.soap_rounded,
        'bubble_chart' => Icons.bubble_chart_rounded,
        'science' => Icons.science_rounded,
        'water_drop' => Icons.water_drop_rounded,
        'auto_awesome' => Icons.auto_awesome_rounded,
        'opacity' => Icons.opacity_rounded,
        'spa' => Icons.spa_rounded,
        'wb_sunny' => Icons.wb_sunny_rounded,
        _ => Icons.circle_outlined,
      };
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = const Color(0x4DBA1A1A)
      ..strokeWidth = 1.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashWidth, 0), paint);
      x += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Slot tab switcher ──────────────────────────────────────────────────────────

class _SlotTabSwitcher extends StatelessWidget {
  final Slot activeSlot;
  final bool hasMorning;
  final bool hasEvening;
  final bool morningHasConflict;
  final bool eveningHasConflict;
  final ValueChanged<Slot> onSelect;
  final AppLocalizations l;

  const _SlotTabSwitcher({
    required this.activeSlot,
    required this.hasMorning,
    required this.hasEvening,
    required this.morningHasConflict,
    required this.eveningHasConflict,
    required this.onSelect,
    required this.l,
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
          _SlotTab(
            label: l.slotMorning,
            icon: Icons.wb_sunny_rounded,
            active: activeSlot == Slot.morning,
            isMorning: true,
            hasConflict: morningHasConflict,
            onTap: hasMorning ? () => onSelect(Slot.morning) : null,
          ),
          _SlotTab(
            label: l.slotEvening,
            icon: Icons.dark_mode_rounded,
            active: activeSlot == Slot.evening,
            isMorning: false,
            hasConflict: eveningHasConflict,
            onTap: hasEvening ? () => onSelect(Slot.evening) : null,
          ),
        ],
      ),
    );
  }
}

class _SlotTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isMorning;
  final bool hasConflict;
  final VoidCallback? onTap;

  const _SlotTab({
    required this.label,
    required this.icon,
    required this.active,
    required this.isMorning,
    required this.hasConflict,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg =
        isMorning ? AppColors.primaryContainer : AppColors.tertiary;
    const activeText = AppColors.onPrimary;
    final inactiveText = AppColors.onSurfaceVariant.withValues(alpha: 0.6);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: active ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(9999),
            boxShadow: active ? AppColors.glowSm : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelMd.copyWith(
                  color: active ? activeText : inactiveText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon,
                  size: 18,
                  color: active ? activeText : inactiveText),
              if (hasConflict) ...[
                const SizedBox(width: 4),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high_rounded,
                    size: 11,
                    color: active ? AppColors.error : Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product schedule card ──────────────────────────────────────────────────────

class _ProductScheduleCard extends ConsumerWidget {
  final MasterProduct product;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final AppLocalizations l;
  final void Function(Set<int> weekdays, WeekdaySchedule? existing) onChanged;

  const _ProductScheduleCard({
    required this.product,
    required this.slot,
    required this.schedules,
    required this.l,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = schedules
        .where((s) => s.productId == product.id && s.slot == slot)
        .firstOrNull;
    final rule = product.configForSlot(slot)?.frequencyRule;
    final isDaily = rule is DailyRule;
    final maxPerWeek = rule is WeeklyMaxRule ? rule.maxPerWeek : null;
    final selectedDays = existing?.weekdays ??
        (isDaily ? {0, 1, 2, 3, 4, 5, 6} : <int>{});
    final count = selectedDays.length;
    final overCap = maxPerWeek != null && count > maxPerWeek;
    final dailyNoDay = isDaily && count == 0;

    final isLikelyLatin =
        product.name.codeUnits.every((c) => c < 128);

    return GlowCard(
      padding: const EdgeInsets.all(14),
      shadow: AppColors.glowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProductThumb(imageAsset: product.imageAsset, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLikelyLatin
                        ? Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              product.name,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Text(
                            product.name,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                    Text(
                      isDaily
                          ? l.scheduleRecommendedDaily
                          : maxPerWeek != null
                              ? l.scheduleRecommendedWeekly(maxPerWeek)
                              : '',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 10.5,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (maxPerWeek != null)
                _CountBadge(text: '$count/$maxPerWeek', isError: overCap)
              else if (isDaily)
                _CountBadge(
                  text: count == 7 ? l.scheduleCountEveryDay : '$count/7',
                  isError: dailyNoDay,
                ),
            ],
          ),
          const SizedBox(height: 12),

          WeekdayPicker(
            selectedDays: selectedDays,
            onChanged: (days) => onChanged(days, existing),
            showOverCapWarning: overCap,
          ),

          if (overCap) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_rounded,
                    size: 13, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.scheduleOverCap(maxPerWeek),
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.error, fontSize: 11),
                  ),
                ),
              ],
            ),
          ] else if (dailyNoDay) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_rounded,
                    size: 13, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l.scheduleNoDaySelected,
                    style: AppTypography.labelSm
                        .copyWith(color: AppColors.error, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String text;
  final bool isError;

  const _CountBadge({required this.text, required this.isError});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isError ? AppColors.error : AppColors.neutralFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTypography.labelSm.copyWith(
          color: isError ? Colors.white : AppColors.onSurfaceVariant,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  final bool fromSetup;
  final bool isProductsFlow;
  final bool hasConflicts;
  final String activeSlotLabel;
  final AppLocalizations l;
  final VoidCallback onTap;

  const _BottomCta({
    required this.fromSetup,
    required this.isProductsFlow,
    required this.hasConflicts,
    required this.activeSlotLabel,
    required this.l,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = fromSetup
        ? l.backAction
        : isProductsFlow
            ? l.scheduleSaveFinish
            : l.saveAction;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.navGlow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PrimaryButton(
            label: label,
            onTap: onTap,
            trailingIcon: Icons.check_rounded,
            height: 56,
          ),
          if (hasConflicts) ...[
            const SizedBox(height: 6),
            Text(
              l.scheduleConflictWarning(activeSlotLabel),
              textAlign: TextAlign.center,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.error,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
