import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/shared/widgets/product_thumb.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('ProductThumb image dispatch', () {
    testWidgets('null imageAsset renders fallback icon', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProductThumb(imageAsset: null, fallbackIcon: Icons.spa_outlined),
      ));
      expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
      expect(find.byType(CachedNetworkImage), findsNothing);
    });

    testWidgets('https:// URL renders CachedNetworkImage', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProductThumb(
            imageAsset: 'https://example.supabase.co/product.jpg'),
      ));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('http:// URL also renders CachedNetworkImage', (tester) async {
      await tester.pumpWidget(_wrap(
        const ProductThumb(imageAsset: 'http://localhost/test.jpg'),
      ));
      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('local asset path does not render CachedNetworkImage',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const ProductThumb(imageAsset: 'assets/images/products/foo.jpg'),
      ));
      expect(find.byType(CachedNetworkImage), findsNothing);
    });
  });
}
