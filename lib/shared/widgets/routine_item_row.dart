import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';

class RoutineItemRow extends StatefulWidget {
  final MasterProduct product;
  final bool isToggled;
  final VoidCallback onToggle;
  final bool isOwnershipContext;
  final bool isDraggable;
  final bool hasConflict;
  final VoidCallback? onConflictTap;

  const RoutineItemRow({
    super.key,
    required this.product,
    required this.isToggled,
    required this.onToggle,
    this.isOwnershipContext = false,
    this.isDraggable = false,
    this.hasConflict = false,
    this.onConflictTap,
  });

  @override
  State<RoutineItemRow> createState() => _RoutineItemRowState();
}

class _RoutineItemRowState extends State<RoutineItemRow> {
  bool _expanded = false;

  static bool _isLikelyLatin(String s) =>
      s.codeUnits.every((c) => c < 128);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final nameWidget = _isLikelyLatin(product.name)
        ? Directionality(
            textDirection: TextDirection.ltr,
            child: Text(product.name, style: AppTypography.bodyMd),
          )
        : Text(product.name, style: AppTypography.bodyMd);

    return Semantics(
      label: '${product.name}, ${widget.isToggled ? "נבחר" : "לא נבחר"}',
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Toggle or drag handle
                  if (widget.isDraggable)
                    const Icon(
                      Icons.drag_indicator,
                      color: AppColors.onSurfaceVariant,
                    )
                  else
                    _buildToggle(),
                  const SizedBox(width: 12),

                  // Product name — flexible
                  Expanded(child: nameWidget),

                  // Conflict icon
                  if (widget.hasConflict && !widget.isDraggable)
                    GestureDetector(
                      onTap: widget.onConflictTap,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.tertiary,
                          size: 20,
                        ),
                      ),
                    ),

                  // Deprecated badge
                  if (product.isDeprecated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'לא מומלץ',
                        style: AppTypography.labelSm
                            .copyWith(color: AppColors.error),
                      ),
                    ),

                  // Expand chevron
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image or placeholder
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: product.imageAsset != null
                            ? Image.asset(
                                product.imageAsset!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    _imagePlaceholder(),
                              )
                            : _imagePlaceholder(),
                      ),
                      const SizedBox(width: 12),
                      if (product.comment != null)
                        Expanded(
                          child: Text(
                            product.comment!,
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (product.isDeprecated) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'מוצר זה אינו מומלץ עוד',
                        style: AppTypography.labelMd
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    if (widget.isOwnershipContext) {
      return GestureDetector(
        onTap: widget.onToggle,
        child: Icon(
          widget.isToggled
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded,
          color:
              widget.isToggled ? AppColors.primary : AppColors.onSurfaceVariant,
          size: 24,
        ),
      );
    }
    return GestureDetector(
      onTap: widget.onToggle,
      child: Icon(
        widget.isToggled ? Icons.check_circle : Icons.radio_button_unchecked,
        color:
            widget.isToggled ? AppColors.primary : AppColors.onSurfaceVariant,
        size: 24,
      ),
    );
  }

  Widget _imagePlaceholder() => Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.onSurfaceVariant,
          size: 32,
        ),
      );
}
