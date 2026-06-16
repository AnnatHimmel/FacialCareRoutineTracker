import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/pao_meter.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('PaoMeter', () {
    testWidgets('PaoMeter renders without error', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.ok),
      ));
      expect(tester.takeException(), isNull);
      expect(find.byType(PaoMeter), findsOneWidget);
    });

    testWidgets('PaoMeter ok tone uses peach color', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.ok),
      ));

      // Find the progress fill Container with the peach color
      final peachColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.color == const Color(0xffe58b73),
      );
      expect(peachColorFinder, findsOneWidget);
    });

    testWidgets('PaoMeter warn tone uses amber color', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.warn),
      ));

      // Find the progress fill Container with the amber color
      final amberColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.color == const Color(0xffd9a648),
      );
      expect(amberColorFinder, findsOneWidget);
    });

    testWidgets('PaoMeter bad tone uses red color', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.bad),
      ));

      // Find the progress fill Container with the red color
      final redColorFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.color == const Color(0xffba1a1a),
      );
      expect(redColorFinder, findsOneWidget);
    });

    testWidgets('PaoMeter renders with default height', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.ok),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PaoMeter renders with custom height', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.5, tone: PaoTone.ok, height: 12),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PaoMeter renders at 0% value', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 0.0, tone: PaoTone.ok),
      ));
      expect(tester.takeException(), isNull);
    });

    testWidgets('PaoMeter renders at 100% value', (tester) async {
      await tester.pumpWidget(_wrap(
        const PaoMeter(value: 1.0, tone: PaoTone.bad),
      ));
      expect(tester.takeException(), isNull);
    });
  });
}
