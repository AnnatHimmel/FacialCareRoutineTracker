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
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'שלום',
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ברוכה הבאה ל־Glow Protocol',
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
          _SectionLabel(label: 'שגרת הטיפוח שלי'),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.tune_outlined,
            label: 'בחירת מוצרים',
            subtitle: 'בחרי את המוצרים שברשותך',
            onTap: () => context.push('/setup/selection'),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.calendar_today_outlined,
            label: 'תזמון מוצרים',
            subtitle: 'קבעי ימים ושעות לכל מוצר',
            onTap: () => context.push('/setup/schedule'),
          ),
          const SizedBox(height: 12),
          _SettingsRow(
            icon: Icons.reorder,
            label: 'סדר מוצרים',
            subtitle: 'גרורי לסידור אישי',
            onTap: () => context.push('/setup/order'),
          ),

          const SizedBox(height: 24),

          // ── Section: נתונים ───────────────────────────────────────────────
          _SectionLabel(label: 'נתונים'),
          const SizedBox(height: 8),

          _SettingsRow(
            icon: Icons.cloud_download_outlined,
            label: 'ייצוא / ייבוא',
            subtitle: 'גיבוי מקומי של הנתונים',
            onTap: () => context.push('/export-import'),
          ),

          const SizedBox(height: 24),

          // ── Section: מידע ─────────────────────────────────────────────────
          _SectionLabel(label: 'מידע'),
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

          const SizedBox(height: 32),
        ],
      ),
    );
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
