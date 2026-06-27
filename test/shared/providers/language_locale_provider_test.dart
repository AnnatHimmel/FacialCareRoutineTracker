import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

class _FakeSettings implements SettingsRepository {
  String language;
  String? gender;

  _FakeSettings({this.language = 'he', this.gender});

  @override Future<String> getAppLanguage() async => language;
  @override Future<void> setAppLanguage(String code) async => language = code;
  @override Future<String?> getUserGender() async => gender;
  @override Future<void> setUserGender(String gender) async => this.gender = gender;
  @override Future<String?> getLastExportDate() async => null;
  @override Future<void> setLastExportDate(String d) async {}
  @override Future<String?> getLastKnownMasterVersion() async => null;
  @override Future<void> setLastKnownMasterVersion(String v) async {}
  @override Future<int> getUserSchemaVersion() async => 1;
  @override Future<void> setUserSchemaVersion(int v) async {}
  @override Future<int> getLongestStreak() async => 0;
  @override Future<void> setLongestStreak(int s) async {}
  @override Future<bool> getOnboardingCompleted() async => false;
  @override Future<void> setOnboardingCompleted(bool v) async {}
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String n) async {}
  @override Future<void> clearUserProfile() async {}
  @override Future<String> getRoutineViewMode() async => 'list';
  @override Future<void> setRoutineViewMode(String m) async {}
  @override Future<bool> getRoutineShowNames() async => false;
  @override Future<void> setRoutineShowNames(bool v) async {}
  @override Future<bool> getTapHintSeen() async => false;
  @override Future<void> setTapHintSeen(bool value) async {}
  @override Future<String?> getWeeklyPhotoReminderDismissedDate() async => null;
  @override Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate) async {}
  @override Future<bool> getWeeklyReminderEnabled() async => true;
  @override Future<void> setWeeklyReminderEnabled(bool value) async {}
}

ProviderContainer _container(_FakeSettings settings) => ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
    );

void main() {
  group('appLocaleProvider language support', () {
    test('defaults to Hebrew locale when language is he', () async {
      final container = _container(_FakeSettings(language: 'he'));
      addTearDown(container.dispose);

      await container.read(localeSyncProvider.future);
      final locale = container.read(appLocaleProvider);
      expect(locale.languageCode, 'he');
    });

    test('returns English locale when language is en', () async {
      final container = _container(_FakeSettings(language: 'en'));
      addTearDown(container.dispose);

      await container.read(localeSyncProvider.future);
      final locale = container.read(appLocaleProvider);
      expect(locale.languageCode, 'en');
    });

    test('Hebrew feminine is Locale(he) with no country code', () async {
      final container =
          _container(_FakeSettings(language: 'he', gender: 'female'));
      addTearDown(container.dispose);

      await container.read(localeSyncProvider.future);
      final locale = container.read(appLocaleProvider);
      expect(locale.languageCode, 'he');
      expect(locale.countryCode, isNull);
    });

    test('Hebrew masculine is Locale(he, MA)', () async {
      final container =
          _container(_FakeSettings(language: 'he', gender: 'male'));
      addTearDown(container.dispose);

      await container.read(localeSyncProvider.future);
      final locale = container.read(appLocaleProvider);
      expect(locale.languageCode, 'he');
      expect(locale.countryCode, 'MA');
    });

    test('English ignores gender — always Locale(en)', () async {
      final container =
          _container(_FakeSettings(language: 'en', gender: 'male'));
      addTearDown(container.dispose);

      await container.read(localeSyncProvider.future);
      final locale = container.read(appLocaleProvider);
      expect(locale.languageCode, 'en');
      expect(locale.countryCode, isNull);
    });
  });
}
