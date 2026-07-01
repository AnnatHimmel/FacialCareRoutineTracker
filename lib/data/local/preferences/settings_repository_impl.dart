import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyLastExportDate = 'last_export_date';
  static const _keyLastKnownMasterVersion = 'last_known_master_version';
  static const _keyUserSchemaVersion = 'user_schema_version';
  static const _keyLongestStreak = 'longest_streak';
  static const _keyOnboardingCompleted = 'onboarding_completed';
  static const _keyUserName = 'user_name';
  static const _keyUserGender = 'user_gender';
  static const _keyRoutineViewMode = 'routine_view_mode';
  static const _keyRoutineShowNames = 'routine_show_names';
  static const _keyAppLanguage = 'app_language';
  static const _keyTapHintSeen = 'hp_tapHintSeen';
  static const _keyWeeklyPhotoReminderDismissed =
      'weekly_photo_reminder_dismissed_date';
  static const _keyWeeklyReminderEnabled = 'weekly_photo_reminder_enabled';
  static const _keyKnownProductIds = 'known_product_ids';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> getLastExportDate() async =>
      (await _prefs).getString(_keyLastExportDate);

  @override
  Future<void> setLastExportDate(String isoDate) async =>
      (await _prefs).setString(_keyLastExportDate, isoDate);

  @override
  Future<String?> getLastKnownMasterVersion() async =>
      (await _prefs).getString(_keyLastKnownMasterVersion);

  @override
  Future<void> setLastKnownMasterVersion(String version) async =>
      (await _prefs).setString(_keyLastKnownMasterVersion, version);

  @override
  Future<int> getUserSchemaVersion() async =>
      (await _prefs).getInt(_keyUserSchemaVersion) ?? 1;

  @override
  Future<void> setUserSchemaVersion(int v) async =>
      (await _prefs).setInt(_keyUserSchemaVersion, v);

  @override
  Future<int> getLongestStreak() async =>
      (await _prefs).getInt(_keyLongestStreak) ?? 0;

  @override
  Future<void> setLongestStreak(int streak) async =>
      (await _prefs).setInt(_keyLongestStreak, streak);

  @override
  Future<bool> getOnboardingCompleted() async =>
      (await _prefs).getBool(_keyOnboardingCompleted) ?? false;

  @override
  Future<void> setOnboardingCompleted(bool value) async =>
      (await _prefs).setBool(_keyOnboardingCompleted, value);

  @override
  Future<String?> getUserName() async =>
      (await _prefs).getString(_keyUserName);

  @override
  Future<void> setUserName(String name) async =>
      (await _prefs).setString(_keyUserName, name);

  @override
  Future<String?> getUserGender() async =>
      (await _prefs).getString(_keyUserGender);

  @override
  Future<void> setUserGender(String gender) async =>
      (await _prefs).setString(_keyUserGender, gender);

  @override
  Future<void> clearUserProfile() async {
    final prefs = await _prefs;
    await prefs.remove(_keyOnboardingCompleted);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserGender);
  }

  @override
  Future<String> getRoutineViewMode() async =>
      (await _prefs).getString(_keyRoutineViewMode) ?? 'list';

  @override
  Future<void> setRoutineViewMode(String mode) async =>
      (await _prefs).setString(_keyRoutineViewMode, mode);

  @override
  Future<bool> getRoutineShowNames() async =>
      (await _prefs).getBool(_keyRoutineShowNames) ?? false;

  @override
  Future<void> setRoutineShowNames(bool value) async =>
      (await _prefs).setBool(_keyRoutineShowNames, value);

  @override
  Future<String> getAppLanguage() async =>
      (await _prefs).getString(_keyAppLanguage) ?? 'he';

  @override
  Future<void> setAppLanguage(String languageCode) async =>
      (await _prefs).setString(_keyAppLanguage, languageCode);

  @override
  Future<bool> getTapHintSeen() async =>
      (await _prefs).getBool(_keyTapHintSeen) ?? false;

  @override
  Future<void> setTapHintSeen(bool value) async =>
      (await _prefs).setBool(_keyTapHintSeen, value);

  @override
  Future<String?> getWeeklyPhotoReminderDismissedDate() async =>
      (await _prefs).getString(_keyWeeklyPhotoReminderDismissed);

  @override
  Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate) async =>
      (await _prefs).setString(_keyWeeklyPhotoReminderDismissed, isoDate);

  @override
  Future<bool> getWeeklyReminderEnabled() async =>
      (await _prefs).getBool(_keyWeeklyReminderEnabled) ?? true;

  @override
  Future<void> setWeeklyReminderEnabled(bool value) async =>
      (await _prefs).setBool(_keyWeeklyReminderEnabled, value);

  @override
  Future<Set<String>?> getKnownProductIds() async {
    final raw = (await _prefs).getString(_keyKnownProductIds);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
    return list.toSet();
  }

  @override
  Future<void> setKnownProductIds(Set<String> ids) async =>
      (await _prefs).setString(_keyKnownProductIds, jsonEncode(ids.toList()));
}
