import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/scrapers/incidecoder_scraper.dart';

void main() {
  group('IncidecoderScraper', () {
    const searchHtml = '''
<!DOCTYPE html>
<html><body>
<a href="/products/etude-house-soon-jung-2x-barrier-intensive-cream-3" class="klavika">Etude House Soon Jung 2x Barrier Intensive Cream</a>
<a href="/products/create">Add a product</a>
</body></html>
''';

    const productHtml = '''
<!DOCTYPE html>
<html>
<head>
<title>Etude House Soon Jung 2x Barrier Intensive Cream ingredients (Explained)</title>
<meta name="description" content="Etude House Soon Jung 2x Barrier Intensive Cream ingredients explained: Water, Propanediol, Glycerin, Panthenol, Madecassoside">
</head>
<body>
<h1>
  <div class="fs21 normal"><span id="product-brand-title"><a href="/brands/etude-house" class="underline">Etude House</a></span></div>
  <div class="klavikab lilac"><span id="product-title">Soon Jung 2x Barrier Intensive Cream</span></div>
</h1>
<img src="https://incidecoder-content.storage.googleapis.com/abc/ingredients/etude-house-soon-jung-2x-barrier-intensive-cream-3/etude-house-soon-jung-2x-barrier-intensive-cream-3_original.jpeg">
</body>
</html>
''';

    test('searches then fetches product page, extracts name/brand/image/ingredients',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(searchHtml, 200);
        }
        if (request.url.path.startsWith('/products/')) {
          return http.Response(productHtml, 200);
        }
        return http.Response('', 404);
      });

      final scraper = IncidecoderScraper(client: client);
      final result = await scraper.search('Etude Soonjung 2x Barrier Intensive Cream');

      expect(result, isNotNull);
      expect(result!.name, 'Soon Jung 2x Barrier Intensive Cream');
      expect(result.brand, 'Etude House');
      expect(result.imageUrls, [
        'https://incidecoder-content.storage.googleapis.com/abc/ingredients/etude-house-soon-jung-2x-barrier-intensive-cream-3/etude-house-soon-jung-2x-barrier-intensive-cream-3_original.jpeg'
      ]);
      expect(result.ingredients,
          'Water, Propanediol, Glycerin, Panthenol, Madecassoside');
      expect(result.barcode, '');
    });

    test('returns null when search has no real product links', () async {
      const emptySearch = '''
<html><body><a href="/products/create">Add a product</a></body></html>
''';
      final client = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(emptySearch, 200);
        }
        return http.Response('', 404);
      });

      final scraper = IncidecoderScraper(client: client);
      final result = await scraper.search('no such product');

      expect(result, isNull);
    });

    test('returns null on search non-200', () async {
      final client = MockClient((request) async => http.Response('', 500));
      final scraper = IncidecoderScraper(client: client);
      expect(await scraper.search('anything'), isNull);
    });

    test('returns null on product page non-200', () async {
      final client = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(searchHtml, 200);
        }
        return http.Response('', 404);
      });
      final scraper = IncidecoderScraper(client: client);
      expect(await scraper.search('anything'), isNull);
    });

    test('returns null on network error', () async {
      final client = MockClient((request) async => throw Exception('boom'));
      final scraper = IncidecoderScraper(client: client);
      expect(await scraper.search('anything'), isNull);
    });

    // Name-similarity guard: if the product Incidecoder returns shares no word
    // tokens with the original query, it is a false match and must be discarded.
    test('returns null when result name has no token overlap with query', () async {
      // Simulates the "Zero Pore Pads" → "Quia" false-match:
      // Incidecoder finds a product link but the product page is for an
      // unrelated item whose name shares zero words with the query.
      const mismatchedSearchHtml = '''
<!DOCTYPE html>
<html><body>
<a href="/products/quia-brightening-toner-1" class="klavika">Quia Brightening Toner</a>
</body></html>
''';
      const mismatchedProductHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta name="description" content="Soft Brightening Toner ingredients explained: Water, Glycerin">
</head>
<body>
<h1>
  <div class="fs21 normal"><span id="product-brand-title"><a href="/brands/quia">Quia</a></span></div>
  <div class="klavikab lilac"><span id="product-title">Soft Brightening Toner</span></div>
</h1>
</body>
</html>
''';

      final client = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(mismatchedSearchHtml, 200);
        }
        if (request.url.path.startsWith('/products/')) {
          return http.Response(mismatchedProductHtml, 200);
        }
        return http.Response('', 404);
      });

      final scraper = IncidecoderScraper(client: client);
      // Query tokens: ["zero", "pore", "pads"] — none appear in "Soft Brightening Toner"
      final result = await scraper.search('zero pore pads');
      expect(result, isNull, reason: 'False-match product must be discarded');
    });

    test('accepts result when at least one query token appears in product name',
        () async {
      final client = MockClient((request) async {
        if (request.url.path == '/search') {
          return http.Response(searchHtml, 200);
        }
        if (request.url.path.startsWith('/products/')) {
          return http.Response(productHtml, 200);
        }
        return http.Response('', 404);
      });

      final scraper = IncidecoderScraper(client: client);
      // "Jung" and "Intensive" and "Cream" all appear in the product name
      final result = await scraper.search('Jung Intensive Cream');
      expect(result, isNotNull, reason: 'Matching product must be returned');
    });
  });
}
