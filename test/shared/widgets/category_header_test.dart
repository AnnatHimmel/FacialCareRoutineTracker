import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/category_header.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CategoryHeader', () {
    testWidgets('renders category name', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryHeader(categoryName: 'לחות'),
      ));

      expect(find.text('לחות'), findsOneWidget);
    });

    testWidgets('renders Latin category name', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryHeader(categoryName: 'Serums'),
      ));

      expect(find.text('Serums'), findsOneWidget);
    });

    testWidgets('count chip present when count provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryHeader(categoryName: 'ניקוי', count: 4),
      ));

      expect(find.textContaining('4'), findsOneWidget);
      expect(find.textContaining('פריטים'), findsOneWidget);
    });

    testWidgets('no count chip when count is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryHeader(categoryName: 'ניקוי'),
      ));

      expect(find.textContaining('פריטים'), findsNothing);
    });

    testWidgets('custom countSuffix is used', (tester) async {
      await tester.pumpWidget(_wrap(
        const CategoryHeader(
          categoryName: 'ניקוי',
          count: 2,
          countSuffix: 'מוצרים',
        ),
      ));

      expect(find.textContaining('מוצרים'), findsOneWidget);
      expect(find.textContaining('פריטים'), findsNothing);
    });
  });
}
