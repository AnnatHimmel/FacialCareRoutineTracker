import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/scanned_product_info.dart';
import '../retailer_search_scraper.dart';

/// Scrapes yesstyle.com — a server-rendered Asian beauty/fashion retailer with
/// strong K-beauty/J-beauty coverage. Search works for both product names and
/// barcodes. Two-step flow: search list page → first real result → product page.
///
/// Android-only: the cross-origin requests are blocked by CORS on web.
class YesStyleScraper implements RetailerSearchScraper {
  static const _host = 'https://www.yesstyle.com';

  final http.Client _client;

  YesStyleScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  bool get supportsBarcodeSearch => true;

  static const _headers = {
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  @override
  Future<ScannedProductInfo?> search(String query) async {
    if (kIsWeb) return null;
    try {
      final searchUri = Uri.parse(
        '$_host/en/list.html?q=${Uri.encodeComponent(query)}',
      );
      final searchRes = await _client
          .get(searchUri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (searchRes.statusCode != 200) return null;

      final link = _firstResultLink(searchRes.body);
      if (link == null) {
        if (kDebugMode) debugPrint('[YesStyle] no result link for "$query"');
        return null;
      }

      final productUri =
          Uri.parse(link.startsWith('http') ? link : '$_host$link');
      final productRes = await _client
          .get(productUri, headers: _headers)
          .timeout(const Duration(seconds: 8));
      if (productRes.statusCode != 200) return null;

      return _parseProduct(productRes.body);
    } catch (e) {
      if (kDebugMode) debugPrint('[YesStyle] error: $e');
      return null;
    }
  }

  /// First product link inside a search-result grid item. Real results sit in
  /// anchors whose class contains "itemContainer"; promotional/navbar links
  /// (which also point at /info.html/pid.N) are excluded.
  static String? _firstResultLink(String html) {
    final m = RegExp(
            r'<a class="[^"]*itemContainer[^"]*"[^>]*href="([^"]+/info\.html/pid\.\d+[^"]*)"')
        .firstMatch(html);
    return m?.group(1);
  }

  ScannedProductInfo? _parseProduct(String html) {
    // Prefer the JSON-LD Product block (clean name + brand + image).
    final ld = _productJsonLd(html);
    String? name;
    String? brand;
    String? image;

    if (ld != null) {
      name = _nonEmpty(ld['name'] as String?);
      brand = _extractBrand(ld['brand']);
      image = _extractImage(ld['image']);
    }

    // Fall back to Open Graph tags (og:title carries a " | YesStyle" suffix).
    name ??= _stripSuffix(_nonEmpty(_firstGroup(
        html, RegExp('og:title["\'][^>]*content="([^"]+)"'))));
    image ??= _nonEmpty(
        _firstGroup(html, RegExp('og:image["\'][^>]*content="([^"]+)"')));

    if (name == null && brand == null) return null;

    if (kDebugMode) {
      debugPrint('[YesStyle] ✓ name=$name | brand=$brand | image=$image');
    }

    return ScannedProductInfo(
      barcode: '',
      name: name,
      brand: brand,
      imageUrls: image == null ? const [] : [image],
    );
  }

  /// Finds and decodes the first JSON-LD block whose `@type` is `Product`.
  static Map<String, dynamic>? _productJsonLd(String html) {
    final blocks = RegExp(
      r'<script[^>]+application/ld\+json[^>]*>(.*?)</script>',
      dotAll: true,
    ).allMatches(html);
    for (final b in blocks) {
      try {
        final raw = b.group(1);
        if (raw == null) continue;
        final decoded = jsonDecode(raw.trim());
        final data = decoded is List ? decoded.firstOrNull : decoded;
        if (data is Map<String, dynamic> &&
            (data['@type'] as String?)?.toLowerCase() == 'product') {
          return data;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static String? _extractBrand(dynamic raw) {
    if (raw is Map<String, dynamic>) return _nonEmpty(raw['name'] as String?);
    if (raw is String) return _nonEmpty(raw);
    return null;
  }

  static String? _extractImage(dynamic raw) {
    if (raw is List && raw.isNotEmpty) return _nonEmpty(raw.first as String?);
    if (raw is String) return _nonEmpty(raw);
    return null;
  }

  static String? _stripSuffix(String? s) {
    if (s == null) return null;
    final i = s.indexOf('| YesStyle');
    return _nonEmpty(i == -1 ? s : s.substring(0, i));
  }

  static String? _firstGroup(String input, RegExp re) =>
      re.firstMatch(input)?.group(1);

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
