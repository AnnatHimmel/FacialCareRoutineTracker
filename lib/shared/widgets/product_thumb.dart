import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../providers/root_providers.dart';

final userPhotoProvider = FutureProvider.family<Uint8List?, String>(
  (ref, key) => ref.watch(photoRepositoryProvider).readPhoto(key),
);

class ProductThumb extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = imageAsset;

    Widget child;
    if (asset != null && asset.startsWith('user_photo:')) {
      final key = asset.substring('user_photo:'.length);
      final photoAsync = ref.watch(userPhotoProvider(key));
      child = photoAsync.when(
        data: (bytes) => bytes != null
            ? Image.memory(bytes, width: size, height: size, fit: BoxFit.cover)
            : _fallback(),
        loading: _fallback,
        error: (_, _) => _fallback(),
      );
    } else if (asset != null) {
      child = Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      child = _fallback();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (asset != null) ? AppColors.surfaceContainer : AppColors.primaryFixed,
        boxShadow: AppColors.glowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
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
