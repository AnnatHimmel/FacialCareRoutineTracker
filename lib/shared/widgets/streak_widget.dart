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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final gracesLeft = (gracesTotal - gracesUsed).clamp(0, gracesTotal);

    final headline = currentStreak > 0 ? l.streakOnTrack : l.streakStartToday;
    final subtext = l.streakPersonalBest(longestStreak);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: AppColors.streakGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.glowLg,
      ),
      child: Stack(
        children: [
          // Sparkle decorations
          PositionedDirectional(
            top: 12,
            end: 16,
            child: Text(
              '✦',
              style: TextStyle(
                color: _white.withValues(alpha: 0.6),
                fontSize: 20,
              ),
            ),
          ),
          PositionedDirectional(
            bottom: 48,
            end: 60,
            child: Text(
              '✧',
              style: TextStyle(
                color: _white.withValues(alpha: 0.4),
                fontSize: 16,
              ),
            ),
          ),

          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 20, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left column — fixed 104px
                    SizedBox(
                      width: 104,
                      child: Semantics(
                        label: l.streakSemanticDays(currentStreak),
                        excludeSemantics: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Icon(
                                      Icons.local_fire_department_rounded,
                                      color: _white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$currentStreak',
                                    style: AppTypography.displayLg.copyWith(
                                      color: _white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 60,
                                      height: 0.85,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l.streakDaysInRow,
                              style: AppTypography.labelSm.copyWith(
                                color: _white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Right column — fills remaining width
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              headline,
                              maxLines: 1,
                              style: AppTypography.labelSm.copyWith(
                                color: _white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtext,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.labelSm.copyWith(
                              color: _white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(height: 1, color: Colors.white.withAlpha(51)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _GraceMeter(total: gracesTotal, left: gracesLeft),
              ),
            ],
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
