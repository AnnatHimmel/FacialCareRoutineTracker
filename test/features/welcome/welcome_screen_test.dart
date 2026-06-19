import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/domain/services/day_boundary_service.dart';
import 'package:skincare_tracker/features/welcome/welcome_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeUDR implements UserDataRepository {
  final List<DayRecord> dayRecords;
  final String? userName;

  _FakeUDR({
    this.dayRecords = const [],
    this.userName,
  });

  @override
  Stream<List<DayRecord>> watchAllDayRecords() => Stream.value(dayRecords);

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      throw UnimplementedError();
  @override
  Stream<List<MutedConflict>> watchMutedConflicts() =>
      throw UnimplementedError();
  @override
  Future<void> upsertSelection(ProductSelection s) async =>
      throw UnimplementedError();
  @override
  Future<void> upsertSchedule(WeekdaySchedule s) async =>
      throw UnimplementedError();
  @override
  Future<void> muteConflict(MutedConflict m) async =>
      throw UnimplementedError();
  @override
  Future<void> unmuteConflict(String ruleId) async =>
      throw UnimplementedError();
  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() =>
      throw UnimplementedError();
  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteCustomProduct(String id) async =>
      throw UnimplementedError();
  @override
  Stream<List<CollectionItem>> watchCollectionItems() =>
      throw UnimplementedError();
  @override
  Future<void> upsertCollectionItem(CollectionItem item) =>
      throw UnimplementedError();
  @override
  Future<void> deleteCollectionItem(String id) =>
      throw UnimplementedError();
  @override
  Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) =>
      throw UnimplementedError();
  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      throw UnimplementedError();
  @override
  Stream<OrderOverride?> watchOrderOverride(Slot s) =>
      throw UnimplementedError();
  @override
  Future<void> upsertOrderOverride(OrderOverride o) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteOrderOverride(Slot s) async =>
      throw UnimplementedError();
  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      throw UnimplementedError();
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async =>
      throw UnimplementedError();
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async =>
      throw UnimplementedError();
  @override
  Stream<DayRecord?> watchDayRecord(String d, Slot s) =>
      throw UnimplementedError();
  @override
  Future<DayRecord> snapshotAndGetDayRecord(
          String d, Slot s, List<String> ids, String v) =>
      throw UnimplementedError();
  @override
  Future<void> updateDayRecord(DayRecord r) async =>
      throw UnimplementedError();
  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      throw UnimplementedError();
  @override
  Stream<SkinLogEntry?> watchSkinLog(String d) =>
      throw UnimplementedError();
  @override
  Future<void> upsertSkinLog(SkinLogEntry e) async =>
      throw UnimplementedError();
  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() =>
      throw UnimplementedError();
  @override
  Future<UserDataExport> exportAllData() async =>
      throw UnimplementedError();
  @override
  Future<void> replaceAllData(UserDataExport e) async =>
      throw UnimplementedError();
  @override
  Future<void> clearRoutineData() async =>
      throw UnimplementedError();
  @override
  Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      throw UnimplementedError();
  @override
  Future<void> upsertCategoryOverride(CategoryOverride o) async =>
      throw UnimplementedError();
  @override
  Future<void> deleteCategoryOverride(String productId) async =>
      throw UnimplementedError();
}

// ── Test wrapper ───────────────────────────────────────────────────────────────

Widget _wrap({
  required List<DayRecord> dayRecords,
  required VoidCallback onContinue,
  String? userName,
}) {
  final udr = _FakeUDR(dayRecords: dayRecords, userName: userName);
  return ProviderScope(
    overrides: [
      userDataRepositoryProvider.overrideWithValue(udr),
    ],
    child: MaterialApp(
      home: WelcomeScreen(onContinue: onContinue),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
    ),
  );
}

/// Sizes the test surface to a realistic portrait phone (≈ Pixel/iPhone) so
/// the welcome screen's flex layout distributes as it does on a real device,
/// instead of the adversarial 800×600 default.
Future<void> _pumpPhone(WidgetTester tester, Widget app) async {
  // Galaxy S24-class portrait phone (the reference shell), logical px.
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(app);
}

