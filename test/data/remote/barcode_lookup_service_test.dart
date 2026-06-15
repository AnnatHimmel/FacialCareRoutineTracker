import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/barcode_lookup_service.dart';

void main() {
  const testBarcode = '0087030027059';

  group('BarcodeProductLookupService', () {
    test('returns ScannedProductInfo when Open Beauty Facts responds with data',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Moisturizing Lotion',
                'brands': 'CeraVe',
                'image_url': 'https://example.com/image.jpg',
                'categories_tags': ['en:face-creams', 'en:moisturizers'],
                'ingredients_text': 'Water, Glycerin...',
                'quantity': '355ml',
              },
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'code': 'NOT_FOUND', 'items': []}), 200);
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.barcode, testBarcode);
      expect(result.name, 'Moisturizing Lotion');
      expect(result.brand, 'CeraVe');
      expect(result.imageUrl, 'https://example.com/image.jpg');
      expect(result.categoryHint, 'face creams');
      expect(result.ingredients, 'Water, Glycerin...');
      expect(result.quantity, '355ml');
    });

    test('falls back to UPC Item DB when Open Beauty Facts has no data',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        if (request.url.host == 'api.upcitemdb.com') {
          return http.Response(
            jsonEncode({
              'code': 'OK',
              'total': 1,
              'items': [
                {
                  'title': 'CeraVe AM Facial Moisturizing Lotion',
                  'brand': 'CeraVe',
                  'images': ['https://example.com/upc_image.jpg'],
                  'description': 'Lightweight moisturizer',
                  'category': 'Skincare',
                  'size': '3 fl oz',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.name, 'CeraVe AM Facial Moisturizing Lotion');
      expect(result.brand, 'CeraVe');
      expect(result.imageUrl, 'https://example.com/upc_image.jpg');
      expect(result.ingredients, 'Lightweight moisturizer');
      expect(result.quantity, '3 fl oz');
    });

    test('merges data — prefers OBF name/brand, uses UPC fallback for missing fields',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'OBF Name',
                'brands': 'OBF Brand',
                'image_url': null,
                'categories_tags': ['en:moisturizers'],
                'ingredients_text': null,
                'quantity': null,
              },
            }),
            200,
          );
        }
        if (request.url.host == 'api.upcitemdb.com') {
          return http.Response(
            jsonEncode({
              'code': 'OK',
              'total': 1,
              'items': [
                {
                  'title': 'UPC Title',
                  'brand': 'UPC Brand',
                  'images': ['https://example.com/upc_image.jpg'],
                  'description': 'UPC description',
                  'size': '100ml',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.name, 'OBF Name');
      expect(result.brand, 'OBF Brand');
      expect(result.imageUrl, 'https://example.com/upc_image.jpg');
      expect(result.ingredients, 'UPC description');
      expect(result.quantity, '100ml');
    });

    test('returns null when both APIs return no usable data', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        return http.Response(
          jsonEncode({'code': 'NOT_FOUND', 'items': []}),
          200,
        );
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNull);
    });

    test('returns null and does not throw on network error', () async {
      final client = MockClient((request) async {
        throw Exception('Network error');
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNull);
    });
  });
}
