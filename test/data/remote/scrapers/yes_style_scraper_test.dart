import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/scrapers/yes_style_scraper.dart';

void main() {
  group('YesStyleScraper', () {
    // Search page: a promo link in the navbar (must be skipped) + a real result
    // inside an "itemContainer" anchor.
    const searchHtml = '''
<!DOCTYPE html><html><body>
<a href="/en/promo-product/info.html/pid.999" class="navbar-module-scss-module__abc__listItem">Promo</a>
<div class="listImageGrid-module-scss-module__20EZDa__imageGridWrapper">
  <a class="listImageGrid-module-scss-module__20EZDa__itemContainer MuiBox-root mui-0" href="/en/etude-soon-jung-2x-barrier-intensive-cream-60ml-2021-new/info.html/pid.1058617520">
    <img src="x"/>
  </a>
</div>
</body></html>
''';

    const productHtmlJsonLd = '''
<!DOCTYPE html><html><head>
<meta property="og:title" content="Etude - Soon Jung 2x Barrier Intensive Cream | YesStyle"/>
<meta property="og:image" content="https://d1flfk77wl2xk4.cloudfront.net/Assets/og.jpg"/>
<script type="application/ld+json">{"itemListElement":[{"item":{"@type":"Thing","name":"Home"},"@type":"ListItem","position":1}]}</script>
<script type="application/ld+json">{"@type":"Product","name":"Soon Jung 2x Barrier Intensive Cream","image":"https://d1flfk77wl2xk4.cloudfront.net/Assets/l_p123.jpg","brand":{"@type":"Brand","name":"Etude"},"offers":[{"@type":"Offer","price":"15.00"}]}</script>
</head><body></body></html>
''';

    http.Response routed(http.Request req,
        {required String search, required String product}) {
      if (req.url.path.contains('list.html')) return http.Response(search, 200);
      if (req.url.path.contains('info.html')) return http.Response(product, 200);
      return http.Response('', 404);
    }

    test('searches list.html, picks itemContainer link, extracts from JSON-LD',
        () async {
      late Uri searchUri;
      final client = MockClient((req) async {
        if (req.url.path.contains('list.html')) searchUri = req.url;
        return routed(req, search: searchHtml, product: productHtmlJsonLd);
      });

      final scraper = YesStyleScraper(client: client);
      final result = await scraper.search('8809820688618');

      expect(result, isNotNull);
      expect(result!.name, 'Soon Jung 2x Barrier Intensive Cream');
      expect(result.brand, 'Etude');
      expect(result.imageUrls,
          ['https://d1flfk77wl2xk4.cloudfront.net/Assets/l_p123.jpg']);
      expect(result.barcode, '');
      // Query is passed via the q= parameter.
      expect(searchUri.queryParameters['q'], '8809820688618');
    });

    test('skips promo/navbar links, only follows itemContainer result',
        () async {
      String? requestedProductPath;
      final client = MockClient((req) async {
        if (req.url.path.contains('info.html')) {
          requestedProductPath = req.url.path;
        }
        return routed(req, search: searchHtml, product: productHtmlJsonLd);
      });

      final scraper = YesStyleScraper(client: client);
      await scraper.search('etude soonjung');

      // Followed the real grid product (pid.1058617520), not the promo (pid.999).
      expect(requestedProductPath, contains('pid.1058617520'));
      expect(requestedProductPath, isNot(contains('pid.999')));
    });

    test('falls back to og:title (stripping " | YesStyle") and og:image', () async {
      const productOgOnly = '''
<!DOCTYPE html><html><head>
<meta property="og:title" content="Beauty of Joseon - Relief Sun Mini | YesStyle"/>
<meta property="og:image" content="https://d1flfk77wl2xk4.cloudfront.net/Assets/og.jpg"/>
</head><body></body></html>
''';
      final client = MockClient((req) async =>
          routed(req, search: searchHtml, product: productOgOnly));

      final scraper = YesStyleScraper(client: client);
      final result = await scraper.search('beauty of joseon');

      expect(result, isNotNull);
      expect(result!.name, 'Beauty of Joseon - Relief Sun Mini');
      expect(result.imageUrls,
          ['https://d1flfk77wl2xk4.cloudfront.net/Assets/og.jpg']);
    });

    test('returns null when search has no grid product link', () async {
      const noResults = '''
<html><body><a href="/en/promo/info.html/pid.999" class="navbar-module-scss-module__x__listItem">Promo</a></body></html>
''';
      final client = MockClient((req) async {
        if (req.url.path.contains('list.html')) {
          return http.Response(noResults, 200);
        }
        return http.Response('', 404);
      });
      final scraper = YesStyleScraper(client: client);
      expect(await scraper.search('nothing'), isNull);
    });

    test('returns null on search non-200', () async {
      final client = MockClient((req) async => http.Response('', 503));
      final scraper = YesStyleScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });

    test('returns null on product non-200', () async {
      final client = MockClient((req) async {
        if (req.url.path.contains('list.html')) {
          return http.Response(searchHtml, 200);
        }
        return http.Response('', 404);
      });
      final scraper = YesStyleScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });

    test('returns null on network error', () async {
      final client = MockClient((req) async => throw Exception('boom'));
      final scraper = YesStyleScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });
  });
}
