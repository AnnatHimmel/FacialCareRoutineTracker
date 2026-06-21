import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/l10n/hebrew_date_strings.dart' show HebrewDateStrings, EnglishDateStrings;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/enums/slot.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
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
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final morningRecordAsync =
        ref.watch(_dayRecordDetailProvider((date: widget.date, slot: Slot.morning)));
    final eveningRecordAsync =
        ref.watch(_dayRecordDetailProvider((date: widget.date, slot: Slot.evening)));

    final morningRecord = morningRecordAsync.valueOrNull;
    final eveningRecord = eveningRecordAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        showBack: true,
        action: IconButton(
          icon: const Icon(Icons.camera_alt_outlined),
          color: AppColors.onSurfaceVariant,
          onPressed: () => context.push('/skin-log/${widget.date}'),
          tooltip: l.dayDetailJournalTooltip,
        ),
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final customProds =
              ref.watch(customProductsProvider).valueOrNull ?? [];
          final productMap = {
            for (final p in master.products) p.id: p,
            for (final cp in customProds) cp.id: cp.toMasterProduct(),
          };

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _formatDateHebrew(widget.date, l),
                    textAlign: TextAlign.start,
                    style: AppTypography.headlineMd.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 56,
                          color: AppColors.primaryFixed,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l.dayDetailNoData,
                          style: AppTypography.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: SlotSectionHeader(
              slot: slot,
              productCount: products.length,
              isExpanded: isExpanded,
              onToggle: () =>
                  setState(() => _sectionExpanded[slot] = !isExpanded),
            ),
          ),
        ),
        if (isExpanded)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < products.length - 1 ? 8.0 : 0.0,
                    ),
                    child: RoutineItemRow(
                      product: product,
                      isToggled: recorded.contains(product.id),
                      onToggle: () => _toggleProduct(record, product.id),
                    ),
                  );
                },
                childCount: products.length,
              ),
            ),
          ),
      ],
    );
  }

  String _formatDateHebrew(String dateStr, AppLocalizations l) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final day = int.tryParse(parts[2]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    if (l.localeName == 'en') {
      return '${EnglishDateStrings.months[month - 1]} ${EnglishDateStrings.ordinal(day)}';
    }
    return '$day ב${HebrewDateStrings.months[month - 1]}';
  }
}

final _dayRecordDetailProvider =
    StreamProvider.family<DayRecord?, ({String date, Slot slot})>(
  (ref, params) => ref
      .watch(userDataRepositoryProvider)
      .watchDayRecord(params.date, params.slot),
);
