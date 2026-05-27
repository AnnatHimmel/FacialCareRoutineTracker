import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/providers/root_providers.dart';
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
      appBar: AppBar(
        title: Text('עדכון הושלם', style: AppTypography.headlineMd),
      ),
      body: reconcileAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('שגיאה: $e')),
        data: (result) {
          if (!result.isUpdateDetected) {
            return Center(
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
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Data-intact confirmation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
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
                          color: AppColors.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Export offer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('לפני ההמשך:', style: AppTypography.headlineMd),
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
              const SizedBox(height: 16),

              // New products
              if (result.newProducts.isNotEmpty) ...[
                Text(
                  'מוצרים חדשים (${result.newProducts.length})',
                  style: AppTypography.headlineMd,
                ),
                const SizedBox(height: 8),
                Text(
                  'מוצרים אלה לא נבחרו עדיין — הוסף אותם בבחירת המוצרים',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final product in result.newProducts)
                  RoutineItemRow(
                    product: product,
                    isToggled: false,
                    onToggle: () {},
                  ),
                const SizedBox(height: 24),
              ],

              // Newly deprecated
              if (result.newlyDeprecatedSelected.isNotEmpty) ...[
                Text(
                  'מוצרים שאינם מומלצים עוד (${result.newlyDeprecatedSelected.length})',
                  style: AppTypography.headlineMd.copyWith(
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'מוצרים אלה נמצאים ברשימה שלך אך אינם מומלצים עוד',
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                for (final product in result.newlyDeprecatedSelected)
                  RoutineItemRow(
                    product: product,
                    isToggled: true,
                    onToggle: () {},
                  ),
                const SizedBox(height: 24),
              ],

              // Acknowledge button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _acknowledging
                      ? null
                      : () => _acknowledge(result.currentContentVersion),
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
