import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class StreakWidget extends StatelessWidget {
  final int currentStreak;
  final int longestStreak;
  final int gracesUsed;
  final int gracesTotal;

  const StreakWidget({
    super.key,
    required this.currentStreak,
    required this.longestStreak,
    required this.gracesUsed,
    this.gracesTotal = 3,
  });

  static const Color _white = Color(0xFFFFFFFF);
  static const Color _whiteDim = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final gracesLeft = (gracesTotal - gracesUsed).clamp(0, gracesTotal);
    final subtitle = currentStreak > 0
        ? l.streakOnTrack
        : l.streakStartToday;

    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.glowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        label: l.streakSemanticDays(currentStreak),
                        excludeSemantics: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 5),
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: _white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$currentStreak',
                              style: AppTypography.displayLg.copyWith(
                                color: _white,
                                fontWeight: FontWeight.w700,
                                fontSize: 64,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l.streakDaysInRow,
                        style: AppTypography.labelSm.copyWith(
                          color: _whiteDim,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSm.copyWith(color: _whiteDim),
                        ),
                        const SizedBox(height: 8),
                        _BestStreakChip(bestStreak: longestStreak),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Container(height: 1, color: Colors.white.withAlpha(51)),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: _GraceMeter(total: gracesTotal, left: gracesLeft),
          ),
        ],
      ),
    );
  }
}

class _BestStreakChip extends StatelessWidget {
  final int bestStreak;
  const _BestStreakChip({required this.bestStreak});

  static const Color _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_rounded, color: _white, size: 14),
          const SizedBox(width: 5),
          Text(
            l.streakPersonalBest(bestStreak),
            style: AppTypography.labelSm.copyWith(
              color: _white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraceMeter extends StatelessWidget {
  final int total;
  final int left;
  const _GraceMeter({required this.total, required this.left});

  static const Color _whiteDim = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isExhausted = left == 0;
    final label = isExhausted ? l.streakNoGraces : l.streakGracesLeft(left);
    final semanticLabel = isExhausted
        ? l.streakNoGraces
        : l.streakGracesLeft(left);

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isExhausted ? Icons.shield : Icons.shield_outlined,
                color: _whiteDim,
                size: 14,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: AppTypography.labelSm.copyWith(color: _whiteDim),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                _GraceToken(available: i >= total - left),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GraceToken extends StatelessWidget {
  final bool available;
  const _GraceToken({required this.available});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: available ? Colors.white : Colors.white.withAlpha(26),
        border: available
            ? null
            : Border.all(
                color: Colors.white.withAlpha(64),
                width: 1.5,
              ),
      ),
      child: Icon(
        available ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 11,
        color: available ? AppColors.primary : Colors.white.withAlpha(153),
      ),
    );
  }
}
