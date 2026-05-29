import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
import '../../shared/widgets/glow_app_bar.dart';
import '../../shared/widgets/glow_card.dart';
import '../../shared/widgets/routine_item_row.dart';

class UpdateReviewScreen extends ConsumerStatefulWidget {
  const UpdateReviewScreen({super.key});

  @override
  ConsumerState<UpdateReviewScreen> createState() =>
      _UpdateReviewScreenState();
}

class _UpdateReviewScreenState extends ConsumerState<UpdateReviewScreen> {
  bool _acknowledging = false;

  Future<void> _acknowledge(String version) async {
    setState(() => _acknowledging = true);
    try {
      final service = ref.read(reconciliationServiceProvider);
      await service.acknowledgeUpdate(version);
      if (mounted) context.go('/today');
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reconcileAsync = ref.watch(_reconcileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const GlowAppBar(showBack: true),
      body: reconcileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (result) {
          if (!result.isUpdateDetected) {
            return Center(
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
                      'הכל מעודכן',
                      style: AppTypography.headlineMd,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/today'),
                      child: const Text('חזור'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              // Data-intact confirmation
              GlowCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                color: AppColors.secondaryFixed,
                shadow: AppColors.glowSm,
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'הנתונים שלך שמורים ועדיין קיימים',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export offer
              GlowCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'לפני ההמשך:',
                      style: AppTypography.headlineMd,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/export-import'),
                      icon: const Icon(Icons.backup_outlined, size: 18),
                      label: const Text('גבה נתונים'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: AppTypography.labelSm,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // New products
              if (result.newProducts.isNotEmpty) ...[
                GlowCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'מוצרים חדשים (${result.newProducts.length})',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'מוצרים אלה לא נבחרו עדיין — הוסף אותם בבחירת המוצרים',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0; i < result.newProducts.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        RoutineItemRow(
                          product: result.newProducts[i],
                          isToggled: false,
                          onToggle: () {},
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Newly deprecated
              if (result.newlyDeprecatedSelected.isNotEmpty) ...[
                GlowCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'מוצרים שאינם מומלצים עוד (${result.newlyDeprecatedSelected.length})',
                        style: AppTypography.headlineMd.copyWith(
                          color: AppColors.error,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'מוצרים אלה נמצאים ברשימה שלך אך אינם מומלצים עוד',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      for (int i = 0;
                          i < result.newlyDeprecatedSelected.length;
                          i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        RoutineItemRow(
                          product: result.newlyDeprecatedSelected[i],
                          isToggled: true,
                          onToggle: () {},
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Acknowledge button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _acknowledging
                      ? null
                      : () => _acknowledge(result.currentContentVersion),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onPrimary,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _acknowledging
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('הבנתי, המשך'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}

final _reconcileProvider = FutureProvider(
  (ref) => ref.watch(reconciliationServiceProvider).reconcile(),
);
