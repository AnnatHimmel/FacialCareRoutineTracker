import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Lemon "count" pill — e.g. "4 פריטים" or "1/3". Reference: the
/// `bg-secondary-container text-on-secondary-container ... rounded-full` chip
/// beside each category/slot header.
class CountChip extends StatelessWidget {
  final String text;
  const CountChip(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.all(Radius.circular(9999)),
      ),
      child: Text(
        text,
        style: AppTypography.labelSm
            .copyWith(color: AppColors.onSecondaryContainer),
      ),
    );
  }
}

/// Small schedule/status tag — e.g. "AM / PM". Tinted peach by default.
/// Reference: `bg-primary-container/20 text-primary ... rounded` chip.
class TagChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const TagChip(
    this.label, {
    super.key,
    this.background = AppColors.primaryFixed,
    this.foreground = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
