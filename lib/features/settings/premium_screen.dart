import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// S15 — License Activation stub (Web-only, deferred post-v1.0).
class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('פרמיום', style: AppTypography.headlineMd),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.cloud_sync_outlined,
                  size: 40,
                  color: AppColors.onTertiaryContainer,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'גיבוי לענן — בקרוב',
                style: AppTypography.headlineLg,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                kIsWeb
                    ? 'הזן מפתח הפעלה כדי לאפשר גיבוי ושחזור אוטומטי בין מכשירים'
                    : 'תכונה זו זמינה בגרסת הווב בלבד',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (kIsWeb) ...[
                const SizedBox(height: 32),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'מפתח הפעלה',
                    hintStyle: AppTypography.bodyMd.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    suffixIcon: const ElevatedButton(
                      onPressed: null,
                      child: Text('הפעל'),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
