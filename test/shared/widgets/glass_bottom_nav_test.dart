import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/glass_bottom_nav.dart';

const _items = [
  GlassNavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'בית',
  ),
  GlassNavItem(
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    label: 'לוח',
  ),
  GlassNavItem(
    icon: Icons.photo_library_outlined,
    selectedIcon: Icons.photo_library,
    label: 'יומן',
  ),
  GlassNavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'הגדרות',
  ),
];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('GlassBottomNav', () {
    testWidgets('renders all 4 tab labels', (tester) async {
      await tester.pumpWidget(_wrap(
        GlassBottomNav(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          items: _items,
        ),
      ));

      expect(find.text('בית'), findsOneWidget);
      expect(find.text('לוח'), findsOneWidget);
      expect(find.text('יומן'), findsOneWidget);
      expect(find.text('הגדרות'), findsOneWidget);
    });

    testWidgets('onDestinationSelected fires with correct index',
        (tester) async {
      final tapped = <int>[];
      await tester.pumpWidget(_wrap(
        GlassBottomNav(
          currentIndex: 0,
          onDestinationSelected: tapped.add,
          items: _items,
        ),
      ));

      await tester.tap(find.text('לוח'));
      expect(tapped, [1]);

      await tester.tap(find.text('הגדרות'));
      expect(tapped, [1, 3]);
    });

    testWidgets('active tab uses selected icon', (tester) async {
      await tester.pumpWidget(_wrap(
        GlassBottomNav(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          items: _items,
        ),
      ));

      // Selected icon for index 0 is Icons.home (filled)
      expect(find.byIcon(Icons.home), findsOneWidget);
      // Unselected icon for index 0 should NOT be shown
      expect(find.byIcon(Icons.home_outlined), findsNothing);
    });

    testWidgets('inactive tab uses outline icon', (tester) async {
      await tester.pumpWidget(_wrap(
        GlassBottomNav(
          currentIndex: 0,
          onDestinationSelected: (_) {},
          items: _items,
        ),
      ));

      // Inactive tabs show outline icons
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('active index 2 marks third item selected', (tester) async {
      await tester.pumpWidget(_wrap(
        GlassBottomNav(
          currentIndex: 2,
          onDestinationSelected: (_) {},
          items: _items,
        ),
      ));

      expect(find.byIcon(Icons.photo_library), findsOneWidget);
      expect(find.byIcon(Icons.photo_library_outlined), findsNothing);
    });
  });
}
