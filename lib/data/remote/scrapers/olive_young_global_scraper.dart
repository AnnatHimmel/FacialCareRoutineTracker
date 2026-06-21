import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/scanned_product_info.dart';
import '../retailer_search_scraper.dart';

/// Scrapes the Olive Young **Global** storefront (global.oliveyoung.com), the
/// English K-beauty site (the Korean .co.kr site is geo-blocked). Search runs
/// against the site's internal product-list JSON endpoint.
///
/// Only name search works — the endpoint returns no results for raw barcodes, so
/// a barcode query simply yields null. Android-only: the cross-origin POST is
/// blocked by CORS on web.
class OliveYoungGlobalScraper implements RetailerSearchScraper {
  static const _endpoint =
      'https://global.oliveyoung.com/display/search/product-list';
  static const _imageBase = 'https://image.oliveyoung.com/';

  final http.Client _client;

  OliveYoungGlobalScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  bool get supportsBarcodeSearch => false;

  @override
  Future<ScannedProductInfo?> search(String query) async {
    if (kIsWeb) return null;
    try {
      final res = await _client
          .post(
            Uri.parse(_endpoint),
            headers: const {
              'User-Agent': 'Mozilla/5.0',
              'X-Requested-With': 'XMLHttpRequest',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'query': query}),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final hit = (((json['search'] as Map<String, dynamic>?)?['hits']
              as Map<String, dynamic>?)?['hit'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>()
          .firstOrNull;
      final fields = hit?['fields'] as Map<String, dynamic>?;
      if (fields == null) return null;

      final name = _nonEmpty(fields['prdtName'] as String?);
      final brand = _nonEmpty(fields['brandName'] as String?);
      if (name == null && brand == null) return null;

      final imagePath = _nonEmpty(fields['imagePath'] as String?);
      final image = imagePath == null ? null : '$_imageBase$imagePath';

      if (kDebugMode) {
        debugPrint('[OliveYoungGlobal] ✓ name=$name | brand=$brand | '
            'image=$image | category=${fields['ctgrName']}');
      }

      return ScannedProductInfo(
        barcode: '',
        name: name,
        brand: brand,
        imageUrls: image == null ? const [] : [image],
        categoryHint: _nonEmpty(fields['ctgrName'] as String?),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[OliveYoungGlobal] error: $e');
      return null;
    }
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
