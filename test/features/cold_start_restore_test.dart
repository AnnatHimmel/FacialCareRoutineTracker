import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

/// Simulates a real cold start: settings are written (as onboarding/settings
/// would), the container is disposed, then a brand-new container reads the
/// values back through the ACTUAL providers the app uses on launch.
void main() {
  group('cold start restore via real providers', () {
    test('name, language(en) and onboarding flag survive a cold restart',
        () async {
      SharedPreferences.setMockInitialValues({});

      // ── Session 1: user completes onboarding / edits settings ──
      final c1 = ProviderContainer();
      final repo1 = c1.read(settingsRepositoryProvider);
      await repo1.setAppLanguage('en');
      await repo1.setUserName('Anna');
      await repo1.setUserGender('female');
      await repo1.setOnboardingCompleted(true);
      c1.dispose(); // app closed

      // ── Session 2: cold start — fresh container, fresh provider graph ──
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      expect(await c2.read(onboardingCompletedProvider.future), isTrue,
          reason: 'onboarding flag must be read back true on cold start');

      await c2.read(localeSyncProvider.future); // app.dart/app_entry await this
      expect(c2.read(appLocaleProvider), const Locale('en'),
          reason: 'saved English language must be restored to appLocaleProvider');

      expect(await c2.read(userNameProvider.future), equals('Anna'),
          reason: 'saved user name must be restored on cold start');
    });

    test('Hebrew male restores to he_MA on cold restart', () async {
      SharedPreferences.setMockInitialValues({});

      final c1 = ProviderContainer();
      final repo1 = c1.read(settingsRepositoryProvider);
      await repo1.setAppLanguage('he');
      await repo1.setUserName('דנה');
      await repo1.setUserGender('male');
      await repo1.setOnboardingCompleted(true);
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);

      await c2.read(localeSyncProvider.future);
      expect(c2.read(appLocaleProvider), const Locale('he', 'MA'));
      expect(await c2.read(userNameProvider.future), equals('דנה'));
      expect(await c2.read(onboardingCompletedProvider.future), isTrue);
    });
  });
}
