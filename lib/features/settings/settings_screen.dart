import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/backup_reminder_banner.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final masterAsync = ref.watch(masterContentProvider);
    final appVersion = masterAsync.valueOrNull?.manifest.appVersion ?? '—';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          GlowCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.settingsGreeting,
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l.settingsWelcome,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const BackupReminderBanner(),
          const SizedBox(height: 8),

          _SectionLabel(label: l.settingsSectionRoutine),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.reorder,
            label: l.settingsOrderProducts,
            subtitle: l.settingsOrderSubtitle,
            onTap: () => context.push('/setup/order'),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: l.settingsSectionData),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.cloud_download_outlined,
            label: l.exportTitle,
            subtitle: l.settingsExportSubtitle,
            onTap: () => context.push('/export-import'),
          ),

          const SizedBox(height: 24),
          _SectionLabel(label: l.settingsSectionInfo),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.info_outlined,
            label: l.settingsAbout,
            subtitle: l.settingsAboutSubtitle(appVersion),
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.system_update_outlined,
            label: l.settingsCheckUpdates,
            subtitle: l.settingsCheckUpdatesSubtitle,
            onTap: () => context.push('/update-review'),
          ),

          if (kIsWeb) ...[
            const SizedBox(height: 12),
            _SettingsRow(
              icon: Icons.workspace_premium_outlined,
              label: l.settingsPremium,
              subtitle: l.settingsPremiumSubtitle,
              onTap: () => context.push('/premium'),
            ),
          ],

          const SizedBox(height: 24),
          _SectionLabel(label: l.settingsSectionAccount),
          const SizedBox(height: 8),

          GlowCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shadow: AppColors.glowSm,
            onTap: () => _confirmLogout(context, ref, l),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout,
                    color: AppColors.error,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.settingsLogout,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        l.settingsLogoutSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

Future<void> _confirmLogout(
    BuildContext context, WidgetRef ref, AppLocalizations l) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.settingsLogout, textAlign: TextAlign.right),
      content: Text(
        l.settingsLogoutConfirmContent,
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l.settingsLogoutConfirmBtn,
              style: const TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await ref.read(settingsRepositoryProvider).clearUserProfile();
    ref.invalidate(onboardingCompletedProvider);
    if (context.mounted) context.go('/');
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shadow: AppColors.glowSm,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}