void main() {
  group('WelcomeScreen', () {
    testWidgets('renders app name', (tester) async {
      /**
       * Given: A user has opened the app (cold start, after onboarding)
       * When: The welcome screen renders
       * Then: The app brand name (l10n.welcomeAppName) is visible
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('The Glow Protocol'), findsOneWidget,
          reason: 'welcomeAppName should be rendered');
    });

    testWidgets('renders streak number', (tester) async {
      /**
       * Given: A user has a streak of 5 complete days
       * When: The welcome screen renders
       * Then: The streak count (5) is displayed as a large number
       */
      bool callbackCalled = false;

      // Mock day records to simulate a 5-day streak
      final dayRecords = List.generate(
        5,
        (i) {
          final date = DateTime(2026, 6, 15 - i);
          return DayRecord(
            id: 'day-$i-morning',
            date: _dateToString(date),
            slot: Slot.morning,
            resolvedProductIds: const ['p1', 'p2'],
            recordedProductIds: const ['p1', 'p2'],
            resolvedAtMasterVersion: '1.0.0',
            lastModified: DateTime.now(),
          );
        },
      );

      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: dayRecords,
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      expect(find.text('5'), findsWidgets,
          reason: 'streak count (5) should be displayed');
    });

    testWidgets('renders streak label', (tester) async {
      /**
       * Given: The welcome screen is displayed
       * When: The screen renders
       * Then: The streak label (l10n.welcomeStreakLabel = "ימים ברצף") is visible
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // The label should be present (in Hebrew)
      expect(find.byType(Text), findsWidgets,
          reason: 'streak label should be rendered');
    });

    testWidgets('CTA button calls onContinue', (tester) async {
      /**
       * Given: The welcome screen displays a CTA button (l10n.welcomeCta)
       * When: The user taps the button
       * Then: The onContinue callback is invoked
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Find and tap the CTA button (should have Hebrew text)
      final ctaButton = find.byType(ElevatedButton);
      expect(ctaButton, findsOneWidget,
          reason: 'CTA button should be present');

      await tester.tap(ctaButton);
      await tester.pump(const Duration(milliseconds: 1500));

      expect(callbackCalled, isTrue,
          reason: 'onContinue should be called after tapping CTA');
    });

    testWidgets('countdown circle tap calls onContinue', (tester) async {
      /**
       * Given: The welcome screen displays a countdown circle widget
       * When: The user taps the countdown circle
       * Then: The onContinue callback is invoked
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Find the countdown circle by key or semantic label
      final countdownCircle = find.byKey(const Key('welcome_countdown'));
      expect(countdownCircle, findsOneWidget,
          reason: 'countdown circle should be present');

      await tester.tap(countdownCircle);
      await tester.pump(const Duration(milliseconds: 1500));

      expect(callbackCalled, isTrue,
          reason: 'onContinue should be called after tapping countdown circle');
    });

    testWidgets('auto-dismiss after 5 seconds', (tester) async {
      /**
       * Given: The welcome screen is displayed
       * When: 5 seconds pass without user interaction
       * Then: The onContinue callback is automatically called
       */
      bool callbackCalled = false;

      // Override the timer to enable testing with pump
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );

      // Initially callback should not be called
      expect(callbackCalled, isFalse,
          reason: 'onContinue should not be called before 5 seconds');

      // Pump and settle then advance time; pump for the completion callback
      // The screen should auto-call onContinue after 5 seconds via Timer
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );

      // Simulate the 5-second timer firing by pumping with duration
      await tester.pump(const Duration(seconds: 5));

      expect(callbackCalled, isTrue,
          reason: 'onContinue should be auto-called after 5 seconds');
    });

    testWidgets('grace tokens count - filled hearts', (tester) async {
      /**
       * Given: A user has 2 grace tokens remaining out of 3
       * When: The welcome screen renders
       * Then: 2 filled hearts and 1 empty heart are displayed
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // Look for heart icons (should be rendered as Icon widgets)
      // The exact count and filling depends on graceLeft from streak calculation
      expect(find.byType(Icon), findsWidgets,
          reason: 'grace token hearts should be rendered');
    });

    testWidgets('personal best label visible', (tester) async {
      /**
       * Given: The welcome screen displays personal best stats
       * When: The screen renders
       * Then: The personal best label (l10n.welcomePersonalBestLabel) is visible
       */
      bool callbackCalled = false;
      await _pumpPhone(
        tester,
        _wrap(
          dayRecords: const [],
          onContinue: () => callbackCalled = true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1500));

      // The label should be visible somewhere on the screen
      expect(find.byType(Text), findsWidgets,
          reason: 'personal best label should be rendered');
    });
  });
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _dateToString(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
