import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/rule_scope.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/soft_warning_banner.dart';
import '../../shared/widgets/weekday_picker.dart';

const _uuid = Uuid();

class ScheduleSetupScreen extends ConsumerStatefulWidget {
  final bool fromSetup;
  /// True when accessed as step 3 from the products nav-tab flow
  /// (i.e. pushed via /products/schedule within the shell).
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

  Future<void> _updateSchedule(
    String productId,
    Slot slot,
    Set<int> weekdays,
    WeekdaySchedule? existing,
  ) async {
    final repo = ref.read(userDataRepositoryProvider);
    await repo.upsertSchedule(
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

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelectionsAsync = ref.watch(selectionsProvider(Slot.morning));
    final eveningSelectionsAsync = ref.watch(selectionsProvider(Slot.evening));
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
          final morningSelections = morningSelectionsAsync.valueOrNull ?? [];
          final eveningSelections = eveningSelectionsAsync.valueOrNull ?? [];
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

          final morningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  morningSelectedIds.contains(p.id) &&
                  p.morningConfig != null)
              .toList();
          final eveningProducts = allProducts
              .where((p) =>
                  !p.isDeprecated &&
                  eveningSelectedIds.contains(p.id) &&
                  p.eveningConfig != null)
              .toList();

          final activeProducts =
              _activeSlot == Slot.morning ? morningProducts : eveningProducts;
          final occasional = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is WeeklyMaxRule)
              .toList();
          final daily = activeProducts
              .where((p) =>
                  p.configForSlot(_activeSlot)?.frequencyRule is DailyRule)
              .toList();

          // Same-day conflicts (shown on evening tab)
          final dayConflicts = _computeDayConflicts(
              morningProducts, eveningProducts, schedules, master, mutedIds);

          final isEmpty = morningProducts.isEmpty && eveningProducts.isEmpty;

          return Column(
            children: [
              // ── Step 3 indicator (products flow only) ──────────────────────
              if (_isProductsFlow)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: _ScheduleStepIndicator(),
                ),

              // ── Slot tab switcher ───────────────────────────────────────────
              if (!isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _SlotTabSwitcher(
                    activeSlot: _activeSlot,
                    hasMorning: morningProducts.isNotEmpty,
                    hasEvening: eveningProducts.isNotEmpty,
                    onSelect: (Slot slot) => setState(() => _activeSlot = slot),
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
                          // Conflict banners
                          if (_activeSlot == Slot.evening)
                            for (final c in dayConflicts)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      20, 12, 20, 0),
                                  child: SoftWarningBanner(
                                    message:
                                        '${c.$1} ו${c.$2} מתנגשים בימים משותפים',
                                  ),
                                ),
                              ),

                          // Occasional sub-section
                          if (occasional.isNotEmpty)
                            _buildSubSection(
                              label: 'מוצרים אקראיים',
                              count: occasional.length,
                              products: occasional,
                              slot: _activeSlot,
                              schedules: schedules,
                            ),

                          // Daily sub-section
                          if (daily.isNotEmpty)
                            _buildSubSection(
                              label: 'מוצרים יומיים',
                              count: daily.length,
                              products: daily,
                              slot: _activeSlot,
                              schedules: schedules,
                            ),

