import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
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

// Hebrew weekday labels (Sunday-first)
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
  int? _openConflictDay; // which day's conflict detail panel is open

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
      _openConflictDay = null; // close conflict panel on slot change
    });
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningAsync = ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);
    final customAsync = ref.watch(customProductsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(showBack: !widget.fromSetup),
      bottomNavigationBar: _isProductsFlow ? null : _buildSetupNav(context),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
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

          // Per-slot conflict days (used for tab markers + week strip)
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
              // Slot tab switcher
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
                  ),
                ),

              Expanded(
                child: isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'לא נבחרו מוצרים עדיין',
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
                          // Week-at-a-glance card
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
                                  checker: checker,
                                  withinSlotRules: withinSlotRules,
                                  categories: master.categories,
                                  mutedIds: mutedIds,
                                ),
                              ),
                            ),

                          // Cross-slot hint banner — current slot is clean, other has issues
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
                                            'יש התנגשות ב${otherSlot == Slot.morning ? 'שגרת בוקר' : 'שגרת ערב'} — הקישי לתיקון',
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

                          // Occasional sub-section
                          if (occasional.isNotEmpty)
                            _buildSubSection(
                              label: 'לא לשימוש יומי',
                              count: occasional.length,
                              products: occasional,
                              slot: _activeSlot,
                              schedules: schedules,
                            ),

                          // Daily sub-section
                          if (daily.isNotEmpty)
                            _buildSubSection(
                              label: 'יומיים',
                              count: daily.length,
                              products: daily,
                              slot: _activeSlot,
                              schedules: schedules,
                            ),

                          const SliverToBoxAdapter(
                              child: SizedBox(height: 32)),
                        ],
                      ),
              ),

              // Sticky bottom CTA
              _BottomCta(
                fromSetup: widget.fromSetup,
                isProductsFlow: _isProductsFlow,
                hasConflicts: activeConflictDays.isNotEmpty,
                activeSlotLabel:
                    _activeSlot == Slot.morning ? 'בוקר' : 'ערב',
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
    required int count,
    required List<MasterProduct> products,
    required Slot slot,
    required List<WeekdaySchedule> schedules,
  }) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              '$label ($count)',
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

// ── Week-at-a-glance card ─────────────────────────────────────────────────────

class _WeekAtAGlanceCard extends StatelessWidget {
  final Slot slot;
  final List<MasterProduct> products;
  final List<WeekdaySchedule> schedules;
  final List<int> conflictDays;
  final int? openDay;
  final ValueChanged<int> onDayTap;
  final VoidCallback onCloseDetail;
  final IncompatibilityChecker checker;
  final List<IncompatibilityRule> withinSlotRules;
  final List<Category> categories;
  final Set<String> mutedIds;

