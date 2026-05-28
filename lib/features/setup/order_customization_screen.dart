import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/order_override.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/master_content_repository.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';

const _uuid = Uuid();

class OrderCustomizationScreen extends ConsumerStatefulWidget {
  final bool fromSetup;

  const OrderCustomizationScreen({super.key, this.fromSetup = false});

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

  // Local reorder state per slot so drags feel instant
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
    if (widget.fromSetup) {
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

          return Stack(
            children: [
              // Scrollable content
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                children: [
                  // Subtitle / instruction
                  Text(
                    'גררו את המוצרים כדי לסדר את השגרה שלכם',
                    textAlign: TextAlign.right,
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),

                  // Morning section
                  if (morningProducts.isNotEmpty)
                    _buildSlotSection(
                      slot: Slot.morning,
                      products: morningProducts,
                      override: morningOverride,
                    ),

                  if (morningProducts.isNotEmpty && eveningProducts.isNotEmpty)
                    const SizedBox(height: 16),

                  // Evening section
                  if (eveningProducts.isNotEmpty)
                    _buildSlotSection(
                      slot: Slot.evening,
                      products: eveningProducts,
                      override: eveningOverride,
                    ),

                  if (morningProducts.isEmpty && eveningProducts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Center(
                        child: Text(
                          'לא נבחרו מוצרים',
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

              // Sticky bottom CTA
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: AppColors.navGlow,
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGlowGradient,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: AppColors.glowLg,
                      ),
                      child: TextButton(
                        onPressed: () => _save(context),
                        style: TextButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          widget.fromSetup ? 'סיום והתחלה' : 'שמירת הסדר החדש',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLg.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
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

    final orderIds = localOrder ?? override?.orderedProductIds;
    if (orderIds != null) {
      products.sort((a, b) {
        final ai = orderIds.indexOf(a.id);
        final bi = orderIds.indexOf(b.id);
        if (ai < 0 && bi < 0) return 0;
        if (ai < 0) return 1;
        if (bi < 0) return -1;
        return ai.compareTo(bi);
      });
    } else {
      products.sort(
        (a, b) => (a.configForSlot(slot)?.order ?? 0)
            .compareTo(b.configForSlot(slot)?.order ?? 0),
      );
    }
    return products;
  }

  Widget _buildSlotSection({
    required Slot slot,
    required List<MasterProduct> products,
    required OrderOverride? override,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    final isExpanded = _sectionExpanded[slot] ?? true;
    final localIds = _localOrder[slot];
    final hasCustomOrder = localIds != null || override != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Slot header (expand/collapse toggle preserved)
        SlotSectionHeader(
          slot: slot,
          productCount: products.length,
          isExpanded: isExpanded,
          onToggle: () =>
              setState(() => _sectionExpanded[slot] = !isExpanded),
        ),

        if (isExpanded) ...[
          // Reset pill — shown only when a custom order exists
          if (hasCustomOrder)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () => _resetOrder(slot),
                  icon: const Icon(Icons.restart_alt_rounded, size: 16),
                  label: const Text('איפוס לסדר המומלץ', maxLines: 1, overflow: TextOverflow.ellipsis),
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

          // Draggable list inside a white pebble card
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

final _orderOverrideProvider =
    StreamProvider.family<OrderOverride?, Slot>(
  (ref, slot) =>
      ref.watch(userDataRepositoryProvider).watchOrderOverride(slot),
);
