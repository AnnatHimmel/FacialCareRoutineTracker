import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/pro_tag.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: child),
    );

void main() {
  group('ProTag', () {
    testWidgets('ProTag renders PRO text', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProTag(size: ProTagSize.normal),
      ));
      expect(find.text('PRO'), findsOneWidget);
    });

    testWidgets('ProTag normal size has correct height', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProTag(size: ProTagSize.normal),
      ));
      // Find the Container with height 21
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            (widget.constraints as BoxConstraints).maxHeight == 25,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('ProTag small size has correct height', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProTag(size: ProTagSize.small),
      ));
      // Find the Container with height 18
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints != null &&
            (widget.constraints as BoxConstraints).maxHeight == 18,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('ProTag renders workspace_premium icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProTag(size: ProTagSize.normal),
      ));
      // Look for Icon widget with workspace_premium name (Material Symbol)
      final iconFinder = find.byIcon(Icons.workspace_premium);
      expect(iconFinder, findsOneWidget);
    });

    testWidgets('ProTag has gold gradient background', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProTag(size: ProTagSize.normal),
      ));
      // Find Container with LinearGradient decoration
      final containerWithGradient = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).gradient is LinearGradient,
      );
      expect(containerWithGradient, findsOneWidget);
    });
  });
}
