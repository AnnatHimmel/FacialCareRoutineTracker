import 'package:flutter/material.dart';
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int? weekMissesUsed;
  final int weekMissBudget;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    this.weekMissesUsed,
    this.weekMissBudget = 3,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurSigma,
          sigmaY: AppColors.glassBlurSigma,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatCell(
                    icon: '🔥',
                    value: '$currentStreak',
                    label: 'רצף נוכחי',
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.outlineVariant,
                  ),
                  _StatCell(
                    icon: '⭐',
                    value: '$longestStreak',
                    label: 'שיא אישי',
                  ),
                ],
              ),
              if (weekMissesUsed != null) ...[
                const SizedBox(height: 12),
                _MissBudgetBar(
                  used: weekMissesUsed!,
                  budget: weekMissBudget,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String icon;
  final String value;
  final String label;

  const _StatCell({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.headlineLg
              .copyWith(color: AppColors.primary),
        ),
        Text(
          label,
          style:
              AppTypography.labelSm.copyWith(color: AppColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _MissBudgetBar extends StatelessWidget {
  final int used;
  final int budget;

  const _MissBudgetBar({required this.used, required this.budget});

  @override
  Widget build(BuildContext context) {
    final remaining = (budget - used).clamp(0, budget);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'חסד שבועי',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            Text(
              '$remaining/$budget',
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: budget > 0 ? remaining / budget : 0,
            backgroundColor: AppColors.surfaceContainer,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
