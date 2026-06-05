import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/features/app_entry.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

Widget buildTestApp({
  required bool onboardingCompleted,
  required void Function() onStartupRan,
  required List<RouteBase> extraRoutes,
}) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AppEntryPoint()),
      ...extraRoutes,
    ],
  );

  return ProviderScope(
    overrides: [
      onboardingCompletedProvider.overrideWith((_) async => onboardingCompleted),
      // Override the startup provider to track whether it ran.
      // If AppEntryPoint doesn't watch silentStartupProvider, this body never
      // executes and the test correctly fails (RED).
      silentStartupProvider.overrideWith((_) async => onStartupRan()),
      // localeSyncProvider reads settingsRepository which isn't available in
      // tests — override it to complete immediately so pumpAndSettle doesn't
      // time out waiting for locale initialization.
      localeSyncProvider.overrideWith((_) async {}),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('silent startup reconciliation', () {
    testWidgets('silentStartupProvider runs before routing to /today',
        (tester) async {
      bool startupRan = false;

      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: true,
        onStartupRan: () => startupRan = true,
        extraRoutes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(startupRan, isTrue,
          reason: 'silentStartupProvider must run on every cold start');
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('silentStartupProvider runs before routing to /onboarding',
        (tester) async {
      bool startupRan = false;

      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: false,
        onStartupRan: () => startupRan = true,
        extraRoutes: [
          GoRoute(
            path: '/onboarding',
            builder: (context, state) => const Scaffold(body: Text('onboarding')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(startupRan, isTrue,
          reason: 'silentStartupProvider must run even on first launch');
      expect(find.text('onboarding'), findsOneWidget);
    });

    testWidgets('app routes to /today (not S14) regardless of startup result',
        (tester) async {
      // Even if reconciliation detects a content update, no S14 is shown.
      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: true,
        onStartupRan: () {}, // startup completes without navigating to S14
        extraRoutes: [
          GoRoute(
            path: '/today',
            builder: (context, state) => const Scaffold(body: Text('home')),
          ),
          GoRoute(
            path: '/update-review',
            builder: (context, state) => const Scaffold(body: Text('update-review')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
      expect(find.text('update-review'), findsNothing);
    });
  });
}
