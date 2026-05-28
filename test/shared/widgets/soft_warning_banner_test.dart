import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/soft_warning_banner.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('SoftWarningBanner', () {
    testWidgets('renders message text', (tester) async {
      await tester.pumpWidget(_wrap(
        const SoftWarningBanner(message: 'ויטמין C + רטינול — לא לשלב'),
      ));

      expect(find.text('ויטמין C + רטינול — לא לשלב'), findsOneWidget);
    });

    testWidgets('mute button fires onMute callback', (tester) async {
      var muted = false;
      await tester.pumpWidget(_wrap(
        SoftWarningBanner(
          message: 'conflict warning',
          onMute: () => muted = true,
        ),
      ));

      await tester.tap(find.text('השתק'));
      expect(muted, isTrue);
    });

    testWidgets('no mute button when onMute is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const SoftWarningBanner(message: 'warning'),
      ));

      expect(find.text('השתק'), findsNothing);
    });

    testWidgets('custom action widget is rendered when provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SoftWarningBanner(
          message: 'warning',
          customAction: const Text('custom-action'),
        ),
      ));

      expect(find.text('custom-action'), findsOneWidget);
    });

    testWidgets('dismiss button fires onDismiss callback', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(_wrap(
        SoftWarningBanner(
          message: 'warning',
          onDismiss: () => dismissed = true,
        ),
      ));

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, isTrue);
    });

    testWidgets('no dismiss button when onDismiss is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const SoftWarningBanner(message: 'warning'),
      ));

      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('custom muteLabel overrides default "השתק"', (tester) async {
      await tester.pumpWidget(_wrap(
        SoftWarningBanner(
          message: 'warning',
          muteLabel: 'הסתר',
          onMute: () {},
        ),
      ));

      expect(find.text('הסתר'), findsOneWidget);
      expect(find.text('השתק'), findsNothing);
    });
  });
}
