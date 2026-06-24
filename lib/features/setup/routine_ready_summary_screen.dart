import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/enums/slot.dart';
import '../../domain/services/routine_build_summary.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/radiant_chips.dart';

/// Terminal "routine is ready" summary screen shown after the setup flow
/// completes. Presents any auto-adjustments and advisories the resolver made,
/// then lets the user navigate to their live routine.
///
/// Pure presentation widget — no providers. Caller supplies [summary] and
/// [onContinue].
class RoutineReadySummaryScreen extends StatelessWidget {
  final RoutineBuildSummary summary;
  final VoidCallback onContinue;

  const RoutineReadySummaryScreen({
    super.key,
    required this.summary,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroCheck(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        l.routineReadyTitle,
                        style: AppTypography.headlineMd,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: Text(
                        l.routineReadyCounts(
                          summary.totalProducts,
                          summary.morningCount,
                          summary.eveningCount,
                        ),
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (summary.hasNothingToReport)
                      _NothingToReport(text: l.routineReadyNothingToReport)
                    else ...[
                      if (summary.changes.isNotEmpty) ...[
                        _SectionHeader(
                          label: l.routineReadyChangesHeader,
                          icon: Icons.auto_fix_high_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.routineReadyChangesExplainer,
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        for (final change in summary.changes)
                          _ChangeCard(change: change),
                      ],
                      if (summary.advisories.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _SectionHeader(
                          label: l.routineReadyAdvisoriesHeader,
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.routineReadyAdvisoriesExplainer,
                          style: AppTypography.labelMd
                              .copyWith(color: AppColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        for (final advisory in summary.advisories)
                          _AdvisoryCard(advisory: advisory),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: PrimaryButton(
                label: l.routineReadyCta,
                onTap: onContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _HeroCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: AppColors.secondaryContainer,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(color: AppColors.onSurface),
        ),
      ],
    );
  }
}

class _NothingToReport extends StatelessWidget {
  final String text;

  const _NothingToReport({required this.text});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Text(
        text,
        style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ChangeCard extends StatelessWidget {
  final RoutineChange change;

  const _ChangeCard({required this.change});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlowCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _kindIcon(change.kind),
              size: 22,
              color: AppColors.primary,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SlotBadge(slot: change.slot),
                  const SizedBox(height: 6),
                  Text(
                    change.localized('he'),
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _kindIcon(RoutineChangeKind kind) {
    switch (kind) {
      case RoutineChangeKind.movedDays:
        return Icons.swap_horiz;
      case RoutineChangeKind.reducedFrequency:
        return Icons.south_rounded;
      case RoutineChangeKind.movedSlot:
        return Icons.swap_vert;
    }
  }
}

class _AdvisoryCard extends StatelessWidget {
  final RoutineAdvisory advisory;

  const _AdvisoryCard({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlowCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 22,
              color: AppColors.tertiary,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SlotBadge(slot: advisory.slot),
                  const SizedBox(height: 6),
                  Text(
                    advisory.localized('he'),
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.onSurface),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotBadge extends StatelessWidget {
  final Slot slot;

  const _SlotBadge({required this.slot});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (slot == Slot.morning) {
      return TagChip(
        l.slotMorning,
        background: AppColors.primaryFixed,
        foreground: AppColors.primary,
        icon: Icons.wb_sunny_rounded,
      );
    } else {
      return TagChip(
        l.slotEvening,
        background: AppColors.tertiaryFixed,
        foreground: AppColors.tertiary,
        icon: Icons.dark_mode_rounded,
      );
    }
  }
}
