import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../providers/root_providers.dart';

/// Inline banner prompting the user to back up their data.
/// Shown when last export is overdue (> 30 days) or never done.
/// Dismissable per-session only.
class BackupReminderBanner extends ConsumerStatefulWidget {
  const BackupReminderBanner({super.key});

  @override
  ConsumerState<BackupReminderBanner> createState() =>
      _BackupReminderBannerState();
}

class _BackupReminderBannerState
    extends ConsumerState<BackupReminderBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final shouldShowAsync = ref.watch(_shouldShowBackupReminderProvider);
    return shouldShowAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (shouldShow) {
        if (!shouldShow) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondaryFixed,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.glowSm,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.backup_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'מומלץ לגבות את הנתונים שלך',
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.onSurface),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/export-import'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: AppTypography.labelSm,
                ),
                child: const Text('גבה עכשיו'),
              ),
              IconButton(
                onPressed: () => setState(() => _dismissed = true),
                icon: const Icon(Icons.close, size: 18),
                color: AppColors.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shows the banner if last export was never done or was > 30 days ago.
final _shouldShowBackupReminderProvider = FutureProvider<bool>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final lastExportDate = await settings.getLastExportDate();
  if (lastExportDate == null) return true;
  final lastExport = DateTime.tryParse(lastExportDate);
  if (lastExport == null) return true;
  return DateTime.now().difference(lastExport).inDays > 30;
});
