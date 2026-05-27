import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class CategoryHeader extends StatelessWidget {
  final String categoryName;

  const CategoryHeader({super.key, required this.categoryName});

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context) {
    final nameWidget = _isLikelyLatin(categoryName)
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              categoryName,
              style: AppTypography.labelMd
                  .copyWith(color: AppColors.onSurfaceVariant),
            ),
          )
        : Text(
            categoryName,
            style: AppTypography.labelMd
                .copyWith(color: AppColors.onSurfaceVariant),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          nameWidget,
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: AppColors.outlineVariant,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
