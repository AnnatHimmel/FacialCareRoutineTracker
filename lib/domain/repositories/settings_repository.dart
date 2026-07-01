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

  Future<String?> getUserName();
  Future<void> setUserName(String name);

  Future<String?> getUserGender();
  Future<void> setUserGender(String gender);

  Future<void> clearUserProfile();

  Future<String> getRoutineViewMode();
  Future<void> setRoutineViewMode(String mode);
  Future<bool> getRoutineShowNames();
  Future<void> setRoutineShowNames(bool value);

  Future<String> getAppLanguage();
  Future<void> setAppLanguage(String languageCode);

  Future<bool> getTapHintSeen();
  Future<void> setTapHintSeen(bool value);

  /// Effective date (YYYY-MM-DD) on which the weekly skin-tracking reminder was
  /// last dismissed via "אחר כך". Used to snooze the home-screen reminder card
  /// for the remainder of that day. Null if never dismissed.
  Future<String?> getWeeklyPhotoReminderDismissedDate();
  Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate);

  /// Master on/off switch for the weekly skin-tracking reminder. Defaults to
  /// true; set false by the card's "never show again" action or the Settings
  /// toggle. When false the reminder card never appears.
  Future<bool> getWeeklyReminderEnabled();
  Future<void> setWeeklyReminderEnabled(bool value);

  /// Snapshot of the master product IDs that were present the last time the
  /// user acknowledged a content update (or on first run). Used by
  /// [ReconciliationService] to detect newly-added products.
  /// Returns null if never set (first run).
  Future<Set<String>?> getKnownProductIds();
  Future<void> setKnownProductIds(Set<String> ids);
}
