import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/streak_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StreakWidget', () {
    testWidgets('hero streak number is shown', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 42, longestStreak: 100, gracesUsed: 0),
      ));
      expect(find.text('42'), findsWidgets);
    });

    testWidgets('"ימים ברצף" label is shown', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 5, longestStreak: 10, gracesUsed: 0),
      ));
      expect(find.text('ימים ברצף'), findsOneWidget);
    });

    testWidgets('trophy chip shows longestStreak', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 5, longestStreak: 21, gracesUsed: 0),
      ));
      expect(find.textContaining('21'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });

    testWidgets('zero streak renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 0, longestStreak: 0, gracesUsed: 0),
      ));
      expect(find.text('0'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('gracesUsed: 1 → 2 filled tokens and 1 hollow', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(
          currentStreak: 5,
          longestStreak: 10,
          gracesUsed: 1,
          gracesTotal: 3,
        ),
      ));
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    });

    testWidgets('gracesUsed: 0 → all 3 tokens filled', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(
          currentStreak: 5,
          longestStreak: 10,
          gracesUsed: 0,
        ),
      ));
      expect(find.byIcon(Icons.favorite_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);
    });

    testWidgets('grace label shows remaining count', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(
          currentStreak: 5,
          longestStreak: 10,
          gracesUsed: 1,
        ),
      ));
      expect(find.textContaining('2 חסדים'), findsOneWidget);
    });

    testWidgets('streak > 0 shows motivational text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 3, longestStreak: 5, gracesUsed: 0),
      ));
      expect(find.textContaining('זוהר'), findsOneWidget);
    });

    testWidgets('streak == 0 shows start-today text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 0, longestStreak: 0, gracesUsed: 0),
      ));
      expect(find.textContaining('נתחיל'), findsOneWidget);
    });
  });
}
