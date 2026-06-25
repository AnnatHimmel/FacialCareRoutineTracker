import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
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
    Color background,
    Color foreground,
    Color selectedBackground,
  })? _colorInfo(String state) => switch (state) {
        'calm' => (
            background: AppColors.tertiaryFixed,
            foreground: AppColors.onTertiaryContainer,
            selectedBackground: AppColors.tertiaryContainer,
          ),
        'moist' => (
            background: AppColors.secondaryFixed,
            foreground: AppColors.onSecondaryContainer,
            selectedBackground: AppColors.secondaryContainer,
          ),
        'oily' => (
            background: AppColors.primaryFixed,
            foreground: AppColors.primary,
            selectedBackground: AppColors.primaryFixedDim,
          ),
        'dry' => (
            background: const Color(0xFFEDE8E0),
            foreground: const Color(0xFF6B5C4A),
            selectedBackground: const Color(0xFFD4C4B0),
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = switch (state) {
      'calm' => l.skinStateCalm,
      'moist' => l.skinStateMoist,
      'oily' => l.skinStateOily,
      'dry' => l.skinStateDry,
      _ => null,
    };
    final info = _colorInfo(state);
    if (info == null || label == null) return const SizedBox.shrink();

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: selected
          ? const EdgeInsets.symmetric(horizontal: 20, vertical: 9)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        label,
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
