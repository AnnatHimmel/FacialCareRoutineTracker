import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'radiant_chips.dart';

/// Category section header: peach headline on the right, optional lemon count
/// chip on the left (RTL). Reference: curator_1 — `text-primary` headline +
/// `bg-secondary-container` count pill, `justify-between`.
///
/// Latin category names (e.g. "Serums") render LTR so they read correctly
/// inside the RTL layout.
class CategoryHeader extends StatelessWidget {
  final String categoryName;

  /// Optional item count rendered as a lemon pill (e.g. "4 פריטים").
  final int? count;
  final String countSuffix;

  const CategoryHeader({
    super.key,
    required this.categoryName,
    this.count,
    this.countSuffix = 'פריטים',
  });

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context) {
    final title = Text(
      categoryName,
      textDirection: _isLikelyLatin(categoryName)
          ? TextDirection.ltr
          : TextDirection.rtl,
      style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Row(
        children: [
          Flexible(child: title),
          const Spacer(),
          if (count != null) CountChip('$count $countSuffix'),
        ],
      ),
    );
  }
}
