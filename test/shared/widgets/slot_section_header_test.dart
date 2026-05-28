import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/shared/widgets/slot_section_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SlotSectionHeader', () {
    testWidgets('morning slot shows sun icon and "בוקר"', (tester) async {
      await tester.pumpWidget(_wrap(
        const SlotSectionHeader(slot: Slot.morning, productCount: 3),
      ));

      expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
      expect(find.text('בוקר'), findsOneWidget);
    });

    testWidgets('evening slot shows moon icon and "ערב"', (tester) async {
      await tester.pumpWidget(_wrap(
        const SlotSectionHeader(slot: Slot.evening, productCount: 2),
      ));

      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
      expect(find.text('ערב'), findsOneWidget);
    });

    testWidgets('onToggle callback fires when tapped', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(
        SlotSectionHeader(
          slot: Slot.morning,
          productCount: 3,
          onToggle: () => fired = true,
        ),
      ));

      await tester.tap(find.byType(InkWell));
      expect(fired, isTrue);
    });

    testWidgets('count chip shows done/total when doneCount provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const SlotSectionHeader(
          slot: Slot.morning,
          productCount: 3,
          doneCount: 1,
        ),
      ));

      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('no count chip when doneCount is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const SlotSectionHeader(slot: Slot.morning, productCount: 3),
      ));

      // No count chip text like "X/Y"
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('expand/collapse chevron shown when onToggle provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SlotSectionHeader(
          slot: Slot.morning,
          productCount: 3,
          onToggle: () {},
        ),
      ));

      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('no chevron when onToggle is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const SlotSectionHeader(slot: Slot.morning, productCount: 3),
      ));

      expect(find.byIcon(Icons.expand_more), findsNothing);
    });
  });
}
