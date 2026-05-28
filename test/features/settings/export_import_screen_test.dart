import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/features/settings/export_import_screen.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap() {
  final router = GoRouter(
    initialLocation: '/export-import',
    routes: [
      GoRoute(
        path: '/export-import',
        builder: (_, __) => const ExportImportScreen(),
      ),
      GoRoute(
        path: '/export-import/merge',
        builder: (_, __) => const Scaffold(body: Text('merge-screen')),
      ),
    ],
  );
  return ProviderScope(
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ExportImportScreen', () {
    testWidgets('renders export section title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('ייצוא נתונים'), findsOneWidget);
    });

    testWidgets('renders import section title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.text('ייבוא נתונים'), findsOneWidget);
    });

    testWidgets('export action button is present and enabled', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ייצוא'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('import action button is present and enabled', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'ייבוא'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('no status message shown on initial render', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
