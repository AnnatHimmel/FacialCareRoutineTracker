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
import '../../shared/widgets/category_header.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/product_thumb.dart';
import '../../shared/widgets/slot_section_header.dart';
import '../../shared/widgets/soft_warning_banner.dart';
import '../../shared/widgets/weekday_picker.dart';

const _uuid = Uuid();

class ScheduleSetupScreen extends ConsumerStatefulWidget {
  final bool fromSetup;

  const ScheduleSetupScreen({super.key, this.fromSetup = false});

  @override
  ConsumerState<ScheduleSetupScreen> createState() =>
      _ScheduleSetupScreenState();
}

class _ScheduleSetupScreenState extends ConsumerState<ScheduleSetupScreen> {
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

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

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.morning));
    final eveningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.evening));
    final schedulesAsync = ref.watch(allSchedulesProvider);
    final mutedAsync = ref.watch(mutedConflictsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(showBack: !widget.fromSetup),
      bottomNavigationBar: _buildSetupNav(context),
      body: masterAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final morningSelections =
              morningSelectionsAsync.valueOrNull ?? [];
          final eveningSelections =
              eveningSelectionsAsync.valueOrNull ?? [];
          final schedules = schedulesAsync.valueOrNull ?? [];
          final mutedIds = (mutedAsync.valueOrNull ?? [])
              .map((m) => m.ruleId)
              .toSet();

          final morningSelectedIds = morningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();
          final eveningSelectedIds = eveningSelections
              .where((s) => s.isSelected)
              .map((s) => s.productId)
              .toSet();

          // Only occasional (WeeklyMax) products need scheduling
          final morningOccasional = master.products
              .where((p) =>
                  !p.isDeprecated &&
                  morningSelectedIds.contains(p.id) &&
                  p.morningConfig?.frequencyRule is WeeklyMaxRule)
              .toList();
          final eveningOccasional = master.products
              .where((p) =>
                  !p.isDeprecated &&
                  eveningSelectedIds.contains(p.id) &&
                  p.eveningConfig?.frequencyRule is WeeklyMaxRule)
              .toList();

          final isEmpty =
              morningOccasional.isEmpty && eveningOccasional.isEmpty;

          return Column(
            children: [
              Expanded(
                child: isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'כל המוצרים שלך הם יומיים — אין צורך בתזמון',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          _buildSlotSection(
                            slot: Slot.morning,
                            occasionalProducts: morningOccasional,
                            schedules: schedules,
                            master: master,
                            mutedIds: mutedIds,
                            morningScheduled: morningOccasional,
                            eveningScheduled: eveningOccasional,
                            allSchedules: schedules,
                          ),
                          _buildSlotSection(
                            slot: Slot.evening,
                            occasionalProducts: eveningOccasional,
                            schedules: schedules,
                            master: master,
                            mutedIds: mutedIds,
                            morningScheduled: morningOccasional,
                            eveningScheduled: eveningOccasional,
                            allSchedules: schedules,
                          ),
                          const SliverToBoxAdapter(
                              child: SizedBox(height: 32)),
                        ],
                      ),
              ),
              // ── Sticky bottom CTA ──────────────────────────────────────────
              _BottomCta(
                fromSetup: widget.fromSetup,
                onTap: () => _handleContinue(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlotSection({
    required Slot slot,
    required List<MasterProduct> occasionalProducts,
    required List<WeekdaySchedule> schedules,
    required MasterContent master,
    required Set<String> mutedIds,
    required List<MasterProduct> morningScheduled,
    required List<MasterProduct> eveningScheduled,
    required List<WeekdaySchedule> allSchedules,
  }) {
    if (occasionalProducts.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final isExpanded = _sectionExpanded[slot] ?? true;

    // Day-dependent conflict warnings for sameDayAcrossBoth
    final dayConflicts = _computeDayConflicts(
      morningScheduled,
      eveningScheduled,
      allSchedules,
      master,
      mutedIds,
    );

    final categoryMap = {for (final c in master.categories) c.id: c};
    final Map<String, List<MasterProduct>> byCategory = {};
    for (final p in occasionalProducts) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: SlotSectionHeader(
              slot: slot,
              productCount: occasionalProducts.length,
              isExpanded: isExpanded,
              onToggle: () => setState(
                () => _sectionExpanded[slot] = !isExpanded,
              ),
            ),
          ),
        ),
        if (isExpanded) ...[
          for (final conflict in dayConflicts)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 4),
                child: SoftWarningBanner(
                  message:
                      '${conflict.$1} ו${conflict.$2} מתנגשים בימים משותפים',
                ),
              ),
            ),
          for (final categoryId in byCategory.keys)
            SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: CategoryHeader(
                      categoryName:
                          categoryMap[categoryId]?.name ?? categoryId,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product =
                            byCategory[categoryId]![index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index <
                                    byCategory[categoryId]!.length - 1
                                ? 12
                                : 0,
                          ),
                          child: _ProductScheduleCard(
                            product: product,
                            slot: slot,
                            schedules: schedules,
                            onChanged: (weekdays, existing) =>
                                _updateSchedule(
                              product.id,
                              slot,
                              weekdays,
                              existing,
                            ),
                          ),
                        );
                      },
                      childCount: byCategory[categoryId]!.length,
                    ),
                  ),
                ),
              ],
            ),
        ],
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
      final aSchedule = schedules
          .where((s) => s.productId == c.productA.id)
          .firstOrNull;
      final bSchedule = schedules
          .where((s) => s.productId == c.productB.id)
          .firstOrNull;

      if (aSchedule != null && bSchedule != null) {
        final overlap =
            aSchedule.weekdays.intersection(bSchedule.weekdays);
        if (overlap.isNotEmpty) {
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
    final selectedDays = existing?.weekdays ?? {};

    final rule = product.configForSlot(slot)?.frequencyRule;
    final maxPerWeek = rule is WeeklyMaxRule ? rule.maxPerWeek : null;
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
                  crossAxisAlignment: CrossAxisAlignment.end,
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
                    if (maxPerWeek != null)
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

// ── Sticky bottom CTA ─────────────────────────────────────────────────────────

class _BottomCta extends StatelessWidget {
  final bool fromSetup;
  final VoidCallback onTap;

  const _BottomCta({required this.fromSetup, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                    fromSetup ? 'הבא' : 'שמור',
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
