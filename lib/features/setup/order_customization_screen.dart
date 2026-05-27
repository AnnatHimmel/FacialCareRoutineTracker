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
      appBar: AppBar(
        title: Text('סדר מוצרים', style: AppTypography.headlineMd),
        actions: [
          TextButton(
            onPressed: () async {
              if (widget.fromSetup) {
                await ref
                    .read(settingsRepositoryProvider)
                    .setOnboardingCompleted(true);
                if (context.mounted) context.go('/today');
              } else {
                context.pop();
              }
            },
            child: Text(
              widget.fromSetup ? 'סיום' : 'שמור',
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

          return ListView(
            children: [
              _buildSlotSection(
                slot: Slot.morning,
                products: morningProducts,
                override: morningOverride,
              ),
              _buildSlotSection(
                slot: Slot.evening,
                products: eveningProducts,
                override: eveningOverride,
              ),
              const SizedBox(height: 32),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _resetOrder(slot),
                    icon: const Icon(Icons.restart_alt, size: 18),
                    label: const Text('איפוס לסדר מומלץ'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      textStyle: AppTypography.labelSm,
                    ),
                  ),
                ],
              ),
            ),
          ReorderableListView.builder(
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
