import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';
import 'package:skincare_tracker/shared/widgets/manual_order_chip.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he'),
      home: Scaffold(body: child),
    );

void main() {
  group('ManualOrderChip', () {
    testWidgets('shows the moved-product count label and icons', (tester) async {
      await tester.pumpWidget(_wrap(
        ManualOrderChip(slot: Slot.morning, count: 2, onTap: () {}),
      ));

      expect(find.text('2 מוצרים הוזזו ידנית'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      // The reorder arrows icon was intentionally removed — info icon only.
      expect(find.byIcon(Icons.swap_vert_rounded), findsNothing);
    });

    testWidgets('uses the singular form for one product', (tester) async {
      await tester.pumpWidget(_wrap(
        ManualOrderChip(slot: Slot.evening, count: 1, onTap: () {}),
      ));

      expect(find.text('מוצר אחד הוזז ידנית'), findsOneWidget);
    });

    testWidgets('fires onTap when pressed', (tester) async {
      var fired = false;
      await tester.pumpWidget(_wrap(
        ManualOrderChip(
          slot: Slot.morning,
          count: 3,
          onTap: () => fired = true,
        ),
      ));

      await tester.tap(find.byType(ManualOrderChip));
      expect(fired, isTrue);
    });
  });
}
