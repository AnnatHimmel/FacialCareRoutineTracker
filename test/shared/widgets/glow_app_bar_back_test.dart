import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:skincare_tracker/shared/widgets/glow_app_bar.dart';

/// Regression tests for [GlowAppBar]'s default back action.
///
/// A screen reached via `context.go(...)` replaces go_router's match list with
/// a single entry. Previously the back button called `Navigator.of(context).pop()`
/// unconditionally, which popped that lone entry and crashed with
/// "You have popped the last page off of the stack, there are no pages left to
/// show" (a black screen at runtime). The default must now be go_router-safe.
void main() {
  Widget destScaffold(String label) => Scaffold(
        appBar: const GlowAppBar(showBack: true, title: 'dest'),
        body: Center(child: Text(label)),
      );

  GoRouter buildRouter() => GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(
            path: '/start',
            builder: (c, s) => const Scaffold(body: Center(child: Text('start'))),
          ),
          GoRoute(
            path: '/dest',
            builder: (c, s) => destScaffold('dest-screen'),
          ),
          GoRoute(
            path: '/today',
            builder: (c, s) => const Scaffold(body: Center(child: Text('today'))),
          ),
        ],
      );

  testWidgets(
      'back falls back to /today (no crash) when the screen was reached via go()',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // go() replaces the stack — nothing to pop back to.
    router.go('/dest');
    await tester.pumpAndSettle();
    expect(find.text('dest-screen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    // No assertion thrown; lands on the safe home fallback.
    expect(tester.takeException(), isNull);
    expect(find.text('today'), findsOneWidget);
  });

  testWidgets('back pops normally when the screen was reached via push()',
      (tester) async {
    final router = buildRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // push() keeps /start beneath /dest, so back pops to it.
    router.push('/dest');
    await tester.pumpAndSettle();
    expect(find.text('dest-screen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('start'), findsOneWidget);
  });
}
