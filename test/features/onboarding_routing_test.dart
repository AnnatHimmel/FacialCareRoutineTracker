import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_tracker/data/local/preferences/settings_repository_impl.dart';
import 'package:skincare_tracker/features/app_entry.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

void main() {
  // ── SettingsRepositoryImpl unit tests ─────────────────────────────────────

  group('SettingsRepositoryImpl — onboarding flag', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('returns false when flag has never been set', () async {
      final repo = SettingsRepositoryImpl();
      expect(await repo.getOnboardingCompleted(), isFalse);
    });

    test('returns true after setOnboardingCompleted(true)', () async {
      final repo = SettingsRepositoryImpl();
      await repo.setOnboardingCompleted(true);
      expect(await repo.getOnboardingCompleted(), isTrue);
    });

    test('returns false after being set back to false', () async {
      final repo = SettingsRepositoryImpl();
      await repo.setOnboardingCompleted(true);
      await repo.setOnboardingCompleted(false);
      expect(await repo.getOnboardingCompleted(), isFalse);
    });

    test('two repo instances share the same persisted value', () async {
      final writer = SettingsRepositoryImpl();
      await writer.setOnboardingCompleted(true);
      final reader = SettingsRepositoryImpl();
      expect(await reader.getOnboardingCompleted(), isTrue);
    });
  });

  // ── AppEntryPoint widget tests ─────────────────────────────────────────────

  group('AppEntryPoint routing', () {
    Widget buildTestApp({
      required bool onboardingCompleted,
      required List<RouteBase> extraRoutes,
    }) {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, state) => const AppEntryPoint(),
          ),
          ...extraRoutes,
        ],
      );

      return ProviderScope(
        overrides: [
          onboardingCompletedProvider
              .overrideWith((_) async => onboardingCompleted),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('shows loading indicator before Future resolves',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: false,
        extraRoutes: [
          GoRoute(
            path: '/setup/selection',
            builder: (_, state) =>
                const Scaffold(body: Text('setup')),
          ),
        ],
      ));

      // Before any async tick — loading state is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'navigates to /setup/selection when onboarding is not completed',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: false,
        extraRoutes: [
          GoRoute(
            path: '/setup/selection',
            builder: (_, state) =>
                const Scaffold(body: Text('setup')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('setup'), findsOneWidget);
    });

    testWidgets('navigates to /today when onboarding is already completed',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: true,
        extraRoutes: [
          GoRoute(
            path: '/today',
            builder: (_, state) =>
                const Scaffold(body: Text('home')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('home'), findsOneWidget);
    });
  });
}
