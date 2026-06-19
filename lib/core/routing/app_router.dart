import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';
import '../../shared/widgets/glass_bottom_nav.dart';
import '../../features/app_entry.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/setup/product_selection_screen.dart';
import '../../features/home/daily_home_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/calendar/day_detail_screen.dart';
import '../../features/settings/about_screen.dart';
import '../../features/settings/export_import_screen.dart';
import '../../features/settings/merge_conflict_screen.dart';
import '../../features/settings/premium_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/update_review_screen.dart';
import '../../features/journal/skin_journal_screen.dart';
import '../../features/collection/collection_screen.dart';
import '../../features/collection/product_detail_screen.dart';
import '../../features/journal/skin_log_entry_screen.dart';
import '../../features/setup/add_product_flow_screen.dart';
import '../../features/setup/order_customization_screen.dart';
import '../../features/setup/schedule_setup_screen.dart';
import '../../features/home/week_glance_screen.dart';
import '../../features/welcome/welcome_screen.dart';

// ── Safe zone wrapper ────────────────────────────────────────────────────────

Widget _withSafeZone(Widget screen) => Container(
  color: AppColors.surface,
  child: SafeArea(
    left: false,
    top: false,
    right: false,
    bottom: true,
    child: screen,
  ),
);

// ── Shell with bottom nav ─────────────────────────────────────────────────────

class _ShellScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ShellScaffold({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => _withSafeZone(const AppEntryPoint()),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => _withSafeZone(OnboardingScreen(
        onFinish: () => context.go('/today'),
      )),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => _withSafeZone(const WelcomeScreen()),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          _ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => _withSafeZone(const DailyHomeScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/collection',
              builder: (context, state) => _withSafeZone(const CollectionScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/journal',
              builder: (context, state) => _withSafeZone(const SkinJournalScreen()),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => _withSafeZone(const SettingsScreen()),
            ),
          ],
        ),
      ],
    ),

    // Products — standalone (outside shell, no persistent nav)
    GoRoute(
      path: '/products',
      builder: (context, state) => _withSafeZone(const ProductSelectionScreen()),
      routes: [
        GoRoute(
          path: 'schedule',
          builder: (context, state) =>
              _withSafeZone(const ScheduleSetupScreen(fromProducts: true)),
        ),
      ],
    ),

    // Calendar — standalone (outside shell)
    GoRoute(
      path: '/calendar',
      builder: (context, state) => _withSafeZone(const CalendarScreen()),
    ),

    // Setup flow
    GoRoute(
      path: '/setup/selection',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return _withSafeZone(ProductSelectionScreen(fromSetup: fromSetup));
      },
    ),
    GoRoute(
      path: '/setup/schedule',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return _withSafeZone(ScheduleSetupScreen(fromSetup: fromSetup));
      },
    ),
    GoRoute(
      path: '/setup/order',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return _withSafeZone(OrderCustomizationScreen(fromSetup: fromSetup));
      },
    ),

    // Add product wizard (returning users)
    GoRoute(
      path: '/add-product',
      builder: (context, state) => _withSafeZone(const AddProductFlowScreen()),
    ),

    // Week at a glance
    GoRoute(
      path: '/week-glance',
      builder: (context, state) => _withSafeZone(const WeekGlanceScreen()),
    ),

    // Detail routes
    GoRoute(
      path: '/day/:date',
      builder: (context, state) => _withSafeZone(DayDetailScreen(
        date: state.pathParameters['date']!,
      )),
    ),
    GoRoute(
      path: '/skin-log/:date',
      builder: (context, state) => _withSafeZone(SkinLogEntryScreen(
        date: state.pathParameters['date']!,
      )),
    ),
    GoRoute(
      path: '/collection/:productId',
      builder: (context, state) => _withSafeZone(ProductDetailScreen(
        productId: state.pathParameters['productId']!,
      )),
    ),

    // Data management
    GoRoute(
      path: '/export-import',
      builder: (context, state) => _withSafeZone(const ExportImportScreen()),
    ),
    GoRoute(
      path: '/export-import/merge',
      builder: (context, state) => _withSafeZone(const MergeConflictScreen()),
    ),

    // Info
    GoRoute(
      path: '/about',
      builder: (context, state) => _withSafeZone(const AboutScreen()),
    ),
    GoRoute(
      path: '/update-review',
      builder: (context, state) => _withSafeZone(const UpdateReviewScreen()),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => _withSafeZone(const PremiumScreen()),
    ),
  ],
);
