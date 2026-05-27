import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_list_manifest.dart';
import '../../shared/providers/root_providers.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final masterAsync = ref.watch(masterContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('אודות', style: AppTypography.headlineMd),
      ),
      body: masterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (master) {
          final manifest = master.manifest;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // App identity
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.spa_outlined,
                        size: 40,
                        color: AppColors.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'מעקב שגרת טיפוח',
                      style: AppTypography.headlineLg,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'גרסת אפליקציה ${manifest.appVersion}',
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'גרסת תוכן ${manifest.contentVersion}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 24),

              // Changelog
              Text('מה חדש', style: AppTypography.headlineMd),
              const SizedBox(height: 16),

              for (final entry in manifest.changelog) ...[
                _ChangelogCard(entry: entry),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 32),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              entry.contentVersion,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final change in entry.changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: AppTypography.bodyMd
                        .copyWith(color: AppColors.primary),
                  ),
                  Expanded(
                    child: Text(change, style: AppTypography.bodyMd),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