  const _WeekAtAGlanceCard({
    required this.slot,
    required this.products,
    required this.schedules,
    required this.conflictDays,
    required this.openDay,
    required this.onDayTap,
    required this.onCloseDetail,
    required this.checker,
    required this.withinSlotRules,
    required this.categories,
    required this.mutedIds,
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

  List<(MasterProduct, MasterProduct)> _conflictPairsOnDay(int dayId) {
    final onDay = products.where((p) {
      final sched = schedules
          .where((s) => s.productId == p.id && s.slot == slot)
          .firstOrNull;
      if (sched != null && sched.weekdays.isNotEmpty) {
        return sched.weekdays.contains(dayId);
      }
      return p.configForSlot(slot)?.frequencyRule is DailyRule;
    }).toList();
    final conflicts = checker.getConflictsForSelection(
      activeSlot: slot,
      slotProducts: onDay,
      otherSlotProducts: const [],
      rules: withinSlotRules,
      categories: categories,
      mutedRuleIds: mutedIds,
    );
    return conflicts
        .where((c) => !c.isMuted)
        .map((c) => (c.productA, c.productB))
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
          // Card header
          Row(
            children: [
              Text(
                'מבט שבועי',
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
                      'הקישי על יום מסומן',
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
                  'מספר מוצרים ביום',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Day cells row
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

          // Inline conflict detail panel
          if (openDay != null && conflictDays.contains(openDay!))
            _ConflictDetailPanel(
              dayLabel: _dayNames[openDay!],
              pairs: _conflictPairsOnDay(openDay!),
              onClose: onCloseDetail,
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
  final List<(MasterProduct, MasterProduct)> pairs;
  final VoidCallback onClose;

  const _ConflictDetailPanel({
    required this.dayLabel,
    required this.pairs,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withAlpha(128),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withAlpha(64)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    dayLabel,
                    style: AppTypography.labelSm.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'לא מומלץ לשלב',
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close_rounded,
                        size: 17, color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final (a, b) in pairs) ...[
              Row(
                children: [
                  ProductThumb(imageAsset: a.imageAsset, size: 28),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded,
                        size: 12, color: AppColors.error),
                  ),
                  Expanded(
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  ProductThumb(imageAsset: b.imageAsset, size: 28),
                ],
              ),
              if (pairs.last != (a, b)) const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
            Text(
              'הזיזי אחד מהם ליום אחר, או השאירי כך — לא נחסום.',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onSurfaceVariant,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Slot tab switcher ─────────────────────────────────────────────────────────

class _SlotTabSwitcher extends StatelessWidget {
  final Slot activeSlot;
  final bool hasMorning;
  final bool hasEvening;
  final bool morningHasConflict;
  final bool eveningHasConflict;
  final ValueChanged<Slot> onSelect;

  const _SlotTabSwitcher({
    required this.activeSlot,
    required this.hasMorning,
    required this.hasEvening,
    required this.morningHasConflict,
    required this.eveningHasConflict,
    required this.onSelect,
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
            label: 'בוקר',
            icon: Icons.wb_sunny_rounded,
            active: activeSlot == Slot.morning,
            isMorning: true,
            hasConflict: morningHasConflict,
            onTap: hasMorning ? () => onSelect(Slot.morning) : null,
          ),
          _SlotTab(
            label: 'ערב',
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

// ── Product schedule card ─────────────────────────────────────────────────────

class _ProductScheduleCard extends ConsumerWidget {
  final MasterProduct product;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final void Function(Set<int> weekdays, WeekdaySchedule? existing) onChanged;

  const _ProductScheduleCard({
    required this.product,
    required this.slot,
    required this.schedules,
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
          // Product header: thumb + name + badge
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
                          ? 'מומלץ: כל יום'
                          : maxPerWeek != null
                              ? 'מומלץ: עד $maxPerWeek× בשבוע'
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
              // Count badge
              if (maxPerWeek != null)
                _CountBadge(text: '$count/$maxPerWeek', isError: overCap)
              else if (isDaily)
                _CountBadge(
                  text: count == 7 ? 'כל יום' : '$count/7',
                  isError: dailyNoDay,
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Weekday picker
          WeekdayPicker(
            selectedDays: selectedDays,
            onChanged: (days) => onChanged(days, existing),
            showOverCapWarning: overCap,
          ),

          // Inline warnings
          if (overCap) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_rounded,
                    size: 13, color: AppColors.error),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'מעבר למומלץ — שקלי להפחית ל־$maxPerWeek ימים',
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
                    'לא נבחר יום — המוצר לא ישובץ',
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

// ── Count / cap badge ─────────────────────────────────────────────────────────

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

// ── Sticky bottom CTA ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool fromSetup;
  final bool isProductsFlow;
  final bool hasConflicts;
  final String activeSlotLabel;
  final VoidCallback onTap;

  const _BottomCta({
    required this.fromSetup,
    required this.isProductsFlow,
    required this.hasConflicts,
    required this.activeSlotLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = fromSetup
        ? 'הבא'
        : isProductsFlow
            ? 'סיום ושמירת השגרה'
            : 'שמור';

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
              'עדיין יש ימי התנגשות ב$activeSlotLabel',
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
