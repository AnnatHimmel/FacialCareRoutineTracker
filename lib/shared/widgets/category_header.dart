import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'radiant_chips.dart';

class CategoryHeader extends StatelessWidget {
  final String categoryName;
  final int? count;

  /// Override the suffix; if null uses the l10n default ("פריטים").
  final String? countSuffix;

  const CategoryHeader({
    super.key,
    required this.categoryName,
    this.count,
    this.countSuffix,
  });

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final suffix = countSuffix ?? l.categoryItemsSuffix;

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
          if (count != null) CountChip('$count $suffix'),
        ],
      ),
    );
  }
}
