import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Streak banner — the warm "golden hour" gradient pebble at the top of the
/// home screen. Shows the current streak prominently, the personal best, and
/// (optionally) the weekly grace budget as a slim progress bar.
///
/// Reference: home screen (`_2/screen.png`) — peach gradient card with a glassy
/// flame disc and white text.
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

  static const Color _onGradient = Color(0xFFFFFFFF);
  static const Color _onGradientDim = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    final remaining =
        weekMissesUsed == null ? null : (weekMissBudget - weekMissesUsed!).clamp(0, weekMissBudget);

    final subtitle = currentStreak > 0
        ? 'את בדרך הנכונה לזוהר מושלם!'
        : 'כל יום נחשב — נתחיל היום ✨';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.glowLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'רצף של $currentStreak ימים',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMd.copyWith(
                    color: _onGradient,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelMd.copyWith(color: _onGradientDim),
                ),
                if (remaining != null) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('חסד שבועי',
                          style: AppTypography.labelSm
                              .copyWith(color: _onGradientDim)),
                      Text('$remaining/$weekMissBudget',
                          style: AppTypography.labelSm
                              .copyWith(color: _onGradient)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: LinearProgressIndicator(
                      value: weekMissBudget > 0 ? remaining / weekMissBudget : 0,
                      minHeight: 6,
                      backgroundColor: const Color(0x33FFFFFF),
                      valueColor: const AlwaysStoppedAnimation<Color>(_onGradient),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  'שיא אישי · $longestStreak ימים',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSm.copyWith(color: _onGradientDim),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _FlameDisc(streak: currentStreak),
        ],
      ),
    );
  }
}

class _FlameDisc extends StatelessWidget {
  final int streak;
  const _FlameDisc({required this.streak});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0x33FFFFFF),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFFFFFFFF), size: 30),
          Text(
            '$streak',
            style: AppTypography.labelSm.copyWith(
              color: const Color(0xFFFFFFFF),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
