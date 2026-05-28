import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// Circular product image with a soft glow. Falls back to a peach disc with a
/// rounded icon when no asset is available.
///
/// Reference: `components.jsx` `ProductThumb` (`rounded-full ... shadow-glow-sm`,
/// fallback `bg-primary-fixed/60`).
class ProductThumb extends StatelessWidget {
  final String? imageAsset;
  final double size;
  final IconData fallbackIcon;

  const ProductThumb({
    super.key,
    this.imageAsset,
    this.size = 52,
    this.fallbackIcon = Icons.spa_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: asset != null ? AppColors.surfaceContainer : AppColors.primaryFixed,
        boxShadow: AppColors.glowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: asset != null
          ? Image.asset(
              asset,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : _fallback(),
    );
  }

  Widget _fallback() => Center(
        child: Icon(
          fallbackIcon,
          size: size * 0.5,
          color: AppColors.onPrimaryFixedVariant,
        ),
      );
}
