import 'package:flutter/material.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/entities/master_product.dart';
import 'fixed_slot_chip.dart';
import 'product_thumb.dart';

/// Routine row — used on S1 (select), S4/S7 (done), and S3 (drag-to-reorder).
class RoutineItemRow extends StatefulWidget {
  final MasterProduct product;
  final bool isToggled;
  final VoidCallback onToggle;
  final bool isOwnershipContext;
  final bool isDraggable;
  final bool hasConflict;
  final VoidCallback? onConflictTap;
  final String? subtitle;
  final bool isHintTarget;

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
    this.isHintTarget = false,
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

  bool get _isFlexible =>
      widget.product.morningConfig != null &&
      widget.product.eveningConfig != null;

  bool get _showSlotChip =>
      widget.subtitle == null && !_isFlexible;

  String? _subtitle(AppLocalizations l) {
    if (widget.subtitle != null) return widget.subtitle;
    if (_isFlexible) return l.routineItemFlexibleSlots;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final product = widget.product;
    final checkedDone = _isDoneChecked;
    final subtitle = _subtitle(l);

    final name = Text(
      product.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: _isLikelyLatin(product.name) ? TextAlign.end : TextAlign.start,
      textDirection:
          _isLikelyLatin(product.name) ? TextDirection.ltr : TextDirection.rtl,
      style: AppTypography.bodyMd.copyWith(
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: checkedDone
            ? AppColors.onSurfaceVariant.withAlpha(178)
            : AppColors.onSurface,
        decoration: checkedDone ? TextDecoration.lineThrough : null,
        decorationColor: checkedDone
            ? AppColors.onSurfaceVariant.withAlpha(178)
            : null,
        decorationThickness: 1,
      ),
    );

    final rowContent = Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
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

              _buildThumbnail(product.imageAsset, checkedDone),
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
                          _deprecatedPill(l),
                        ],
                      ],
                    ),
                    if (_isDoneVariant && product.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        product.brand!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: AppTypography.labelSm.copyWith(
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          fontSize: 11.5,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ] else if (!_isDoneVariant && _showSlotChip) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: FixedSlotChip(product: product),
                      ),
                    ] else if (!_isDoneVariant && subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
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
              const SizedBox(width: 4),

              if (widget.hasConflict && !widget.isDraggable)
                _conflictButton(),

              if (_isDoneVariant && !widget.isDraggable)
                _chevronButton()
              else if (widget.isOwnershipContext)
                _selectActionButton(),
            ],
          ),
          _buildExpandedSection(product, l),
        ],
      ),
    );

    return Semantics(
      label: '${product.name}, ${widget.isToggled ? l.routineItemDone : l.routineItemNotDone}',
      button: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: checkedDone
              ? AppColors.primaryFixed.withAlpha(115)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(_expanded ? 26 : 9999),
          boxShadow: checkedDone ? null : AppColors.glowSm,
          border: Border.all(
            color: (widget.isHintTarget && !checkedDone)
                ? AppColors.primary.withValues(alpha: 0.4)
                : (checkedDone
                    ? Colors.transparent
                    : AppColors.outlineVariant.withAlpha(51)),
            width: (widget.isHintTarget && !checkedDone) ? 2.0 : 1.0,
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: _isDoneVariant
              ? InkWell(
                  onTap: widget.onToggle,
                  borderRadius:
                      BorderRadius.circular(_expanded ? 26 : 9999),
                  child: rowContent,
                )
              : rowContent,
        ),
      ),
    );
  }

  Widget _buildThumbnail(String? imageAsset, bool checkedDone) {
    final base = _ThumbnailWithBadge(imageAsset: imageAsset, isDone: checkedDone);
    if (!widget.isHintTarget || checkedDone) return base;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        base,
        const Positioned(
          top: -8,
          left: -8,
          right: -8,
          bottom: -8,
          child: IgnorePointer(child: _PingOverlay()),
        ),
        PositionedDirectional(
          bottom: -2,
          start: -2,
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
              Icons.touch_app_rounded,
              color: Colors.white,
              size: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedSection(MasterProduct product, AppLocalizations l) {
    final commentText = product.localizedComment(l.localeName);
    final hasComment = commentText.isNotEmpty;
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState:
          _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(width: double.infinity),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 1, color: AppColors.outlineVariant),
            const SizedBox(height: 10),
            if (hasComment)
              Text(
                commentText,
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
                  l.routineItemDeprecatedWarning,
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

  Widget _deprecatedPill(AppLocalizations l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorContainer,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(l.routineItemDeprecatedPill,
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

  Widget _chevronButton() => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          width: 40,
          height: 40,
          margin: const EdgeInsetsDirectional.only(end: 8),
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: _expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(
              Icons.expand_more_rounded,
              color: AppColors.onSurfaceVariant,
              size: 22,
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
          PositionedDirectional(
            bottom: -2,
            start: -2,
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

// Self-contained animated ping ring. Mounted only while the hint is active;
// disposal stops the ticker cleanly.
class _PingOverlay extends StatefulWidget {
  const _PingOverlay();

  @override
  State<_PingOverlay> createState() => _PingOverlayState();
}

class _PingOverlayState extends State<_PingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: _PingRingPainter(progress: _ctrl.value, color: AppColors.primary),
      ),
    );
  }
}

class _PingRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _PingRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Canvas is ~68×68 (thumbnail 52px + 8px bleed on each side).
    // Thumbnail edge sits at radius 26 from center; ring expands outward from there.
    final center = Offset(size.width / 2, size.height / 2);
    final t = Curves.easeOut.transform(progress);
    final radius = 26.0 + 16.0 * t;
    final opacity = (1.0 - t) * 0.5;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(_PingRingPainter old) => old.progress != progress;
}
