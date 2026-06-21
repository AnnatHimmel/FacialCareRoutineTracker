import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/scrapers/open_beauty_facts_name_search_scraper.dart';

void main() {
  group('OpenBeautyFactsNameSearchScraper', () {
    test(
        'extracts name, brand, image, ingredients and categoryHint from first product',
        () async {
      // Arrange
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'count': 1,
            'products': [
              {
                'product_name': 'Soonjung 2x Barrier Intensive Cream',
                'brands': 'Etude',
                'image_url': 'https://static.opf.org/soonjung.jpg',
                'image_front_url': 'https://static.opf.org/soonjung-front.jpg',
                'categories_tags': ['en:face-creams', 'en:moisturizers'],
                'ingredients_text': 'Water, Glycerin, Panthenol',
                'quantity': '60 ml',
              }
            ],
          }),
          200,
        );
      });

      // Act
      final scraper = OpenBeautyFactsNameSearchScraper(client: client);
      final result =
          await scraper.search('Soonjung 2x Barrier Intensive Cream');

      // Assert
      expect(result, isNotNull);
      expect(result!.name, 'Soonjung 2x Barrier Intensive Cream');
      expect(result.brand, 'Etude');
      expect(result.imageUrls,
          containsAll(['https://static.opf.org/soonjung.jpg',
                        'https://static.opf.org/soonjung-front.jpg']));
      expect(result.categoryHint, 'face creams');
      expect(result.ingredients, 'Water, Glycerin, Panthenol');
      expect(result.quantity, '60 ml');
      expect(result.barcode, '');
    });

    test('returns null when products list is empty', () async {
      // Arrange
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'count': 0, 'products': []}),
          200,
        );
      });

      // Act
      final scraper = OpenBeautyFactsNameSearchScraper(client: client);
      final result = await scraper.search('some product');

      // Assert
      expect(result, isNull);
    });

    test('returns null when first product has no name or brand', () async {
      // Arrange
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'count': 1,
            'products': [
              {
                'product_name': null,
                'brands': null,
                'image_url': 'https://static.opf.org/image.jpg',
                'categories_tags': ['en:face-creams'],
                'ingredients_text': 'Water, Glycerin',
                'quantity': '50 ml',
              }
            ],
          }),
          200,
        );
      });

      // Act
      final scraper = OpenBeautyFactsNameSearchScraper(client: client);
      final result = await scraper.search('some product');

      // Assert
      expect(result, isNull);
    });

    test('returns null on non-200 response', () async {
      // Arrange
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });

      // Act
      final scraper = OpenBeautyFactsNameSearchScraper(client: client);
      final result = await scraper.search('some product');

      // Assert
      expect(result, isNull);
    });

    test('returns null on network error', () async {
      // Arrange
      final client = MockClient((request) async {
        throw Exception('Network error');
      });

      // Act
      final scraper = OpenBeautyFactsNameSearchScraper(client: client);
      final result = await scraper.search('some product');

      // Assert
      expect(result, isNull);
    });
  });
}
