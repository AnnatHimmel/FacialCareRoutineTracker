import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Branded top app bar used on all screens.
///
/// Layout (RTL — start = right):
///   right: optional back button
///   center: "The Glow Protocol" wordmark + sun icon
///   left: optional action widget
class GlowAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final VoidCallback? onBack;

  /// Optional widget placed at the visual left (end) of the bar.
  /// Typically an [IconButton] for a settings / camera action.
  final Widget? action;

  const GlowAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.action,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'The Glow Protocol',
            style: AppTypography.headlineMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 8),
          const SizedBox(
            width: 24,
            height: 24,
            child: CustomPaint(
              painter: _SunLogoPainter(
                color: AppColors.primary,
                colorLight: AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      ),
      // Balance the leading area so the title stays truly centered.
      actions: [
        if (action != null) action! else if (showBack) const SizedBox(width: 48),
        const SizedBox(width: 4),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppColors.glassBlurSigma,
            sigmaY: AppColors.glassBlurSigma,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.glassFill,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primaryFixed,
                  width: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stylized sun: hollow ring + 12 alternating long/short pill rays.
/// Matches the `LeafLogo` SVG in components.jsx (viewBox 0 0 32 32).
class _SunLogoPainter extends CustomPainter {
  final Color color;
  final Color colorLight;

  const _SunLogoPainter({required this.color, required this.colorLight});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 32;
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Hollow ring center
    canvas.drawCircle(
      Offset(cx, cy),
      6.2 * scale,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.1 * scale
        ..color = color,
    );

    // 12 rays, alternating long/short
    for (int i = 0; i < 12; i++) {
      final angle = (-90 + i * 30) * (math.pi / 180);
      final isLong = i % 2 == 0;
      final r1 = (isLong ? 9.2 : 9.5) * scale;
      final r2 = (isLong ? 13.6 : 12.2) * scale;
      canvas.drawLine(
        Offset(cx + r1 * math.cos(angle), cy + r1 * math.sin(angle)),
        Offset(cx + r2 * math.cos(angle), cy + r2 * math.sin(angle)),
        Paint()
          ..color = isLong ? color : colorLight
          ..strokeWidth = 1.7 * scale
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_SunLogoPainter old) =>
      old.color != color || old.colorLight != colorLight;
}
