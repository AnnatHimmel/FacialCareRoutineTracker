import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
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

    final l = AppLocalizations.of(context)!;
    final shouldShowAsync = ref.watch(_backupReminderProvider);
    return shouldShowAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (info) {
        if (!info.shouldShow) return const SizedBox.shrink();

        final noteText = info.daysSince == null
            ? l.backupNeverBacked
            : l.backupDaysAgo(info.daysSince!);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
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
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l.backupReminderText,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      noteText,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => context.push('/export-import'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(9999),
                    boxShadow: AppColors.glowSm,
                  ),
                  child: Text(
                    l.backupNowAction,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => _dismissed = true),
                child: const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

({bool shouldShow, int? daysSince}) _calcBackupInfo(String? lastExportDate) {
  if (lastExportDate == null) return (shouldShow: true, daysSince: null);
  final lastExport = DateTime.tryParse(lastExportDate);
  if (lastExport == null) return (shouldShow: true, daysSince: null);
  final days = DateTime.now().difference(lastExport).inDays;
  return (shouldShow: days > 30, daysSince: days);
}

final _backupReminderProvider =
    FutureProvider<({bool shouldShow, int? daysSince})>((ref) async {
  final settings = ref.watch(settingsRepositoryProvider);
  final lastExportDate = await settings.getLastExportDate();
  return _calcBackupInfo(lastExportDate);
});
