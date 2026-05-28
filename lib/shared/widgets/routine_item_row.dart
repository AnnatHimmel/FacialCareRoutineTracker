import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import 'product_thumb.dart';

/// Routine row — a white pill holding a circular product thumbnail, the product
/// name + subtitle, and a circular action button. Used on S1 (select / "I own
/// this"), S4 & S7 (done / "I did this"), and S3 (drag-to-reorder).
///
/// Reference: `components.jsx` `RoutineRow`. Variant is derived from the
/// existing flags so all call sites keep their current API:
///   • [isDraggable] → drag handle, no toggle button
///   • [isOwnershipContext] → "select" (+ / ✓) button
///   • otherwise → "done" (check) button; checked → peach fill + strikethrough
class RoutineItemRow extends StatefulWidget {
  final MasterProduct product;
  final bool isToggled;
  final VoidCallback onToggle;
  final bool isOwnershipContext;
  final bool isDraggable;
  final bool hasConflict;
  final VoidCallback? onConflictTap;

  /// Optional secondary line. Defaults to the product comment.
  final String? subtitle;

  const RoutineItemRow({
    super.key,
    required this.product,
    required this.isToggled,
    required this.onToggle,
    this.isOwnershipContext = false,
    this.isDraggable = false,
    this.hasConflict = false,
    this.onConflictTap,
    this.subtitle,
  });

  @override
  State<RoutineItemRow> createState() => _RoutineItemRowState();
}

class _RoutineItemRowState extends State<RoutineItemRow> {
  bool _expanded = false;

  static bool _isLikelyLatin(String s) => s.codeUnits.every((c) => c < 128);

  bool get _isDoneChecked =>
      !widget.isOwnershipContext && !widget.isDraggable && widget.isToggled;

  String? get _subtitle {
    if (widget.subtitle != null) return widget.subtitle;
    final c = widget.product.comment;
    if (c != null && c.trim().isNotEmpty) return c;
    return _amPmLabel();
  }

  String? _amPmLabel() {
    final am = widget.product.configForSlot(Slot.morning) != null;
    final pm = widget.product.configForSlot(Slot.evening) != null;
    if (am && pm) return 'בוקר • ערב';
    if (am) return 'בוקר';
    if (pm) return 'ערב';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final checkedDone = _isDoneChecked;

    final nameColor = checkedDone
        ? AppColors.onSurfaceVariant
        : AppColors.onSurface;

    final name = Text(
      product.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
      textDirection:
          _isLikelyLatin(product.name) ? TextDirection.ltr : TextDirection.rtl,
      style: AppTypography.bodyMd.copyWith(
        fontWeight: FontWeight.w700,
        color: nameColor,
        decoration: checkedDone ? TextDecoration.lineThrough : null,
        decorationColor: AppColors.onSurfaceVariant,
      ),
    );

    final subtitle = _subtitle;

    return Semantics(
      label: '${product.name}, ${widget.isToggled ? "נבחר" : "לא נבחר"}',
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: checkedDone
              ? AppColors.primaryFixed
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(_expanded ? 24 : 9999),
          boxShadow: AppColors.glowSm,
          border: checkedDone
              ? null
              : Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(_expanded ? 24 : 9999),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      if (widget.isDraggable)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.drag_indicator,
                              color: AppColors.outline, size: 22),
                        ),
                      ProductThumb(imageAsset: product.imageAsset, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(child: name),
                                if (product.isDeprecated) ...[
                                  const SizedBox(width: 6),
                                  _deprecatedPill(),
                                ],
                              ],
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: AppTypography.labelSm.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.hasConflict && !widget.isDraggable)
                        _conflictButton(),
                      if (!widget.isDraggable) _actionButton(checkedDone),
                    ],
                  ),
                  _buildExpanded(product),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded(MasterProduct product) {
    final hasComment = product.comment != null && product.comment!.isNotEmpty;
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 10),
            if (hasComment)
              Text(
                product.comment!,
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onSurfaceVariant),
              ),
            if (product.isDeprecated) ...[
              if (hasComment) const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'מוצר זה אינו מומלץ עוד',
                  style:
                      AppTypography.labelMd.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _deprecatedPill() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text('לא מומלץ',
            style: AppTypography.labelSm.copyWith(color: AppColors.error)),
      );

  Widget _conflictButton() => GestureDetector(
        onTap: widget.onConflictTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.warning_amber_rounded,
              color: AppColors.tertiary, size: 20),
        ),
      );

  Widget _actionButton(bool checkedDone) {
    final select = widget.isOwnershipContext;
    final checked = widget.isToggled;

    late final Color bg;
    late final Color fg;
    late final IconData icon;
    Border? border;

    if (select) {
      icon = checked ? Icons.check : Icons.add;
      if (checked) {
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
      } else {
        bg = AppColors.primaryFixed;
        fg = AppColors.primary;
      }
    } else {
      icon = Icons.check;
      if (checked) {
        bg = AppColors.primary;
        fg = AppColors.onPrimary;
      } else {
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = Border.all(color: AppColors.primary, width: 2);
      }
    }

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: border,
          boxShadow: checked ? AppColors.glowSm : null,
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}
