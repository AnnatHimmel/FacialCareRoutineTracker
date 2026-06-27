import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';

/// Outlined pill shown under a slot header on Daily Home when a manual order is
/// in effect for that slot today. Slot-tinted (peach for morning, rosy for
/// evening); tapping it opens the revert sheet. The label carries the real
/// count of moved products.
class ManualOrderChip extends StatelessWidget {
  final Slot slot;
  final int count;
  final VoidCallback onTap;

  const ManualOrderChip({
    super.key,
    required this.slot,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isAm = slot == Slot.morning;
    final fg = isAm ? AppColors.primary : AppColors.tertiary;
    final border = isAm ? AppColors.primaryFixed : AppColors.tertiaryFixed;

    return Semantics(
      button: true,
      label: l.manualOrderChip(count),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: border.withAlpha(38),
              borderRadius: BorderRadius.circular(9999),
              border: Border.all(color: border, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Leading info icon — renders to the right of the text in RTL,
                // to the left in LTR.
                Icon(Icons.info_outline_rounded, size: 14, color: fg),
                const SizedBox(width: 5),
                Text(
                  l.manualOrderChip(count),
                  maxLines: 1,
                  style: AppTypography.labelSm.copyWith(
                    color: fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
