import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/l10n/generated/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class GlassNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const GlassNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Frosted bottom navigation with a peach "pill" highlight behind the active
/// destination. Reference: `components.jsx` `BottomNav` — glass surface, top
/// border in `primary-fixed/30`, active item `bg-primary-fixed/60 text-primary`.
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurSigma,
          sigmaY: AppColors.glassBlurSigma,
        ),
        child: Container(
          padding: EdgeInsets.only(top: 8, bottom: 8 + bottomInset, left: 8, right: 8),
          decoration: const BoxDecoration(
            color: AppColors.glassFill,
            border: Border(
              top: BorderSide(color: AppColors.primaryFixed, width: 1),
            ),
            boxShadow: AppColors.navGlow,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavButton(
                  item: items[i],
                  active: i == currentIndex,
                  onTap: () => onDestinationSelected(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The standard 4-item app navigation bar. Owns the canonical items list so all
/// call sites stay in sync. Pass [currentIndex] = -1 for screens outside the
/// main shell (setup flow).
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _routes = ['/today', '/products', '/calendar', '/settings'];

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  /// Convenience constructor for setup screens: no active tab, navigates via
  /// context.go so the shell branch state is not required.
  static Widget setup(BuildContext context) => AppBottomNav(
        currentIndex: -1,
        onDestinationSelected: (i) {
          if (i < _routes.length) context.go(_routes[i]);
        },
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GlassBottomNav(
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      items: [
        GlassNavItem(
          icon: Icons.wb_sunny_outlined,
          selectedIcon: Icons.wb_sunny_rounded,
          label: l.navToday,
        ),
        GlassNavItem(
          icon: Icons.spa_outlined,
          selectedIcon: Icons.spa_rounded,
          label: l.navProducts,
        ),
        GlassNavItem(
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today_rounded,
          label: l.navCalendar,
        ),
        GlassNavItem(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings_rounded,
          label: l.navSettings,
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final GlassNavItem item;
  final bool active;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.onSurfaceVariant;
    return Semantics(
      selected: active,
      button: true,
      label: item.label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryFixed : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? item.selectedIcon : item.icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaler: TextScaler.noScaling,
                style: AppTypography.labelSm.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
