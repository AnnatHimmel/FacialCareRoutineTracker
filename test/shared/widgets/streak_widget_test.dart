import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/streak_widget.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StreakWidget', () {
    testWidgets('displays currentStreak value', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 7, longestStreak: 14),
      ));

      expect(find.textContaining('7'), findsWidgets);
    });

    testWidgets('displays longestStreak value', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 3, longestStreak: 21),
      ));

      expect(find.textContaining('21'), findsOneWidget);
    });

    testWidgets('zero streak renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 0, longestStreak: 0),
      ));

      expect(find.textContaining('0'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('weekMissesUsed shown as X/budget ratio', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(
          currentStreak: 5,
          longestStreak: 10,
          weekMissesUsed: 1,
          weekMissBudget: 3,
        ),
      ));

      // remaining = 3 - 1 = 2 → "2/3"
      expect(find.textContaining('2/3'), findsOneWidget);
    });

    testWidgets('weekMissesUsed null → no budget row shown', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 5, longestStreak: 10),
      ));

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('weekMissesUsed provided → progress bar shown',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(
          currentStreak: 5,
          longestStreak: 10,
          weekMissesUsed: 0,
        ),
      ));

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('streak > 0 shows motivational text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 3, longestStreak: 5),
      ));

      expect(find.textContaining('זוהר'), findsOneWidget);
    });

    testWidgets('streak == 0 shows start-today text', (tester) async {
      await tester.pumpWidget(_wrap(
        const StreakWidget(currentStreak: 0, longestStreak: 0),
      ));

      expect(find.textContaining('נתחיל'), findsOneWidget);
    });
  });
}
