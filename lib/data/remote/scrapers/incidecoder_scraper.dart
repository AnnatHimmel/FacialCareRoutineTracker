import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/scanned_product_info.dart';
import '../retailer_search_scraper.dart';

/// Scrapes incidecoder.com — a server-rendered cosmetics ingredient database
/// with strong Korean/Japanese/European coverage. Two-step flow: search for the
/// product, then fetch its page for name, brand, image, and full INCI list.
class IncidecoderScraper implements RetailerSearchScraper {
  static const _host = 'https://incidecoder.com';

  final http.Client _client;

  IncidecoderScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  bool get supportsBarcodeSearch => false;

  @override
  Future<ScannedProductInfo?> search(String query) async {
    if (kIsWeb) return null;
    try {
      final searchUri = Uri.parse(
        '$_host/search?query=${Uri.encodeComponent(query)}',
      );
      final searchRes = await _client
          .get(searchUri, headers: const {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));
      if (searchRes.statusCode != 200) return null;

      final slug = _firstProductSlug(searchRes.body);
      if (slug == null) {
        if (kDebugMode) debugPrint('[Incidecoder] no product link for "$query"');
        return null;
      }

      final productRes = await _client
          .get(Uri.parse('$_host$slug'),
              headers: const {'User-Agent': 'Mozilla/5.0'})
          .timeout(const Duration(seconds: 8));
      if (productRes.statusCode != 200) return null;

      final result = _parseProduct(productRes.body);
      if (result == null) return null;

      // Reject false matches: if the parsed product name shares no word tokens
      // with the original query, Incidecoder returned an unrelated product.
      if (!_hasNameOverlap(query, result.name)) {
        if (kDebugMode) {
          debugPrint('[Incidecoder] false-match discarded '
              '(query="$query", name=${result.name})');
        }
        return null;
      }

      return result;
    } catch (e) {
      if (kDebugMode) debugPrint('[Incidecoder] error: $e');
      return null;
    }
  }

  /// Returns true if [productName] shares at least one meaningful word token
  /// (length > 2) with [query], case-insensitively.
  static bool _hasNameOverlap(String query, String? productName) {
    if (productName == null) return false;
    final queryTokens = _tokenize(query);
    if (queryTokens.isEmpty) return true; // can't judge — allow
    final nameTokens = _tokenize(productName);
    return queryTokens.any(nameTokens.contains);
  }

  static Set<String> _tokenize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.length > 2)
      .toSet();

  /// First `/products/<slug>` href in the search results, skipping the
  /// "/products/create" call-to-action link.
  static String? _firstProductSlug(String html) {
    for (final m in RegExp(r'href="(/products/[^"]+)"').allMatches(html)) {
      final href = m.group(1);
      if (href == null) continue;
      if (href == '/products/create') continue;
      return href;
    }
    return null;
  }

  ScannedProductInfo? _parseProduct(String html) {
    final name = _nonEmpty(_firstGroup(
        html, RegExp(r'id="product-title"[^>]*>([^<]+)<')));
    // Brand sits inside an <a> within the brand-title span.
    final brand = _nonEmpty(_firstGroup(
        html,
        RegExp(r'id="product-brand-title"[^>]*>\s*<a[^>]*>([^<]+)</a>',
            dotAll: true)));

    if (name == null && brand == null) return null;

    final image = _firstGroup(
        html,
        RegExp(
            r'<img[^>]+src="(https://incidecoder-content\.storage\.googleapis\.com/[^"]*/ingredients/[^"]+)"'));

    // Full INCI list lives in the meta description after "ingredients explained:".
    final desc = _firstGroup(
        html, RegExp(r'name="description"[^>]+content="([^"]*)"'));
    String? ingredients;
    if (desc != null) {
      final marker = desc.indexOf('ingredients explained:');
      if (marker != -1) {
        ingredients =
            _nonEmpty(desc.substring(marker + 'ingredients explained:'.length));
      }
    }

    if (kDebugMode) {
      debugPrint('[Incidecoder] ✓ name=$name | brand=$brand | '
          'image=$image | ingredients=$ingredients');
    }

    return ScannedProductInfo(
      barcode: '',
      name: name,
      brand: brand,
      imageUrls: image == null ? const [] : [image],
      ingredients: ingredients,
    );
  }

  static String? _firstGroup(String input, RegExp re) =>
      re.firstMatch(input)?.group(1);

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
