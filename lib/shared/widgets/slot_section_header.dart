import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';

class SlotSectionHeader extends StatelessWidget {
  final Slot slot;
  final int productCount;
  final int? doneCount;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const SlotSectionHeader({
    super.key,
    required this.slot,
    required this.productCount,
    this.doneCount,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isMorning = slot == Slot.morning;
    final color = isMorning ? AppColors.primary : AppColors.secondary;
    final iconColor =
        isMorning ? AppColors.primaryContainer : AppColors.secondaryFixedDim;
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded;
    final label = isMorning ? l.slotMorningRoutine : l.slotEveningRoutine;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
        child: Row(
          children: [
            if (onToggle != null) ...[
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, color: color),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: AppTypography.bodyLg.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}
