import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/journal/skin_log_entry_screen.dart';
import '../../features/setup/order_customization_screen.dart';
import '../../features/setup/schedule_setup_screen.dart';

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
    );
  }
}

// ── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AppEntryPoint(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        onFinish: () => context.go('/today'),
      ),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) =>
          _ShellScaffold(navigationShell: shell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/today',
              builder: (context, state) => const DailyHomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/products',
              builder: (context, state) =>
                  const ProductSelectionScreen(isTabDestination: true),
              routes: [
                // Step 3 of the products flow — schedule setup.
                // Nested inside the shell branch so the bottom nav stays visible.
                GoRoute(
                  path: 'schedule',
                  builder: (context, state) =>
                      const ScheduleSetupScreen(fromProducts: true),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/calendar',
              builder: (context, state) => const CalendarScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // Setup flow
    GoRoute(
      path: '/setup/selection',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return ProductSelectionScreen(fromSetup: fromSetup);
      },
    ),
    GoRoute(
      path: '/setup/schedule',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return ScheduleSetupScreen(fromSetup: fromSetup);
      },
    ),
    GoRoute(
      path: '/setup/order',
      builder: (context, state) {
        final fromSetup = state.uri.queryParameters['from'] == 'setup';
        return OrderCustomizationScreen(fromSetup: fromSetup);
      },
    ),

    // Skin journal (accessible from calendar)
    GoRoute(
      path: '/journal',
      builder: (context, state) => const SkinJournalScreen(),
    ),

    // Detail routes
    GoRoute(
      path: '/day/:date',
      builder: (context, state) => DayDetailScreen(
        date: state.pathParameters['date']!,
      ),
    ),
    GoRoute(
      path: '/skin-log/:date',
      builder: (context, state) => SkinLogEntryScreen(
        date: state.pathParameters['date']!,
      ),
    ),

    // Data management
    GoRoute(
      path: '/export-import',
      builder: (context, state) => const ExportImportScreen(),
    ),
    GoRoute(
      path: '/export-import/merge',
      builder: (context, state) => const MergeConflictScreen(),
    ),

    // Info
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    GoRoute(
      path: '/update-review',
      builder: (context, state) => const UpdateReviewScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
  ],
);
