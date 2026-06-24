import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/repositories/settings_repository.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';
import 'package:skincare_tracker/shared/widgets/backup_reminder_banner.dart';

class _FakeSettings implements SettingsRepository {
  final String? lastExportDate;
  _FakeSettings({this.lastExportDate});

  @override
  Future<String?> getLastExportDate() async => lastExportDate;
  @override
  Future<void> setLastExportDate(String d) async {}
  @override
  Future<String?> getLastKnownMasterVersion() async => null;
  @override
  Future<void> setLastKnownMasterVersion(String v) async {}
  @override
  Future<int> getUserSchemaVersion() async => 1;
  @override
  Future<void> setUserSchemaVersion(int v) async {}
  @override
  Future<int> getLongestStreak() async => 0;
  @override
  Future<void> setLongestStreak(int s) async {}
  @override
  Future<bool> getOnboardingCompleted() async => true;
  @override
  Future<void> setOnboardingCompleted(bool v) async {}
  @override Future<String?> getUserName() async => null;
  @override Future<void> setUserName(String name) async {}
  @override Future<String?> getUserGender() async => null;
  @override Future<void> setUserGender(String gender) async {}
  @override Future<void> clearUserProfile() async {}
  @override Future<String> getRoutineViewMode() async => 'list';
  @override Future<void> setRoutineViewMode(String m) async {}
  @override Future<bool> getRoutineShowNames() async => false;
  @override Future<void> setRoutineShowNames(bool v) async {}
  @override Future<String> getAppLanguage() async => 'he';
  @override Future<void> setAppLanguage(String code) async {}
  @override Future<bool> getTapHintSeen() async => false;
  @override Future<void> setTapHintSeen(bool value) async {}
  @override Future<String?> getWeeklyPhotoReminderDismissedDate() async => null;
  @override Future<void> setWeeklyPhotoReminderDismissedDate(String isoDate) async {}
  @override Future<bool> getWeeklyReminderEnabled() async => true;
  @override Future<void> setWeeklyReminderEnabled(bool value) async {}
}

Widget _buildBanner({String? lastExportDate}) => ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(
          _FakeSettings(lastExportDate: lastExportDate),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('he', 'MA'),
        home: const Scaffold(body: BackupReminderBanner()),
      ),
    );

void main() {
  group('BackupReminderBanner', () {
    testWidgets('renders backup message when never exported', (tester) async {
      await tester.pumpWidget(_buildBanner(lastExportDate: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('גבה'), findsWidgets);
    });

    testWidgets('renders backup message when last export > 30 days ago',
        (tester) async {
      final old = DateTime.now()
          .subtract(const Duration(days: 31))
          .toIso8601String();
      await tester.pumpWidget(_buildBanner(lastExportDate: old));
      await tester.pumpAndSettle();

      expect(find.textContaining('גבה'), findsWidgets);
    });

    testWidgets('not shown when last export is recent (< 30 days)',
        (tester) async {
      final recent =
          DateTime.now().subtract(const Duration(days: 5)).toIso8601String();
      await tester.pumpWidget(_buildBanner(lastExportDate: recent));
      await tester.pumpAndSettle();

      expect(find.textContaining('גבה'), findsNothing);
    });

    testWidgets('dismiss button hides the banner', (tester) async {
      await tester.pumpWidget(_buildBanner(lastExportDate: null));
      await tester.pumpAndSettle();

      expect(find.byType(BackupReminderBanner), findsOneWidget);
      expect(find.textContaining('גבה'), findsWidgets);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      expect(find.textContaining('גבה'), findsNothing);
    });
  });
}
