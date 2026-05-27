import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';

class SlotSectionHeader extends StatelessWidget {
  final Slot slot;
  final int productCount;
  final bool isExpanded;
  final VoidCallback onToggle;

  const SlotSectionHeader({
    super.key,
    required this.slot,
    required this.productCount,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isMorning = slot == Slot.morning;
    final color = isMorning ? AppColors.secondary : AppColors.tertiary;
    final containerColor =
        isMorning ? AppColors.secondaryContainer : AppColors.tertiaryContainer;
    final icon = isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_outlined;
    final label = isMorning ? 'בוקר' : 'ערב';

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: containerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style:
                  AppTypography.headlineMd.copyWith(color: AppColors.onSurface),
            ),
            const SizedBox(width: 6),
            Text(
              '($productCount)',
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
