import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// When set, replaces the default "The Glow Protocol" wordmark + sun icon.
  final String? title;

  const GlowAppBar({
    super.key,
    this.showBack = false,
    this.onBack,
    this.action,
    this.title,
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
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      centerTitle: true,
      automaticallyImplyLeading: false,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_forward_rounded),
              color: AppColors.primary,
              onPressed: onBack ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: AppTypography.headlineMd.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1,
                letterSpacing: -0.2,
              ),
            )
          : Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/app_icon_line_art.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 2),
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
                ],
              ),
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
