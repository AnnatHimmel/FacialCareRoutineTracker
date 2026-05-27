import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterAsync = ref.watch(masterContentProvider);
    final appVersion = masterAsync.valueOrNull?.manifest.appVersion ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: Text('הגדרות', style: AppTypography.headlineMd),
      ),
      body: ListView(
        children: [
          // My Routine group
          const _SectionHeader(label: 'שגרת הטיפוח שלי'),
          _SettingsTile(
            icon: Icons.check_box_outlined,
            label: 'בחירת מוצרים',
            onTap: () => context.push('/setup/selection'),
          ),
          _SettingsTile(
            icon: Icons.calendar_today_outlined,
            label: 'תזמון מוצרים',
            onTap: () => context.push('/setup/schedule'),
          ),
          _SettingsTile(
            icon: Icons.sort,
            label: 'סדר מוצרים',
            onTap: () => context.push('/setup/order'),
          ),

          const Divider(),

          // Data group
          const _SectionHeader(label: 'נתונים'),
          _SettingsTile(
            icon: Icons.import_export_outlined,
            label: 'ייצוא / ייבוא',
            onTap: () => context.push('/export-import'),
          ),

          const Divider(),

          // Info group
          const _SectionHeader(label: 'מידע'),
          _SettingsTile(
            icon: Icons.info_outline,
            label: 'אודות',
            trailing: Text(
              appVersion,
              style: AppTypography.labelSm
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
            onTap: () => context.push('/about'),
          ),
          _SettingsTile(
            icon: Icons.system_update_outlined,
            label: 'בדוק עדכונים',
            onTap: () => context.push('/update-review'),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        label,
        style: AppTypography.labelMd.copyWith(
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.onSurface),
      title: Text(label, style: AppTypography.bodyMd),
      trailing: trailing ?? const Icon(Icons.chevron_left, color: AppColors.onSurfaceVariant),
      onTap: onTap,
    );
  }
}
