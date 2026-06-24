import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/domain/services/routine_build_summary.dart';
import 'package:skincare_tracker/features/setup/routine_ready_summary_screen.dart';

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _summaryWithItems = RoutineBuildSummary(
  totalProducts: 13,
  morningCount: 7,
  eveningCount: 9,
  changes: [
    RoutineChange(
      slot: Slot.morning,
      kind: RoutineChangeKind.movedDays,
      he: 'הזזנו את הרטינול לימי ראשון וחמישי בלבד',
      en: 'Moved retinol to Sundays and Thursdays only',
    ),
    RoutineChange(
      slot: Slot.evening,
      kind: RoutineChangeKind.reducedFrequency,
      he: 'הפחתנו את תדירות הסרום לשלוש פעמים בשבוע',
      en: 'Reduced serum frequency to three times a week',
    ),
    RoutineChange(
      slot: Slot.morning,
      kind: RoutineChangeKind.movedSlot,
      he: 'העברנו את ויטמין C לבוקר',
      en: 'Moved Vitamin C to morning',
    ),
  ],
  advisories: [
    RoutineAdvisory(
      slot: Slot.evening,
      he: 'ניאצינמיד ורטינול — מומלץ להפריד לערבים שונים',
      en: 'Niacinamide and retinol — recommended on separate evenings',
    ),
  ],
);

const _summaryNothingToReport = RoutineBuildSummary(
  totalProducts: 5,
  morningCount: 3,
  eveningCount: 4,
);

// ── Test harness ──────────────────────────────────────────────────────────────

Widget _wrap(RoutineBuildSummary summary, {VoidCallback? onContinue}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('he'),
    home: Directionality(
      textDirection: TextDirection.rtl,
      child: RoutineReadySummaryScreen(
        summary: summary,
        onContinue: onContinue ?? () {},
      ),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('RoutineReadySummaryScreen', () {
    group('with changes and advisories', () {
      testWidgets('shows the screen title', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        expect(find.text('השגרה שלך מוכנה ✨'), findsOneWidget);
      });

      testWidgets('shows both section headers', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        expect(find.text('מה סידרנו בשבילך'), findsOneWidget);
        expect(find.text('כדאי לשים לב'), findsOneWidget);
      });

      testWidgets('renders a בוקר badge for a morning change', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        // morning changes are present → at least one "בוקר" badge
        expect(find.text('בוקר'), findsWidgets);
      });

      testWidgets('renders a ערב badge for an evening change', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        // evening changes are present → at least one "ערב" badge
        expect(find.text('ערב'), findsWidgets);
      });

      testWidgets('renders kind icons for each change kind', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
        expect(find.byIcon(Icons.south_rounded), findsOneWidget);
        expect(find.byIcon(Icons.swap_vert), findsOneWidget);
      });

      testWidgets('renders advisory icon', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.schedule_rounded), findsWidgets);
      });

      testWidgets('CTA is present and fires onContinue when tapped',
          (tester) async {
        var called = false;
        await tester.pumpWidget(
          _wrap(_summaryWithItems, onContinue: () => called = true),
        );
        await tester.pumpAndSettle();

        expect(find.text('הצגת השגרה שלי'), findsOneWidget);

        await tester.tap(find.text('הצגת השגרה שלי'));
        await tester.pump();

        expect(called, isTrue);
      });

      testWidgets('does NOT show the nothing-to-report line', (tester) async {
        await tester.pumpWidget(_wrap(_summaryWithItems));
        await tester.pumpAndSettle();

        expect(
          find.text('לא נדרשו התאמות — השגרה מסודרת ומוכנה.'),
          findsNothing,
        );
      });
    });

    group('with nothing to report', () {
      testWidgets('shows the empty-state reassurance line', (tester) async {
        await tester.pumpWidget(_wrap(_summaryNothingToReport));
        await tester.pumpAndSettle();

        expect(
          find.text('לא נדרשו התאמות — השגרה מסודרת ומוכנה.'),
          findsOneWidget,
        );
      });

      testWidgets('does NOT show changes section header', (tester) async {
        await tester.pumpWidget(_wrap(_summaryNothingToReport));
        await tester.pumpAndSettle();

        expect(find.text('מה סידרנו בשבילך'), findsNothing);
      });

      testWidgets('does NOT show advisories section header', (tester) async {
        await tester.pumpWidget(_wrap(_summaryNothingToReport));
        await tester.pumpAndSettle();

        expect(find.text('כדאי לשים לב'), findsNothing);
      });

      testWidgets('CTA is still present', (tester) async {
        await tester.pumpWidget(_wrap(_summaryNothingToReport));
        await tester.pumpAndSettle();

        expect(find.text('הצגת השגרה שלי'), findsOneWidget);
      });
    });
  });
}
