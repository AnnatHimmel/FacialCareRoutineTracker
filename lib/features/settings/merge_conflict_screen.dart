import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/services/export_import_service.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';

// This provider is set by ExportImportScreen before pushing to this route
final pendingMergeSessionProvider =
    StateProvider<MergeSession?>((ref) => null);

class MergeConflictScreen extends ConsumerStatefulWidget {
  const MergeConflictScreen({super.key});

  @override
  ConsumerState<MergeConflictScreen> createState() =>
      _MergeConflictScreenState();
}

class _MergeConflictScreenState
    extends ConsumerState<MergeConflictScreen> {
  int _currentIndex = 0;
  bool _completing = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pendingMergeSessionProvider);

    if (session == null) {
      return Scaffold(
        backgroundColor: AppColors.surface,
        appBar: const GlowAppBar(showBack: true),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: GlowCard(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 48,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text('אין נתונים למיזוג', style: AppTypography.bodyMd),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('חזור'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final conflicts = session.conflicts;
    final isDone = _currentIndex >= conflicts.length;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: GlowAppBar(
        showBack: true,
        action: isDone
            ? Padding(
                padding: const EdgeInsets.only(left: 8),
                child: FilledButton(
                  onPressed: _completing ? null : () => _complete(session),
                  child: Text(_completing ? 'ממזג...' : 'סיים'),
                ),
              )
            : null,
      ),
      body: isDone
          ? _buildDoneState(session)
          : _buildConflictCard(conflicts[_currentIndex], session),
    );
  }

  Widget _buildConflictCard(MergeConflict conflict, MergeSession session) {
    final total = session.conflicts.length;
    final current = _currentIndex + 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        // Progress card
        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: current / total,
                  backgroundColor: AppColors.surfaceContainer,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'התנגשות $current מתוך $total',
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'סוג: ${conflict.recordType}  ·  מזהה: ${conflict.recordId}',
                style: AppTypography.labelSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Title + options grouped in one GlowCard
        GlowCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'בחר איזו גרסה לשמור:',
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 16),

              // Keep local option
              _ConflictOption(
                label: 'שמור גרסה מקומית',
                description: 'המשך עם הנתונים הנוכחיים במכשיר',
                icon: Icons.phone_android,
                color: AppColors.secondary,
                onTap: () {
                  session.resolveConflict(
                    index: _currentIndex,
                    useArchive: false,
                  );
                  setState(() => _currentIndex++);
                },
              ),
              const SizedBox(height: 12),

              // Use archive option
              _ConflictOption(
                label: 'השתמש בגרסת הגיבוי',
                description: 'החלף עם הנתונים מקובץ הגיבוי',
                icon: Icons.backup,
                color: AppColors.primary,
                onTap: () {
                  session.resolveConflict(
                    index: _currentIndex,
                    useArchive: true,
                  );
                  setState(() => _currentIndex++);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneState(MergeSession session) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: GlowCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'כל ההתנגשויות נפתרו',
                style: AppTypography.headlineMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'לחץ על "סיים" להחלת המיזוג',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _complete(MergeSession session) async {
    setState(() => _completing = true);
    try {
      await session.complete();
      ref.read(pendingMergeSessionProvider.notifier).state = null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('המיזוג הושלם בהצלחה')),
      );
      context.go('/settings');
    } finally {
      if (mounted) setState(() => _completing = false);
    }
  }
}

class _ConflictOption extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConflictOption({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  textAlign: TextAlign.right,
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_left, color: color, size: 20),
        ],
      ),
    );
  }
}
