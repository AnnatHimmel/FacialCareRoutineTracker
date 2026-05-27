import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/routine_item_row.dart';
import '../../shared/widgets/slot_section_header.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final String date;

  const DayDetailScreen({super.key, required this.date});

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  final Map<Slot, bool> _sectionExpanded = {
    Slot.morning: true,
    Slot.evening: true,
  };

  Future<void> _toggleProduct(DayRecord record, String productId) async {
    final repo = ref.read(userDataRepositoryProvider);
    final recorded = List<String>.from(record.recordedProductIds);
    if (recorded.contains(productId)) {
      recorded.remove(productId);
    } else {
      recorded.add(productId);
    }
    await repo.updateDayRecord(
      record.copyWith(
        recordedProductIds: recorded,
        lastModified: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final masterAsync = ref.watch(masterContentProvider);
    final morningRecordAsync =
        ref.watch(_dayRecordDetailProvider((date: widget.date, slot: Slot.morning)));
    final eveningRecordAsync =
        ref.watch(_dayRecordDetailProvider((date: widget.date, slot: Slot.evening)));

    final morningRecord = morningRecordAsync.valueOrNull;
    final eveningRecord = eveningRecordAsync.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _formatDateHebrew(widget.date),
          style: AppTypography.headlineMd,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => context.push('/skin-log/${widget.date}'),
            tooltip: 'יומן עור',
          ),
        ],
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final productMap = {for (final p in master.products) p.id: p};

          return CustomScrollView(
            slivers: [
              _buildSlotSection(
                slot: Slot.morning,
                record: morningRecord,
                productMap: productMap,
              ),
              _buildSlotSection(
                slot: Slot.evening,
                record: eveningRecord,
                productMap: productMap,
              ),
              if (morningRecord == null && eveningRecord == null)
                SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'אין נתונים ליום זה',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
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
    required DayRecord? record,
    required Map<String, MasterProduct> productMap,
  }) {
    if (record == null || record.resolvedProductIds.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final products = record.resolvedProductIds
        .map((id) => productMap[id])
        .whereType<MasterProduct>()
        .toList();

    if (products.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final isExpanded = _sectionExpanded[slot] ?? true;
    final recorded = record.recordedProductIds.toSet();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: SlotSectionHeader(
            slot: slot,
            productCount: products.length,
            isExpanded: isExpanded,
            onToggle: () =>
                setState(() => _sectionExpanded[slot] = !isExpanded),
          ),
        ),
        if (isExpanded)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = products[index];
                return RoutineItemRow(
                  product: product,
                  isToggled: recorded.contains(product.id),
                  onToggle: () => _toggleProduct(record, product.id),
                );
              },
              childCount: products.length,
            ),
          ),
      ],
    );
  }

  String _formatDateHebrew(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    const months = [
      'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
      'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
    ];
    return '$day ב${months[month - 1]}';
  }
}

final _dayRecordDetailProvider =
    StreamProvider.family<DayRecord?, ({String date, Slot slot})>(
  (ref, params) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecord(params.date, params.slot),
);
