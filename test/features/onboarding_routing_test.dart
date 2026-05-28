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
            path: '/onboarding',
            builder: (_, state) =>
                const Scaffold(body: Text('onboarding')),
          ),
        ],
      ));

      // Before any async tick — loading state is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
        'navigates to /onboarding when onboarding is not completed',
        (tester) async {
      await tester.pumpWidget(buildTestApp(
        onboardingCompleted: false,
        extraRoutes: [
          GoRoute(
            path: '/onboarding',
            builder: (_, state) =>
                const Scaffold(body: Text('onboarding')),
          ),
        ],
      ));

      await tester.pumpAndSettle();

      expect(find.text('onboarding'), findsOneWidget);
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

  // ── SettingsRepositoryImpl — user profile ───────────────────────────────────

  group('SettingsRepositoryImpl — user profile', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('getUserName() returns null when never set', () async {
      final repo = SettingsRepositoryImpl();
      expect(await repo.getUserName(), isNull);
    });

    test('setUserName() persists value and getUserName() returns it', () async {
      final repo = SettingsRepositoryImpl();
      await repo.setUserName('Anna');
      expect(await repo.getUserName(), equals('Anna'));
    });

    test('getUserGender() returns null when never set', () async {
      final repo = SettingsRepositoryImpl();
      expect(await repo.getUserGender(), isNull);
    });

    test('setUserGender() persists value and getUserGender() returns it',
        () async {
      final repo = SettingsRepositoryImpl();
      await repo.setUserGender('female');
      expect(await repo.getUserGender(), equals('female'));
    });

    test('userName persists across two SettingsRepositoryImpl instances',
        () async {
      final writer = SettingsRepositoryImpl();
      await writer.setUserName('Anna');
      final reader = SettingsRepositoryImpl();
      expect(await reader.getUserName(), equals('Anna'));
    });

    test('userGender persists across two SettingsRepositoryImpl instances',
        () async {
      final writer = SettingsRepositoryImpl();
      await writer.setUserGender('female');
      final reader = SettingsRepositoryImpl();
      expect(await reader.getUserGender(), equals('female'));
    });
  });

  // ── SettingsRepositoryImpl — clearUserProfile ───────────────────────────────

  group('SettingsRepositoryImpl — clearUserProfile', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
        'should_clear_all_user_profile_fields_when_clearUserProfile_is_called_on_populated_repo',
        () async {
      /// Given: a SettingsRepositoryImpl with onboarding_completed, user_name, and user_gender set
      final repo = SettingsRepositoryImpl();
      await repo.setOnboardingCompleted(true);
      await repo.setUserName('Anna');
      await repo.setUserGender('female');

      /// When: clearUserProfile is called
      await repo.clearUserProfile();

      /// Then: all three fields return their default/null values
      expect(await repo.getOnboardingCompleted(), isFalse);
      expect(await repo.getUserName(), isNull);
      expect(await repo.getUserGender(), isNull);
    });

    test(
        'should_not_error_when_clearUserProfile_is_called_on_empty_repo',
        () async {
      /// Given: a fresh SettingsRepositoryImpl with no values set
      final repo = SettingsRepositoryImpl();

      /// When: clearUserProfile is called on an empty repo
      /// Then: no error is thrown and defaults are still returned
      await repo.clearUserProfile();
      expect(await repo.getOnboardingCompleted(), isFalse);
      expect(await repo.getUserName(), isNull);
      expect(await repo.getUserGender(), isNull);
    });

    test(
        'should_allow_repopulation_after_clearUserProfile_is_called',
        () async {
      /// Given: a SettingsRepositoryImpl with values set and then cleared
      final repo = SettingsRepositoryImpl();
      await repo.setOnboardingCompleted(true);
      await repo.setUserName('Anna');
      await repo.setUserGender('female');
      await repo.clearUserProfile();

      /// When: new values are set after clearing
      await repo.setOnboardingCompleted(true);
      await repo.setUserName('Bob');
      await repo.setUserGender('male');

      /// Then: the new values persist and can be read
      expect(await repo.getOnboardingCompleted(), isTrue);
      expect(await repo.getUserName(), equals('Bob'));
      expect(await repo.getUserGender(), equals('male'));
    });
  });
}
