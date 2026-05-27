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
import '../../domain/services/incompatibility_checker.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/category_header.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';
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
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

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
        existing.copyWith(isSelected: !existing.isSelected, lastModified: DateTime.now()),
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

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.morning));
    final eveningSelectionsAsync =
        ref.watch(selectionsProvider(Slot.evening));
    final mutedAsync = ref.watch(mutedConflictsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'בחירת מוצרים',
          style: AppTypography.headlineMd,
        ),
        actions: [
          TextButton(
            onPressed: () => widget.fromSetup
                ? context.go('/setup/schedule')
                : context.pop(),
            child: Text(
              widget.fromSetup ? 'הבא' : 'שמור',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final morningSelections =
              morningSelectionsAsync.valueOrNull ?? [];
          final eveningSelections =
              eveningSelectionsAsync.valueOrNull ?? [];
          final muted = mutedAsync.valueOrNull ?? [];
          final mutedIds =
              muted.map((m) => m.ruleId).toSet();
          final checker = ref.read(incompatibilityCheckerProvider);

          return CustomScrollView(
            slivers: [
              _buildSlotSection(
                slot: Slot.morning,
                master: master,
                selections: morningSelections,
                mutedIds: mutedIds,
                checker: checker,
              ),
              _buildSlotSection(
                slot: Slot.evening,
                master: master,
                selections: eveningSelections,
                mutedIds: mutedIds,
                checker: checker,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlotSection({
    required Slot slot,
    required MasterContent master,
    required List<ProductSelection> selections,
    required Set<String> mutedIds,
    required IncompatibilityChecker checker,
  }) {
    final selectedIds = selections
        .where((s) => s.isSelected)
        .map((s) => s.productId)
        .toSet();

    final slotProducts = master.products
        .where((p) => !p.isDeprecated && p.configForSlot(slot) != null)
        .toList();

    final selectedInSlot =
        slotProducts.where((p) => selectedIds.contains(p.id)).toList();

    final conflicts = checker.getConflictsForSelection(
      slotProducts: selectedInSlot,
      rules: master.rules,
      categories: master.categories,
      mutedRuleIds: mutedIds,
    );

    final categoryMap = {for (final c in master.categories) c.id: c};
    final Map<String, List<MasterProduct>> byCategory = {};
    for (final p in slotProducts) {
      byCategory.putIfAbsent(p.categoryId, () => []).add(p);
    }

    final isExpanded = _sectionExpanded[slot] ?? true;

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SlotSectionHeader(
            slot: slot,
            productCount: selectedInSlot.length,
            isExpanded: isExpanded,
            onToggle: () => setState(
              () => _sectionExpanded[slot] = !isExpanded,
            ),
          ),
        ),
        if (isExpanded) ...[
          // Unmuted conflict banners
          for (final conflict in conflicts.where((c) => !c.isMuted))
            SliverToBoxAdapter(
              child: SoftWarningBanner(
                message:
                    '${conflict.productA.name} ו${conflict.productB.name} לא מומלץ להשתמש יחד',
                muteLabel: 'השתק',
                onMute: () => _muteConflict(conflict.ruleId),
              ),
            ),
          // Muted conflict banners
          for (final conflict in conflicts.where((c) => c.isMuted))
            SliverToBoxAdapter(
              child: SoftWarningBanner(
                message:
                    '${conflict.productA.name} ו${conflict.productB.name} — אזהרה מושתקת',
                customAction: TextButton(
                  onPressed: () => _unmuteConflict(conflict.ruleId),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    textStyle: AppTypography.labelSm,
                  ),
                  child: const Text('בטל השתקה'),
                ),
              ),
            ),
          // Products grouped by category
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
                      final isToggled =
                          selectedIds.contains(product.id);
                      final hasConflict = conflicts.any(
                        (c) =>
                            !c.isMuted &&
                            (c.productA.id == product.id ||
                                c.productB.id == product.id),
                      );
                      return RoutineItemRow(
                        product: product,
                        isToggled: isToggled,
                        onToggle: () => _toggleSelection(
                          product,
                          slot,
                          selections,
                        ),
                        isOwnershipContext: true,
                        hasConflict: hasConflict,
                        onConflictTap: hasConflict
                            ? () => _scrollToConflictBanner(context)
                            : null,
                      );
                    },
                    childCount:
                        byCategory[categoryId]!.length,
                  ),
                ),
              ],
            ),
        ],
      ],
    );
  }

  void _scrollToConflictBanner(BuildContext context) {
    // Expand section if collapsed so banner is visible
    setState(() {
      _sectionExpanded[Slot.morning] = true;
      _sectionExpanded[Slot.evening] = true;
    });
  }
}
