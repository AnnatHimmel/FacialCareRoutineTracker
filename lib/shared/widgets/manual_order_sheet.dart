import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/routine_scheduler.dart';
import '../providers/root_providers.dart';
import 'product_thumb.dart';

/// Opens the "manual changes" revert sheet for [slot] on [date] (yyyy-MM-dd).
/// Lists the products whose position was changed manually and offers to revert
/// to the app's automatic order.
Future<void> showManualOrderSheet(
  BuildContext context, {
  required Slot slot,
  required String date,
}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualOrderSheet(slot: slot, date: date),
    );

class _ManualOrderSheet extends ConsumerWidget {
  final Slot slot;
  final String date;

  const _ManualOrderSheet({required this.slot, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final changesAsync =
        ref.watch(manualOrderChangesProvider((date: date, slot: slot)));
    final moved = changesAsync.valueOrNull?.moved ?? const <MovedProduct>[];

    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.onSurfaceVariant,
                ),
                Expanded(
                  child: Text(
                    l.manualOrderSheetTitle,
                    style: AppTypography.headlineMd.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                children: [
                  for (final m in moved) ...[
                    _MovedRow(moved: m, slot: slot),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final boundary = ref.read(dayBoundaryServiceProvider);
                  final weekday = boundary.parseDate(date).weekday % 7;
                  await ref
                      .read(routineSchedulerProvider)
                      .revertEffectiveOrder(slot: slot, weekday: weekday);
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.secondaryContainer,
                  foregroundColor: AppColors.onSecondaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const StadiumBorder(),
                  textStyle: AppTypography.labelMd
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                label: Text(l.manualOrderRevert),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single moved-product row: thumbnail + name/brand + recommended-position
/// badge (where the product returns to on revert).
class _MovedRow extends StatelessWidget {
  final MovedProduct moved;
  final Slot slot;

  const _MovedRow({required this.moved, required this.slot});

  @override
  Widget build(BuildContext context) {
    final isAm = slot == Slot.morning;
    final badgeBg =
        isAm ? AppColors.primaryFixed : AppColors.tertiaryFixed;
    final badgeFg = isAm ? AppColors.primary : AppColors.tertiary;
    final product = moved.product;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: badgeBg.withAlpha(128),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${moved.targetPosition}',
              style: AppTypography.labelSm.copyWith(
                color: badgeFg,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                if (product.brand != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    product.brand!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          ProductThumb(imageAsset: product.imageAsset, size: 44),
        ],
      ),
    );
  }
}
