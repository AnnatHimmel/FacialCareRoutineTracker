import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:skincare_tracker/data/remote/scrapers/olive_young_global_scraper.dart';

void main() {
  group('OliveYoungGlobalScraper', () {
    Map<String, dynamic> hitsResponse(List<Map<String, dynamic>> fieldsList) => {
          'search': {
            'hits': {
              'found': fieldsList.length,
              'start': 0,
              'hit': [
                for (final f in fieldsList) {'fields': f},
              ],
            },
          },
        };

    test('POSTs query and extracts name/brand/image/category from first hit',
        () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        if (request.method == 'POST' &&
            request.url.path == '/display/search/product-list') {
          return http.Response(
            jsonEncode(hitsResponse([
              {
                'prdtName': 'ETUDE Soonjung 2x Barrier Intensive Cream 60ml',
                'brandName': 'ETUDE',
                'imagePath': 'prdtImg/1935/abc.jpg',
                'prdtNo': 'GA250128321',
                'ctgrName': 'Cream',
              }
            ])),
            200,
          );
        }
        return http.Response('', 405);
      });

      final scraper = OliveYoungGlobalScraper(client: client);
      final result = await scraper.search('Soonjung Barrier Cream');

      expect(result, isNotNull);
      expect(result!.name, 'ETUDE Soonjung 2x Barrier Intensive Cream 60ml');
      expect(result.brand, 'ETUDE');
      expect(result.imageUrls,
          ['https://image.oliveyoung.com/prdtImg/1935/abc.jpg']);
      expect(result.categoryHint, 'Cream');
      expect(result.barcode, '');

      // Sent the query as JSON body
      expect(captured.headers['content-type'], contains('application/json'));
      expect(jsonDecode(captured.body), {'query': 'Soonjung Barrier Cream'});
    });

    test('returns null when no hits found', () async {
      final client = MockClient((request) async =>
          http.Response(jsonEncode(hitsResponse([])), 200));
      final scraper = OliveYoungGlobalScraper(client: client);
      expect(await scraper.search('no such product'), isNull);
    });

    test('returns null on non-200', () async {
      final client = MockClient((request) async => http.Response('', 405));
      final scraper = OliveYoungGlobalScraper(client: client);
      expect(await scraper.search('anything'), isNull);
    });

    test('returns null on network error', () async {
      final client = MockClient((request) async => throw Exception('boom'));
      final scraper = OliveYoungGlobalScraper(client: client);
      expect(await scraper.search('anything'), isNull);
    });
  });
}
