import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/master_product.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/shared/widgets/routine_item_row.dart';

MasterProduct _product({bool deprecated = false, String name = 'Test Product'}) =>
    MasterProduct(
      id: 'p1',
      name: name,
      categoryId: 'cat1',
      morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
      isDeprecated: deprecated,
      addedInVersion: '1.0.0',
    );

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RoutineItemRow', () {
    testWidgets('toggle button fires onToggle callback', (tester) async {
      var toggled = false;
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: false,
          onToggle: () => toggled = true,
        ),
      ));

      await tester.tap(find.byType(GestureDetector).last);
      expect(toggled, isTrue);
    });

    testWidgets('isToggled: true → done-check button shows filled peach icon',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: true,
          onToggle: () {},
        ),
      ));

      // Filled check icon present (done context, isToggled = true)
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hasConflict: true → conflict indicator (warning icon) visible',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: false,
          onToggle: () {},
          hasConflict: true,
        ),
      ));

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('hasConflict: false → no conflict indicator', (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: false,
          onToggle: () {},
          hasConflict: false,
        ),
      ));

      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('isDeprecated: true → "לא מומלץ" pill visible',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(deprecated: true),
          isToggled: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('לא מומלץ'), findsOneWidget);
    });

    testWidgets('isDeprecated: false → no deprecated pill', (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(deprecated: false),
          isToggled: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('לא מומלץ'), findsNothing);
    });

    testWidgets('isOwnershipContext: true → add/check icon (not done check)',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: false,
          onToggle: () {},
          isOwnershipContext: true,
        ),
      ));

      // Unselected ownership context shows add icon
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('isOwnershipContext: true + toggled → check icon',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: true,
          onToggle: () {},
          isOwnershipContext: true,
        ),
      ));

      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('product name is displayed', (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(name: 'My Serum'),
          isToggled: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('My Serum'), findsOneWidget);
    });

    testWidgets('isDraggable: true → no action button, drag handle shown',
        (tester) async {
      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: _product(),
          isToggled: false,
          onToggle: () {},
          isDraggable: true,
        ),
      ));

      expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
      expect(find.byIcon(Icons.check), findsNothing);
      expect(find.byIcon(Icons.add), findsNothing);
    });

    testWidgets('slot config renders am/pm label for morning-only product',
        (tester) async {
      final product = MasterProduct(
        id: 'p1',
        name: 'Morning Only',
        categoryId: 'cat1',
        morningConfig: const SlotConfig(order: 1, frequencyRule: DailyRule()),
        isDeprecated: false,
        addedInVersion: '1.0.0',
      );

      await tester.pumpWidget(_wrap(
        RoutineItemRow(
          product: product,
          isToggled: false,
          onToggle: () {},
        ),
      ));

      expect(find.text('בוקר'), findsOneWidget);
    });
  });
}
