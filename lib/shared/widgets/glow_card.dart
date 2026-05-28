import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/radiant_dew_theme.dart';

/// A white "pebble" surface floating on the cream background with a soft,
/// peach-tinted glow — the foundational container of the Radiant Dew look.
///
/// Reference: `components.jsx` `Card` (`bg-white rounded-[28px] shadow-glow`)
/// and the `.glow-card` rule. Use [pill] for fully-rounded row containers.
class GlowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final bool pill;
  final Color? color;
  final List<BoxShadow>? shadow;
  final Border? border;
  final VoidCallback? onTap;
  final double? width;

  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.radius,
    this.pill = false,
    this.color,
    this.shadow,
    this.border,
    this.onTap,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(
      pill ? RadiantDewTheme.pillRadius : (radius ?? RadiantDewTheme.cardRadius),
    );

    final Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surfaceContainerLowest,
        borderRadius: br,
        boxShadow: shadow ?? AppColors.glow,
        border: border,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: br,
        child: content,
      ),
    );
  }
}
