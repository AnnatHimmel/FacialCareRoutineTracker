import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/upgrade_sheet.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('UpgradeSheet', () {
    testWidgets('renders GLOW PRO overline text', (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      expect(find.text('GLOW PRO'), findsOneWidget);
    });

    testWidgets('renders dismiss link "אולי אחר כך"', (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      expect(find.text('אולי אחר כך'), findsOneWidget);
    });

    testWidgets('renders 3 feature rows', (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      expect(find.text('תיעוד התקדמות'), findsOneWidget);
      expect(find.text('ניהול המדף'), findsOneWidget);
      expect(find.text('תוקף ו-PAO'), findsOneWidget);
    });

    testWidgets('pricing toggle shows both yearly and monthly options',
        (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      expect(find.text('שנתי'), findsOneWidget);
      expect(find.text('חודשי'), findsOneWidget);
    });

    testWidgets('pricing toggle defaults to yearly selected', (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      // Yearly price should be visible
      expect(find.text('8.25 ₪ לחודש'), findsOneWidget);
    });

    testWidgets('CTA button renders', (tester) async {
      await tester.pumpWidget(_wrap(const UpgradeSheet()));
      expect(find.text('התחילי עם PRO'), findsOneWidget);
    });
  });
}
