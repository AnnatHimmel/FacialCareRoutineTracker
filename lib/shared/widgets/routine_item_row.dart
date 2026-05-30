import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import '../../domain/enums/slot.dart';
import 'product_thumb.dart';

/// Routine row — used on S1 (select), S4/S7 (done), and S3 (drag-to-reorder).
///
/// Variants derived from flags:
///   • [isDraggable]          → drag handle, no toggle
///   • [isOwnershipContext]   → "select" (+/✓) action button on trailing side;
///                              tapping the row has no effect
///   • otherwise ("done")    → tapping the ROW toggles done; a chevron on the
///                              trailing side expands/collapses details; the
///                              thumbnail shows a small ✓ badge when done
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

  bool get _isDoneVariant =>
      !widget.isOwnershipContext && !widget.isDraggable;

  bool get _isDoneChecked => _isDoneVariant && widget.isToggled;

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

    final nameColor =
        checkedDone ? AppColors.onSurfaceVariant : AppColors.onSurface;

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

    final rowContent = Padding(
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

              // Thumbnail with optional done-badge overlay
              _ThumbnailWithBadge(
                imageAsset: product.imageAsset,
                isDone: checkedDone,
              ),
              const SizedBox(width: 12),

              // Name + subtitle
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
                          color: checkedDone
                              ? AppColors.onSurfaceVariant.withValues(alpha: 0.7)
                              : AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),

              // Trailing: conflict icon, then action/chevron
              if (widget.hasConflict && !widget.isDraggable)
                _conflictButton(),

              // Done variant: chevron to expand/collapse (tap stops propagation)
              if (_isDoneVariant && !widget.isDraggable)
                _chevronButton()
              else if (widget.isOwnershipContext)
                _selectActionButton(),
            ],
          ),
          _buildExpandedSection(product),
        ],
      ),
    );

    return Semantics(
      label: '${product.name}, ${widget.isToggled ? "בוצע" : "לא בוצע"}',
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
              : Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Material(
          type: MaterialType.transparency,
          // Done variant: tapping the row toggles done.
          // Select/drag variant: no row-level tap.
          child: _isDoneVariant
              ? InkWell(
                  onTap: widget.onToggle,
                  borderRadius:
                      BorderRadius.circular(_expanded ? 24 : 9999),
                  child: rowContent,
                )
              : rowContent,
        ),
      ),
    );
  }

  Widget _buildExpandedSection(MasterProduct product) {
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
                  style: AppTypography.labelMd
                      .copyWith(color: AppColors.error),
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
            style:
                AppTypography.labelSm.copyWith(color: AppColors.error)),
      );

  Widget _conflictButton() => GestureDetector(
        onTap: widget.onConflictTap,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Icon(Icons.warning_amber_rounded,
              color: AppColors.tertiary, size: 20),
        ),
      );

  // Chevron that expands/collapses details; stops propagation so it doesn't
  // also fire the row's onToggle.
  Widget _chevronButton() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              _expanded
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
              color: AppColors.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      );

  Widget _selectActionButton() {
    final checked = widget.isToggled;
    final Color bg =
        checked ? AppColors.primary : AppColors.primaryFixed;
    final Color fg =
        checked ? AppColors.onPrimary : AppColors.primary;
    final IconData icon = checked ? Icons.check : Icons.add;

    return GestureDetector(
      onTap: widget.onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: checked ? AppColors.glowSm : null,
        ),
        child: Icon(icon, color: fg, size: 20),
      ),
    );
  }
}

// ── Thumbnail with optional done checkmark badge ──────────────────────────────

class _ThumbnailWithBadge extends StatelessWidget {
  final String? imageAsset;
  final bool isDone;

  const _ThumbnailWithBadge({
    required this.imageAsset,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ProductThumb(imageAsset: imageAsset, size: 52),
        if (isDone)
          Positioned(
            // -start-0.5 -bottom-0.5 in RTL = visual bottom-right
            bottom: -2,
            right: -2,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: AppColors.soft,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
      ],
    );
  }
}
