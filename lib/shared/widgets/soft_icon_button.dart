import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A soft circular icon button matching the Radiant Dew aesthetic — rounded
/// surface-low fill, no hard Material ripple. Used for sheet header actions
/// such as close and edit. A null [onTap] renders a disabled (dimmed) button.
class SoftIconButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final String? tooltip;

  const SoftIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surfaceLow,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.outlineVariant, width: 1),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 20, color: iconColor),
      ),
    );
    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
