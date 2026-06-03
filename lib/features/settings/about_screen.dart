import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_list_manifest.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(showBack: true),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.genericError(e))),
        data: (master) {
          final manifest = master.manifest;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              GlowCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGlowGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.glow,
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        size: 40,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.appName,
                      style: AppTypography.headlineLg.copyWith(
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l.aboutVersionLabel(manifest.appVersion),
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.only(bottom: 12, right: 4),
                child: Text(
                  l.aboutChangelog,
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

              for (final entry in manifest.changelog) ...[
                _ChangelogCard(entry: entry),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    Text(
                      l.aboutDisclaimer,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => launchUrl(
                        Uri.parse(
                          'https://annathimmel.github.io/FacialCareRoutineTracker/privacy.html',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        l.aboutPrivacyPolicyLink,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final ChangelogEntry entry;

  const _ChangelogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.contentVersion,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          for (final change in entry.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•',
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      change,
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
