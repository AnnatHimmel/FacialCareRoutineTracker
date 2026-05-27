abstract class SettingsRepository {
  Future<String?> getLastExportDate();
  Future<void> setLastExportDate(String isoDate);

  Future<String?> getLastKnownMasterVersion();
  Future<void> setLastKnownMasterVersion(String version);

  Future<int> getUserSchemaVersion();
  Future<void> setUserSchemaVersion(int v);

  Future<int> getLongestStreak();
  Future<void> setLongestStreak(int streak);

  Future<bool> getOnboardingCompleted();
  Future<void> setOnboardingCompleted(bool value);
}
