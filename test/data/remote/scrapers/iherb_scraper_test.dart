import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/scrapers/iherb_scraper.dart';

void main() {
  group('IHerbScraper', () {
    // Search page: iHerb keeps you on /search (og:title "Search - <kw>") and
    // links each result via a single-quoted `href = '.../pr/<slug>/<id>'`
    // anchor. A barcode query returns a single product.
    const searchHtml = '''
<!DOCTYPE html><html><head>
<meta property="og:title" content="Search - 8809728080064" />
</head><body>
<a href="https://il.iherb.com/cms/brands">Brands</a>
<div class="product-cell-container">
  <a class='absolute-link-wrapper' data-ds-target='link' href = 'https://il.iherb.com/pr/iunik-centella-bubble-cleansing-foam-5-07-fl-oz-150-ml/116020' title='iUNIK'>
    <img src="x"/>
  </a>
  <a class='stars scroll-to' href = 'https://il.iherb.com/pr/iunik-centella-bubble-cleansing-foam-5-07-fl-oz-150-ml/116020' aria-label='rating stars'></a>
</div>
</body></html>
''';

    const productHtmlJsonLd = '''
<!DOCTYPE html><html><head>
<meta property="og:title" content="iUNIK, Centella Bubble Cleansing Foam, 5.07 fl oz (150 ml)"/>
<meta property="og:image" content="https://cloudinary.images-iherb.com/image/upload/f_auto/images/iuk/iuk08006/s/33.jpg"/>
<script type="application/ld+json">{"@type":"BreadcrumbList","itemListElement":[]}</script>
<script type="application/ld+json">{"@type":"Product","name":"iUNIK, Centella Bubble Cleansing Foam, 5.07 fl oz (150 ml)","image":"https://cloudinary.images-iherb.com/image/upload/f_auto/images/iuk/iuk08006/g/33.jpg","brand":{"@type":"Brand","name":"iUNIK"}}</script>
</head><body></body></html>
''';

    http.Response routed(http.Request req,
        {required String search, required String product}) {
      if (req.url.path.contains('/search')) return http.Response(search, 200);
      if (req.url.path.contains('/pr/')) return http.Response(product, 200);
      return http.Response('', 404);
    }

    test('supports barcode search', () {
      expect(IHerbScraper().supportsBarcodeSearch, isTrue);
    });

    test('searches /search, follows the /pr/ link, extracts from JSON-LD',
        () async {
      late Uri searchUri;
      final client = MockClient((req) async {
        if (req.url.path.contains('/search')) searchUri = req.url;
        return routed(req, search: searchHtml, product: productHtmlJsonLd);
      });

      final scraper = IHerbScraper(client: client);
      final result = await scraper.search('8809728080064');

      expect(result, isNotNull);
      expect(result!.name, 'iUNIK, Centella Bubble Cleansing Foam, 5.07 fl oz (150 ml)');
      expect(result.brand, 'iUNIK');
      expect(result.imageUrls,
          ['https://cloudinary.images-iherb.com/image/upload/f_auto/images/iuk/iuk08006/g/33.jpg']);
      expect(result.barcode, '');
      // Query is passed via the kw= parameter.
      expect(searchUri.queryParameters['kw'], '8809728080064');
    });

    test('skips non-product links, only follows the /pr/ result', () async {
      String? requestedProductPath;
      final client = MockClient((req) async {
        if (req.url.path.contains('/pr/')) {
          requestedProductPath = req.url.path;
        }
        return routed(req, search: searchHtml, product: productHtmlJsonLd);
      });

      final scraper = IHerbScraper(client: client);
      await scraper.search('iunik centella');

      expect(requestedProductPath, contains('/116020'));
      expect(requestedProductPath, isNot(contains('/cms/brands')));
    });

    test('falls back to og:title and og:image when no JSON-LD Product',
        () async {
      const productOgOnly = '''
<!DOCTYPE html><html><head>
<meta property="og:title" content="Beauty of Joseon, Relief Sun, Rice + Probiotics, SPF 50+"/>
<meta property="og:image" content="https://cloudinary.images-iherb.com/image/upload/og.jpg"/>
</head><body></body></html>
''';
      final client = MockClient((req) async =>
          routed(req, search: searchHtml, product: productOgOnly));

      final scraper = IHerbScraper(client: client);
      final result = await scraper.search('beauty of joseon');

      expect(result, isNotNull);
      expect(result!.name, 'Beauty of Joseon, Relief Sun, Rice + Probiotics, SPF 50+');
      expect(result.imageUrls,
          ['https://cloudinary.images-iherb.com/image/upload/og.jpg']);
    });

    test('returns null when search has no /pr/ product link', () async {
      const noResults = '''
<html><body><a href="https://il.iherb.com/cms/brands">Brands</a></body></html>
''';
      final client = MockClient((req) async {
        if (req.url.path.contains('/search')) {
          return http.Response(noResults, 200);
        }
        return http.Response('', 404);
      });
      final scraper = IHerbScraper(client: client);
      expect(await scraper.search('nothing'), isNull);
    });

    test('returns null on search non-200', () async {
      final client = MockClient((req) async => http.Response('', 503));
      final scraper = IHerbScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });

    test('returns null on product non-200', () async {
      final client = MockClient((req) async {
        if (req.url.path.contains('/search')) {
          return http.Response(searchHtml, 200);
        }
        return http.Response('', 404);
      });
      final scraper = IHerbScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });

    test('returns null on network error', () async {
      final client = MockClient((req) async => throw Exception('boom'));
      final scraper = IHerbScraper(client: client);
      expect(await scraper.search('x'), isNull);
    });
  });
}
