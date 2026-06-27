import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/repositories/user_data_repository.dart';
import 'package:skincare_tracker/features/calendar/calendar_screen.dart';
import 'package:skincare_tracker/shared/providers/root_providers.dart';

// ── Fake ─────────────────────────────────────────────────────────────────────

class _FakeUDR implements UserDataRepository {
  final List<DayRecord> monthRecords;
  _FakeUDR({this.monthRecords = const []});

  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String ym) =>
      Stream.value(monthRecords.where((r) => r.date.startsWith(ym)).toList());

  @override Stream<List<ProductSelection>> watchSelections(Slot s) => throw UnimplementedError();
  @override Future<void> upsertSelection(ProductSelection s) => throw UnimplementedError();
  @override Stream<WeekdaySchedule?> watchSchedule(String p, Slot s) => throw UnimplementedError();
  @override Stream<List<WeekdaySchedule>> watchAllSchedules() => throw UnimplementedError();
  @override Future<void> upsertSchedule(WeekdaySchedule s) => throw UnimplementedError();
  @override Stream<OrderOverride?> watchOrderOverride(Slot s) => throw UnimplementedError();
  @override Future<void> upsertOrderOverride(OrderOverride o) => throw UnimplementedError();
  @override Future<void> deleteOrderOverride(Slot s) => throw UnimplementedError();

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) => Stream.value([]);
  @override
  Future<OrderOverride?> getEffectiveOrderOverride(Slot slot, int weekday) async => null;
  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {}
  @override Stream<DayRecord?> watchDayRecord(String d, Slot s) => throw UnimplementedError();
  @override Future<DayRecord> snapshotAndGetDayRecord(String d, Slot s, List<String> ids, String v) => throw UnimplementedError();
  @override Future<void> updateDayRecord(DayRecord r) => throw UnimplementedError();
  @override Stream<List<DayRecord>> watchAllDayRecords() => throw UnimplementedError();
  @override Stream<SkinLogEntry?> watchSkinLog(String d) => Stream.value(null);
  @override Future<void> upsertSkinLog(SkinLogEntry e) => throw UnimplementedError();
  @override Stream<List<SkinLogEntry>> watchAllSkinLogs() => throw UnimplementedError();
  @override Stream<List<MutedConflict>> watchMutedConflicts() => throw UnimplementedError();
  @override Future<void> muteConflict(MutedConflict m) => throw UnimplementedError();
  @override Future<void> unmuteConflict(String ruleId) => throw UnimplementedError();
  @override Future<UserDataExport> exportAllData() => throw UnimplementedError();
  @override Future<void> replaceAllData(UserDataExport e) => throw UnimplementedError();
  @override Future<void> clearRoutineData() async {}
  @override Stream<List<UserCustomProduct>> watchCustomProducts() => Stream.value([]);
  @override Future<void> upsertCustomProduct(UserCustomProduct p) async {}
  @override Future<void> deleteCustomProduct(String id) async {}
  @override Stream<List<CollectionItem>> watchCollectionItems() => throw UnimplementedError();
  @override Future<void> upsertCollectionItem(CollectionItem item) => throw UnimplementedError();
  @override Future<void> deleteCollectionItem(String id) => throw UnimplementedError();
  @override Stream<List<CategoryOverride>> watchCategoryOverrides() => Stream.value([]);
  @override Future<void> upsertCategoryOverride(CategoryOverride o) async {}
  @override Future<void> deleteCategoryOverride(String productId) async {}
}

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap({List<DayRecord> records = const []}) {
  final router = GoRouter(
    initialLocation: '/calendar',
    routes: [
      GoRoute(
        path: '/calendar',
        builder: (_, _) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/day/:date',
        builder: (_, state) =>
            Scaffold(body: Text('day-${state.pathParameters['date']}')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      userDataRepositoryProvider.overrideWithValue(_FakeUDR(monthRecords: records)),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
    ),
  );
}

// The CalendarScreen body is a non-scrolling Column whose natural height
// exceeds the default 600px test viewport. Set a tall surface so the grid
// and legend both fit without a RenderFlex overflow error.
void _useTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

void main() {
  group('CalendarScreen', () {
    testWidgets('renders day-of-week headers (RTL Sun–Sat)', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      for (final label in ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('month label is shown', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final now = DateTime.now();
      const months = [
        'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
        'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
      ];
      final expectedLabel = '${months[now.month - 1]} ${now.year}';
      expect(find.text(expectedLabel), findsOneWidget);
    });

    testWidgets('previous month button changes month label', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      final prevMonth = DateTime(DateTime.now().year, DateTime.now().month - 1);
      const months = [
        'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
        'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
      ];
      final prevLabel = '${months[prevMonth.month - 1]} ${prevMonth.year}';
      expect(find.text(prevLabel), findsOneWidget);
    });

    testWidgets('tapping day cell navigates to /day/:date', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      // Go to a past month so we can tap any day
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();

      // Tap day '1' — the screen expands an inline detail section (not navigation)
      await tester.tap(find.text('1').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('תיעוד יומי'), findsOneWidget);
    });

    testWidgets('legend items are shown', (tester) async {
      _useTallSurface(tester);
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('הושלם'), findsOneWidget);
      expect(find.text('חלקי'), findsOneWidget);
      expect(find.text('הוחמץ'), findsOneWidget);
    });
  });
}