                          const SliverToBoxAdapter(child: SizedBox(height: 32)),
                        ],
                      ),
              ),

              // ── Sticky bottom CTA ──────────────────────────────────────────
              _BottomCta(
                fromSetup: widget.fromSetup,
                isProductsFlow: _isProductsFlow,
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

  List<(String, String)> _computeDayConflicts(
    List<MasterProduct> morningProducts,
    List<MasterProduct> eveningProducts,
    List<WeekdaySchedule> schedules,
    MasterContent master,
    Set<String> mutedIds,
  ) {
    final result = <(String, String)>[];
    final checker = ref.read(incompatibilityCheckerProvider);
    final allConflicts = checker.getConflictsForDay(
      morningProducts: morningProducts,
      eveningProducts: eveningProducts,
      rules: master.rules
          .where((r) => r.scope == RuleScope.sameDayAcrossBoth)
          .toList(),
      categories: master.categories,
      mutedRuleIds: mutedIds,
    );
    for (final c in allConflicts.where((c) => !c.isMuted)) {
      final aSchedule =
          schedules.where((s) => s.productId == c.productA.id).firstOrNull;
      final bSchedule =
          schedules.where((s) => s.productId == c.productB.id).firstOrNull;
      if (aSchedule != null && bSchedule != null) {
        if (aSchedule.weekdays.intersection(bSchedule.weekdays).isNotEmpty) {
          result.add((c.productA.name, c.productB.name));
        }
      }
    }
    return result;
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

// ── Slot tab switcher (בוקר / ערב) ───────────────────────────────────────────

class _SlotTabSwitcher extends StatelessWidget {
  final Slot activeSlot;
  final bool hasMorning;
  final bool hasEvening;
  final ValueChanged<Slot> onSelect;

  const _SlotTabSwitcher({
    required this.activeSlot,
    required this.hasMorning,
    required this.hasEvening,
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
          _Tab(
            label: 'בוקר',
            icon: Icons.wb_sunny_rounded,
            active: activeSlot == Slot.morning,
            isMorning: true,
            onTap: hasMorning ? () => onSelect(Slot.morning) : null,
          ),
          _Tab(
            label: 'ערב',
            icon: Icons.dark_mode_rounded,
            active: activeSlot == Slot.evening,
            isMorning: false,
            onTap: hasEvening ? () => onSelect(Slot.evening) : null,
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final bool isMorning;
  final VoidCallback? onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.active,
    required this.isMorning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeBg =
        isMorning ? AppColors.primaryContainer : AppColors.tertiary;
    const Color activeText = AppColors.onPrimary;
    final Color inactiveText =
        AppColors.onSurfaceVariant.withValues(alpha: 0.6);

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
              Icon(
                icon,
                size: 18,
                color: active ? activeText : inactiveText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Product card with weekday picker ──────────────────────────────────────────

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
    // Daily products default to all 7 days when no schedule has been saved yet
    final selectedDays = existing?.weekdays ??
        (isDaily ? {0, 1, 2, 3, 4, 5, 6} : <int>{});
    final overCap =
        maxPerWeek != null && selectedDays.length > maxPerWeek;
    final count = selectedDays.length;

    final isLikelyLatin =
        product.name.codeUnits.every((c) => c < 128);

    return GlowCard(
      padding: const EdgeInsets.all(16),
      shadow: AppColors.glowSm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Product header: thumb + name + cap badge ─────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProductThumb(
                imageAsset: product.imageAsset,
                size: 44,
              ),
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
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                          ),
                    if (isDaily)
                      Text(
                        'יומי',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.right,
                      )
                    else if (maxPerWeek != null)
                      Text(
                        'מומלץ: עד $maxPerWeek× בשבוע',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.right,
                      ),
                  ],
                ),
              ),
              if (maxPerWeek != null) ...[
                const SizedBox(width: 8),
                _CapBadge(
                  count: count,
                  cap: maxPerWeek,
                  overCap: overCap,
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          // ── Weekday picker ───────────────────────────────────────────────
          WeekdayPicker(
            selectedDays: selectedDays,
            onChanged: (days) => onChanged(days, existing),
            showOverCapWarning: overCap,
          ),
        ],
      ),
    );
  }
}

// ── Count/cap badge (count/cap pill) ──────────────────────────────────────────

class _CapBadge extends StatelessWidget {
  final int count;
  final int cap;
  final bool overCap;

  const _CapBadge({
    required this.count,
    required this.cap,
    required this.overCap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (count == 0) {
      bg = AppColors.surfaceHigh;
      fg = AppColors.onSurfaceVariant;
    } else if (overCap) {
      bg = AppColors.errorContainer;
      fg = AppColors.error;
    } else {
      bg = AppColors.secondaryFixed;
      fg = AppColors.onSecondaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count/$cap',
        style: AppTypography.labelSm.copyWith(color: fg),
      ),
    );
  }
}

// ── Step 3 indicator (shown on schedule screen in products flow) ──────────────

class _ScheduleStepIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const steps = ['בוקר', 'ערב', 'תזמון'];
    const currentStep = 3;
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
            isDone: i + 1 < currentStep,
            isActive: i + 1 == currentStep,
          ),
        ],
      ],
    );
  }
}

class _StepChip extends StatelessWidget {
  final int number;
  final String label;
  final bool isDone;
  final bool isActive;

  const _StepChip({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = isDone
        ? AppColors.secondary
        : isActive
            ? AppColors.primary
            : AppColors.surfaceHigh;
    final Color fg =
        (isDone || isActive) ? AppColors.onPrimary : AppColors.onSurfaceVariant;
    final Color labelColor = isActive
        ? AppColors.primary
        : isDone
            ? AppColors.onSurface
            : AppColors.onSurfaceVariant.withAlpha(178);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: isDone
              ? Icon(Icons.check, size: 14, color: fg)
              : Center(
                  child: Text(
                    '$number',
                    style: AppTypography.labelSm.copyWith(
                      color: fg,
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

// ── Sticky bottom CTA ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool fromSetup;
  final bool isProductsFlow;
  final VoidCallback onTap;

  const _BottomCta({
    required this.fromSetup,
    required this.isProductsFlow,
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
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppColors.navGlow,
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.primaryGlowGradient,
            borderRadius: BorderRadius.circular(999),
            boxShadow: AppColors.glowLg,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.check_rounded,
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
