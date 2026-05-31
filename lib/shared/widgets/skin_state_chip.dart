import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Display or interactive chip for skin states: 'calm' | 'moist' | 'oily'.
/// When [onTap] is provided the chip is tappable (selection mode).
/// Without [onTap] it renders as a read-only label.
class SkinStateChip extends StatelessWidget {
  final String state;
  final bool selected;
  final VoidCallback? onTap;

  const SkinStateChip({
    super.key,
    required this.state,
    this.selected = false,
    this.onTap,
  });

  static ({
    String label,
    Color background,
    Color foreground,
    Color selectedBackground,
  })? _info(String state) => switch (state) {
        'calm' => (
            label: 'רגוע',
            background: AppColors.tertiaryFixed,
            foreground: AppColors.onTertiaryContainer,
            selectedBackground: AppColors.tertiaryContainer,
          ),
        'moist' => (
            label: 'לח',
            background: AppColors.secondaryFixed,
            foreground: AppColors.onSecondaryContainer,
            selectedBackground: AppColors.secondaryContainer,
          ),
        'oily' => (
            label: 'שמני',
            background: AppColors.primaryFixed,
            foreground: AppColors.primary,
            selectedBackground: AppColors.primaryFixedDim,
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final info = _info(state);
    if (info == null) return const SizedBox.shrink();

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? info.selectedBackground : info.background,
        borderRadius: BorderRadius.circular(9999),
        border: selected
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
                width: 1.5,
              )
            : null,
      ),
      child: Text(
        info.label,
        style: AppTypography.labelSm.copyWith(
          color: info.foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: chip);
    }
    return chip;
  }
}
