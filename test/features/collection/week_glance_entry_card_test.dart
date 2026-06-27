import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/features/collection/collection_screen.dart';

// ── Test Helpers ──────────────────────────────────────────────────────────

Widget _wrap(Widget w) {
  final router = GoRouter(
    initialLocation: '/test',
    routes: [
      GoRoute(path: '/test', builder: (_, _) => w),
      GoRoute(
        path: '/week-glance',
        builder: (_, _) => const Scaffold(body: Text('week-glance')),
      ),
    ],
  );
  return MaterialApp.router(
    routerConfig: router,
    locale: const Locale('he'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────

void main() {
  group('WeekGlanceEntryCard', () {
    testWidgets(
      'should display title text when rendered',
      (WidgetTester tester) async {
        /// Given: WeekGlanceEntryCard is wrapped in GoRouter context
        /// When: the widget is rendered
        /// Then: the title text "שגרת השבוע שלי" is displayed
        await tester.pumpWidget(_wrap(const WeekGlanceEntryCard()));
        await tester.pumpAndSettle();

        expect(find.text('שגרת השבוע שלי'), findsOneWidget);
      },
    );

    testWidgets(
      'should display subtitle text when rendered',
      (WidgetTester tester) async {
        /// Given: WeekGlanceEntryCard is wrapped in GoRouter context
        /// When: the widget is rendered
        /// Then: the subtitle text "מה בשגרת הבוקר ומה בשגרת הערב בכל יום" is displayed
        await tester.pumpWidget(_wrap(const WeekGlanceEntryCard()));
        await tester.pumpAndSettle();

        expect(
          find.text('מה בשגרת הבוקר ומה בשגרת הערב בכל יום'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'should navigate to /week-glance when tapped',
      (WidgetTester tester) async {
        /// Given: WeekGlanceEntryCard is wrapped in GoRouter context
        /// When: the card is tapped
        /// Then: navigation occurs to /week-glance and the target screen appears
        await tester.pumpWidget(_wrap(const WeekGlanceEntryCard()));
        await tester.pumpAndSettle();

        // Find and tap the card (it should be a GestureDetector or similar)
        await tester.tap(find.byType(WeekGlanceEntryCard));
        await tester.pumpAndSettle();

        // Verify navigation by checking for the target screen text
        expect(find.text('week-glance'), findsOneWidget);
      },
    );
  });
}
