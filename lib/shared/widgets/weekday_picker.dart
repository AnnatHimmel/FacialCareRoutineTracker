import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class WeekdayPicker extends StatelessWidget {
  final Set<int> selectedDays;
  final ValueChanged<Set<int>> onChanged;
  final bool showOverCapWarning;

  static const _labels = ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳'];

  const WeekdayPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.showOverCapWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (i) {
            final isSelected = selectedDays.contains(i);
            return _DayChip(
              label: _labels[i],
              isSelected: isSelected,
              onTap: () {
                final updated = Set<int>.from(selectedDays);
                if (isSelected) {
                  updated.remove(i);
                } else {
                  updated.add(i);
                }
                onChanged(updated);
              },
            );
          }),
        ),
        if (showOverCapWarning) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.tertiary,
              ),
              const SizedBox(width: 6),
              Text(
                'מעל ההמלצה השבועית',
                style: AppTypography.labelSm
                    .copyWith(color: AppColors.tertiary),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outlineVariant,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: isSelected ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
