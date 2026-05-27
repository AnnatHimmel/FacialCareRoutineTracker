import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/enums/day_completion_state.dart';

class CompletionIndicator extends StatelessWidget {
  final DayCompletionState state;
  final double size;

  const CompletionIndicator({
    super.key,
    required this.state,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _buildIndicator(),
    );
  }

  Widget _buildIndicator() {
    switch (state) {
      case DayCompletionState.complete:
        return _Circle(
          color: AppColors.primary,
          child: Icon(Icons.check, color: AppColors.onPrimary, size: size * 0.55),
        );
      case DayCompletionState.partial:
        return _Circle(
          color: AppColors.secondaryContainer,
          child: Icon(
            Icons.remove,
            color: AppColors.secondary,
            size: size * 0.55,
          ),
        );
      case DayCompletionState.missed:
        return _Circle(
          color: AppColors.errorContainer,
          child: Icon(Icons.close, color: AppColors.error, size: size * 0.55),
        );
      case DayCompletionState.future:
        return const _Circle(
          color: AppColors.surfaceContainer,
          child: null,
        );
      case DayCompletionState.noData:
        return _Circle(
          color: AppColors.surfaceContainer,
          child: Icon(
            Icons.circle_outlined,
            color: AppColors.outlineVariant,
            size: size * 0.55,
          ),
        );
    }
  }
}

class _Circle extends StatelessWidget {
  final Color color;
  final Widget? child;

  const _Circle({required this.color, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: child,
    );
  }
}
