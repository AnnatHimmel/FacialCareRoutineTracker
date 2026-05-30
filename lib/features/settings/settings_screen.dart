import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final masterAsync = ref.watch(masterContentProvider);
    final appVersion = masterAsync.valueOrNull?.manifest.appVersion ?? '—';

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── Welcoming header card ──────────────────────────────────────────
          GlowCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'שלום',
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ברוכה הבאה ל־The Glow Protocol',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Backup reminder banner ─────────────────────────────────────────
          const BackupReminderBanner(),

          const SizedBox(height: 8),

          // ── Section: שגרת הטיפוח שלי ──────────────────────────────────────
          const _SectionLabel(label: 'שגרת הטיפוח שלי'),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.reorder,
            label: 'סדר מוצרים',
            subtitle: 'גרורי לסידור אישי',
            onTap: () => context.push('/setup/order'),
          ),

          const SizedBox(height: 24),

          // ── Section: נתונים ───────────────────────────────────────────────
          const _SectionLabel(label: 'נתונים'),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.cloud_download_outlined,
            label: 'ייצוא / ייבוא',
            subtitle: 'גיבוי מקומי של הנתונים',
            onTap: () => context.push('/export-import'),
          ),

          const SizedBox(height: 24),

          // ── Section: מידע ─────────────────────────────────────────────────
          const _SectionLabel(label: 'מידע'),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.info_outlined,
            label: 'אודות ומה חדש',
            subtitle: 'גרסה $appVersion • יומן שינויים',
            onTap: () => context.push('/about'),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.system_update_outlined,
            label: 'בדוק עדכונים',
            subtitle: 'בדיקת גרסה עדכנית',
            onTap: () => context.push('/update-review'),
          ),

          // ── Web-only: Premium / License (S15) ─────────────────────────────
          if (kIsWeb) ...[
            const SizedBox(height: 12),
            _SettingsRow(
              icon: Icons.workspace_premium_outlined,
              label: 'הפעלת רישיון',
              subtitle: 'גיבוי ושחזור בענן',
              onTap: () => context.push('/premium'),
            ),
          ],

          const SizedBox(height: 24),

          // ── Section: חשבון ────────────────────────────────────────────────
          const _SectionLabel(label: 'חשבון'),
          const SizedBox(height: 8),

          GlowCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shadow: AppColors.glowSm,
            onTap: () => _confirmLogout(context, ref),
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
                        'התנתקות',
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
                        'איפוס פרופיל וחזרה להתחלה',
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
                  Icons.chevron_left,
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

// ── Logout confirmation dialog ────────────────────────────────────────────────

Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('התנתקות', textAlign: TextAlign.right),
      content: const Text(
        'פעולה זו תאפס את הפרופיל שלך ותחזיר אותך למסך ההתחלה. הנתונים שלך יישמרו.',
        textAlign: TextAlign.right,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('ביטול'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('התנתקי', style: TextStyle(color: AppColors.error)),
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

// ── Section label ────────────────────────────────────────────────────────────

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

// ── Individual settings row (GlowCard pill with icon disc + chevron) ─────────

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
          // Circular peach icon disc (RTL first → visual right)
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

          // Title + subtitle (flex)
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

          // Trailing chevron (RTL last → visual left, navigation indicator)
          const Icon(
            Icons.chevron_left,
            color: AppColors.onSurfaceVariant,
            size: 22,
          ),
        ],
      ),
    );
  }
}
