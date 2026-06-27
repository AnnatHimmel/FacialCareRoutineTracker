import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/barcode_lookup_service.dart';
import 'package:skincare_tracker/data/remote/retailer_search_scraper.dart';
import 'package:skincare_tracker/domain/entities/scanned_product_info.dart';

/// Test double for [RetailerSearchScraper] that returns a fixed result and records queries.
class _StubScraper implements RetailerSearchScraper {
  final ScannedProductInfo? _result;
  final List<String> queries = [];

  @override
  final bool supportsBarcodeSearch;

  _StubScraper(this._result, {this.supportsBarcodeSearch = false});

  @override
  Future<ScannedProductInfo?> search(String query) async {
    queries.add(query);
    return _result;
  }
}

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
        return http.Response(jsonEncode({'code': 'NOT_FOUND', 'items': <dynamic>[]}), 200);
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
      // UPCItemDB's "description" is a marketing blurb, not INCI — it maps to
      // the comment, leaving ingredients empty.
      expect(result.ingredients, isNull);
      expect(result.comment, 'Lightweight moisturizer');
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
      // UPC "description" is a comment, not ingredients; OBF had no INCI here.
      expect(result.ingredients, isNull);
      expect(result.comment, 'UPC description');
      expect(result.quantity, '100ml');
    });

    test('surfaces all UPC images in imageUrls; imageUrl is the first', () async {
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
                  'title': 'Multi Image Product',
                  'brand': 'BrandX',
                  'images': [
                    'https://example.com/a.jpg',
                    'https://example.com/b.jpg',
                    'https://example.com/c.jpg',
                  ],
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
      expect(result!.imageUrls, [
        'https://example.com/a.jpg',
        'https://example.com/b.jpg',
        'https://example.com/c.jpg',
      ]);
      expect(result.imageUrl, 'https://example.com/a.jpg');
    });

    test('surfaces both OBF image_url and image_front_url, deduped', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'OBF Multi',
                'brands': 'OBF Brand',
                'image_url': 'https://example.com/front.jpg',
                'image_front_url': 'https://example.com/front-big.jpg',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final service = BarcodeProductLookupService(client: client);
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.imageUrls, containsAll([
        'https://example.com/front.jpg',
        'https://example.com/front-big.jpg',
      ]));
    });

    test('merges candidate images across sources in priority order, deduped',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'OBF Name',
                'brands': 'OBF Brand',
                'image_url': 'https://example.com/shared.jpg',
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
                  'images': [
                    'https://example.com/shared.jpg',
                    'https://example.com/upc-only.jpg',
                  ],
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
      // OBF image first (priority), UPC unique image appended, no duplicate.
      expect(result!.imageUrls, [
        'https://example.com/shared.jpg',
        'https://example.com/upc-only.jpg',
      ]);
    });

    test('returns null when both APIs return no usable data', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(jsonEncode({'status': 0}), 200);
        }
        return http.Response(
          jsonEncode({'code': 'NOT_FOUND', 'items': <dynamic>[]}),
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

  group('RetailerSearchScraper augmentation', () {
    test('augment: fills missing brand from scraper when base has name', () async {
      // Base: OBF returns name but no brand
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'CeraVe Lotion',
                'brands': null,
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          brand: 'CeraVe',
          imageUrls: ['https://example.com/scraper.jpg'],
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.name, 'CeraVe Lotion');   // from base
      expect(result.brand, 'CeraVe');           // from scraper
      expect(result.imageUrls, contains('https://example.com/scraper.jpg'));
      // Augment path: scraper called with product name, not barcode
      expect(scraper.queries, ['CeraVe Lotion']);
    });

    test('augment: scraper images appended after base images, deduped', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Some Product',
                'brands': 'Brand',
                'image_url': 'https://example.com/base.jpg',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      // Scraper returns a duplicate + a new image
      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          imageUrls: ['https://example.com/base.jpg', 'https://example.com/scraper.jpg'],
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.imageUrls, [
        'https://example.com/base.jpg',
        'https://example.com/scraper.jpg',
      ]);
    });

    test('augment: images deduped at address level (scheme/case/trailing-? insensitive)',
        () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Some Product',
                'brands': 'Brand',
                'image_url': 'https://example.com/shared.jpg',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      // Scraper returns the same image with trivial address-level differences
      // plus one genuinely new image.
      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          imageUrls: [
            'http://EXAMPLE.com/shared.jpg?', // same address, diff scheme/case/?
            'https://example.com/unique.jpg',
          ],
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      // The shared image appears once (base copy kept), unique one appended.
      expect(result!.imageUrls, [
        'https://example.com/shared.jpg',
        'https://example.com/unique.jpg',
      ]);
    });

    test('augment: does not overwrite existing base fields', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Base Name',
                'brands': 'Base Brand',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Scraper Name',
          brand: 'Scraper Brand',
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result!.name, 'Base Name');   // base wins
      expect(result.brand, 'Base Brand'); // base wins
    });

    test('fallback: when all 5 sources null, uses scraper result with real barcode', () async {
      final client = MockClient((request) async => http.Response('{}', 404));

      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Soonjung 2x Barrier Intensive Cream',
          brand: 'Etude',
          imageUrls: ['https://img.example.com/soonjung.jpg'],
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.barcode, testBarcode); // corrected to real barcode
      expect(result.name, 'Soonjung 2x Barrier Intensive Cream');
      // Fallback path: scraper called with barcode, not a name
      expect(scraper.queries, [testBarcode]);
    });

    test('fallback: when all sources and scrapers return null, result is null', () async {
      final client = MockClient((request) async => http.Response('{}', 404));
      final scraper = _StubScraper(null);

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNull);
    });

    test('fallback: scraper result with site-level name is rejected as garbage', () async {
      final client = MockClient((request) async => http.Response('{}', 404));

      // Simulates YesStyle returning its own site title from a Cloudflare challenge page
      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'YesStyle - Fashion and Beauty',
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [scraper],
      );
      final result = await service.lookup(testBarcode);

      // Garbage site name must be filtered — overall result must be null
      expect(result, isNull);
    });
  });

  group('barcode-capable scraper (queried by barcode)', () {
    test('overrides barcode APIs for name/brand/image and is queried by barcode',
        () async {
      // OBF API returns data with a WRONG brand and its own name/image.
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'API Name',
                'brands': 'WrongBrand',
                'image_url': 'https://example.com/api.jpg',
                'ingredients_text': 'Water, Glycerin',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      // YesStyle-style scraper that supports barcode search returns the truth.
      final yesStyle = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Zero Pore Pad 2.0',
          brand: 'medicube',
          imageUrls: ['https://example.com/yesstyle.jpg'],
        ),
        supportsBarcodeSearch: true,
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [yesStyle],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      // Tier 1 (barcode scrape) overrides the APIs for name/brand/image.
      expect(result!.name, 'Zero Pore Pad 2.0');
      expect(result.brand, 'medicube');
      expect(result.imageUrl, 'https://example.com/yesstyle.jpg');
      // API fills gaps the scrape didn't provide.
      expect(result.ingredients, 'Water, Glycerin');
      // The barcode-capable scraper was queried with the BARCODE, not a name.
      expect(yesStyle.queries, [testBarcode]);
    });

    test('name-only scrapers still fill gaps the barcode scrape leaves', () async {
      final client = MockClient((request) async => http.Response('{}', 404));

      final yesStyle = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Zero Pore Pad 2.0',
          brand: 'medicube',
          imageUrls: ['https://example.com/yesstyle.jpg'],
        ),
        supportsBarcodeSearch: true,
      );
      // A name-only scraper that contributes ingredients.
      final nameOnly = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Zero Pore Pad 2.0',
          ingredients: 'Water, Lactic Acid, Salicylic Acid',
        ),
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [yesStyle, nameOnly],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.name, 'Zero Pore Pad 2.0');
      expect(result.brand, 'medicube'); // from barcode scrape
      expect(result.ingredients, 'Water, Lactic Acid, Salicylic Acid'); // gap-filled
      // Barcode scrape queried by barcode; name-only scraper queried by name.
      expect(yesStyle.queries, [testBarcode]);
      expect(nameOnly.queries, ['Zero Pore Pad 2.0']);
    });

    test('site-level scrape name does not override real API data', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'world.openbeautyfacts.org') {
          return http.Response(
            jsonEncode({
              'status': 1,
              'product': {
                'product_name': 'Real Product',
                'brands': 'RealBrand',
              },
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      });

      // Simulates YesStyle Cloudflare challenge page title.
      final yesStyle = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'YesStyle - Fashion and Beauty',
        ),
        supportsBarcodeSearch: true,
      );

      final service = BarcodeProductLookupService(
        client: client,
        scrapers: [yesStyle],
      );
      final result = await service.lookup(testBarcode);

      expect(result, isNotNull);
      expect(result!.name, 'Real Product'); // garbage scrape rejected
      expect(result.brand, 'RealBrand');
    });
  });

  group('lookupByName', () {
    test('queries scrapers with the product name and merges their data',
        () async {
      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Niacinamide 10% + Zinc 1%',
          brand: 'The Ordinary',
          imageUrls: ['https://img.example.com/niacinamide.jpg'],
          categoryHint: 'serum',
          ingredients: 'Aqua, Niacinamide, Zinc PCA',
        ),
      );

      final service = BarcodeProductLookupService(scrapers: [scraper]);
      final result = await service.lookupByName('Niacinamide 10% + Zinc 1%');

      expect(result, isNotNull);
      expect(result!.barcode, ''); // no barcode for a name lookup
      expect(result.name, 'Niacinamide 10% + Zinc 1%');
      expect(result.brand, 'The Ordinary');
      expect(result.imageUrl, 'https://img.example.com/niacinamide.jpg');
      expect(result.categoryHint, 'serum');
      expect(result.ingredients, 'Aqua, Niacinamide, Zinc PCA');
      expect(scraper.queries, ['Niacinamide 10% + Zinc 1%']);
    });

    test('includes brand in the query when provided', () async {
      final scraper = _StubScraper(
        const ScannedProductInfo(barcode: '', name: 'BHA Salicylic'),
      );

      final service = BarcodeProductLookupService(scrapers: [scraper]);
      await service.lookupByName('BHA Salicylic', brand: 'The Ordinary');

      expect(scraper.queries, ['The Ordinary BHA Salicylic']);
    });

    test('fills missing fields from later scrapers and dedupes images',
        () async {
      final first = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Gentle Cleanser',
          imageUrls: ['https://img.example.com/a.jpg'],
        ),
      );
      final second = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'Gentle Cleanser',
          brand: 'CeraVe',
          imageUrls: [
            'https://img.example.com/a.jpg',
            'https://img.example.com/b.jpg',
          ],
          ingredients: 'Aqua, Glycerin',
        ),
      );

      final service =
          BarcodeProductLookupService(scrapers: [first, second]);
      final result = await service.lookupByName('Gentle Cleanser');

      expect(result, isNotNull);
      expect(result!.name, 'Gentle Cleanser');
      expect(result.brand, 'CeraVe'); // filled from the second scraper
      expect(result.ingredients, 'Aqua, Glycerin');
      expect(result.imageUrls, [
        'https://img.example.com/a.jpg',
        'https://img.example.com/b.jpg',
      ]);
    });

    test('returns null when no scraper has useful data', () async {
      final service =
          BarcodeProductLookupService(scrapers: [_StubScraper(null)]);
      final result = await service.lookupByName('Unknown Product');
      expect(result, isNull);
    });

    test('rejects site-level names as garbage', () async {
      final scraper = _StubScraper(
        const ScannedProductInfo(
          barcode: '',
          name: 'YesStyle - Fashion and Beauty',
        ),
      );
      final service = BarcodeProductLookupService(scrapers: [scraper]);
      final result = await service.lookupByName('something');
      expect(result, isNull);
    });

    test('returns null for an empty name', () async {
      final scraper = _StubScraper(
        const ScannedProductInfo(barcode: '', name: 'X'),
      );
      final service = BarcodeProductLookupService(scrapers: [scraper]);
      final result = await service.lookupByName('   ');
      expect(result, isNull);
      expect(scraper.queries, isEmpty); // never queried
    });
  });
}
