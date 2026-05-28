import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';
import 'radiant_chips.dart';

/// Morning / Evening slot header. RTL: filled sun/moon icon + bold label on the
/// right, optional lemon count chip on the left.
///
/// Reference: `components.jsx` `SlotHeader` — morning is primary (peach) with a
/// filled sun; evening is secondary with a filled moon.
class SlotSectionHeader extends StatelessWidget {
  final Slot slot;
  final int productCount;

  /// Optional "done/total" progress shown as a lemon chip (e.g. "1/3").
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
    final isMorning = slot == Slot.morning;
    final color = isMorning ? AppColors.primary : AppColors.secondary;
    final iconColor =
        isMorning ? AppColors.primaryContainer : AppColors.secondaryFixedDim;
    final icon = isMorning ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded;
    final label = isMorning ? 'בוקר' : 'ערב';

    final chipText = doneCount != null ? '$doneCount/$productCount' : null;

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyLg
                  .copyWith(color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 4),
            if (onToggle != null)
              AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.expand_more, color: color),
              ),
            const Spacer(),
            if (chipText != null) CountChip(chipText),
          ],
        ),
      ),
    );
  }
}
