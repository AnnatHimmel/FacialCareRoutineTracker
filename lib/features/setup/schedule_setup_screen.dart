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
      appBar: AppBar(
        title: Text('תזמון מוצרים', style: AppTypography.headlineMd),
        actions: [
          TextButton(
            onPressed: () => widget.fromSetup
                ? context.go('/setup/order')
                : context.pop(),
            child: Text(
              widget.fromSetup ? 'הבא' : 'שמור',
              style:
                  AppTypography.labelMd.copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
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

          return CustomScrollView(
            slivers: [
              if (morningOccasional.isEmpty && eveningOccasional.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'כל המוצרים שלך הם יומיים — אין צורך בתזמון',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
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
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
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
    if (occasionalProducts.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
          child: SlotSectionHeader(
            slot: slot,
            productCount: occasionalProducts.length,
            isExpanded: isExpanded,
            onToggle: () => setState(
              () => _sectionExpanded[slot] = !isExpanded,
            ),
          ),
        ),
        if (isExpanded) ...[
          for (final conflict in dayConflicts)
            SliverToBoxAdapter(
              child: SoftWarningBanner(
                message:
                    '${conflict.$1} ו${conflict.$2} מתנגשים בימים משותפים',
              ),
            ),
          for (final categoryId in byCategory.keys)
            SliverMainAxisGroup(
              slivers: [
                SliverToBoxAdapter(
                  child: CategoryHeader(
                    categoryName:
                        categoryMap[categoryId]?.name ?? categoryId,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product =
                          byCategory[categoryId]![index];
                      return _ProductScheduleRow(
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
                      );
                    },
                    childCount: byCategory[categoryId]!.length,
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
}

class _ProductScheduleRow extends ConsumerWidget {
  final MasterProduct product;
  final Slot slot;
  final List<WeekdaySchedule> schedules;
  final void Function(Set<int> weekdays, WeekdaySchedule? existing) onChanged;

  const _ProductScheduleRow({
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

    final isLikelyLatin =
        product.name.codeUnits.every((c) => c < 128);

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: isLikelyLatin
                    ? Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          product.name,
                          style: AppTypography.bodyMd,
                        ),
                      )
                    : Text(product.name,
                        style: AppTypography.bodyMd),
              ),
              if (maxPerWeek != null)
                Text(
                  'עד $maxPerWeek פעמים/שבוע',
                  style: AppTypography.labelSm.copyWith(
                    color: overCap
                        ? AppColors.tertiary
                        : AppColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
