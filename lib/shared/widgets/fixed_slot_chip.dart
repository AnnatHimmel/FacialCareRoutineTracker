import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';

/// Small pill showing "בוקר בלבד" or "ערב בלבד" for products fixed to one slot.
class FixedSlotChip extends StatelessWidget {
  final MasterProduct product;

  const FixedSlotChip({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final isAm = product.morningConfig != null;
    final label = isAm ? 'בוקר בלבד' : 'ערב בלבד';
    final bg = isAm
        ? AppColors.primaryFixed.withAlpha(153)
        : AppColors.tertiaryFixed.withAlpha(128);
    final fg = isAm ? AppColors.primary : AppColors.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded, size: 10, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: fg,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
