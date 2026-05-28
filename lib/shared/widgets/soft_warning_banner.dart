import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SoftWarningBanner extends StatelessWidget {
  final String message;
  final String? muteLabel;
  final VoidCallback? onMute;
  final VoidCallback? onDismiss;
  final Widget? customAction;

  const SoftWarningBanner({
    super.key,
    required this.message,
    this.muteLabel = 'השתק',
    this.onMute,
    this.onDismiss,
    this.customAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tertiaryFixed,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.glowSm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.tertiary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onTertiaryContainer),
            ),
          ),
          ?customAction,
          if (onMute != null)
            TextButton(
              onPressed: onMute,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.tertiary,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: AppTypography.labelSm,
              ),
              child: Text(muteLabel ?? 'השתק'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.onSurfaceVariant,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
