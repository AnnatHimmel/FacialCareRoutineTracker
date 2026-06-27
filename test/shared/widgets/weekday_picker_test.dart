import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/core/l10n/generated/app_localizations.dart';
import 'package:skincare_tracker/shared/widgets/weekday_picker.dart';

// Stateful wrapper so we can track the live selection
class _PickerHarness extends StatefulWidget {
  const _PickerHarness();

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  Set<int> _selected = <int>{};

  @override
  Widget build(BuildContext context) => WeekdayPicker(
        selectedDays: _selected,
        onChanged: (days) => setState(() => _selected = days),
      );
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('he', 'MA'),
      home: Scaffold(body: child),
    );

void main() {
  group('WeekdayPicker', () {
    testWidgets('renders all 7 day chips', (tester) async {
      await tester.pumpWidget(_wrap(const _PickerHarness()));

      // Sunday–Saturday labels
      for (final label in ['א׳', 'ב׳', 'ג׳', 'ד׳', 'ה׳', 'ו׳', 'ש׳']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('tap unselected day → adds to selection', (tester) async {
      Set<int> captured = {};
      await tester.pumpWidget(_wrap(
        WeekdayPicker(
          selectedDays: const {},
          onChanged: (days) => captured = days,
        ),
      ));

      await tester.tap(find.text('א׳')); // Sunday = index 0
      expect(captured.contains(0), isTrue);
    });

    testWidgets('tap selected day → removes from selection', (tester) async {
      Set<int> captured = {0};
      await tester.pumpWidget(_wrap(
        WeekdayPicker(
          selectedDays: const {0},
          onChanged: (days) => captured = days,
        ),
      ));

      await tester.tap(find.text('א׳')); // deselect Sunday
      expect(captured.contains(0), isFalse);
    });

    testWidgets('stateful: tap adds then tap again removes', (tester) async {
      await tester.pumpWidget(_wrap(const _PickerHarness()));

      await tester.tap(find.text('ב׳')); // Monday = 1
      await tester.pump();
      await tester.tap(find.text('ב׳')); // deselect
      await tester.pump();

      // After two taps, the selection should be empty again
      final state = tester.state<_PickerHarnessState>(
        find.byType(_PickerHarness),
      );
      expect(state._selected.contains(1), isFalse);
    });

    testWidgets('showOverCapWarning: true → warning text visible',
        (tester) async {
      await tester.pumpWidget(_wrap(
        WeekdayPicker(
          selectedDays: const {0, 1, 2, 3, 4, 5, 6},
          onChanged: (_) {},
          showOverCapWarning: true,
        ),
      ));

      expect(find.textContaining('מעבר למומלץ'), findsOneWidget);
    });

    testWidgets('showOverCapWarning: false → no warning text', (tester) async {
      await tester.pumpWidget(_wrap(
        WeekdayPicker(
          selectedDays: const {},
          onChanged: (_) {},
        ),
      ));

      expect(find.textContaining('מעבר למומלץ'), findsNothing);
    });
  });
}
