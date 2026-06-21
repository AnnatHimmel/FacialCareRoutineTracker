import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../domain/entities/scanned_product_info.dart';
import '../retailer_search_scraper.dart';

class OpenBeautyFactsNameSearchScraper implements RetailerSearchScraper {
  final http.Client _client;

  OpenBeautyFactsNameSearchScraper({http.Client? client})
      : _client = client ?? http.Client();

  @override
  bool get supportsBarcodeSearch => false;

  @override
  Future<ScannedProductInfo?> search(String query) async {
    try {
      final uri = Uri.parse(
        'https://world.openbeautyfacts.org/cgi/search.pl'
        '?search_terms=${Uri.encodeComponent(query)}'
        '&search_simple=1&action=process&json=1&page_size=5',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final products = (json['products'] as List<dynamic>?)?.whereType<Map<String, dynamic>>();
      final product = products?.firstOrNull;
      if (product == null) return null;

      final name = _nonEmpty(product['product_name'] as String?);
      final brand = _nonEmpty(product['brands'] as String?);
      if (name == null && brand == null) return null;

      final categoryHint = (product['categories_tags'] as List<dynamic>?)
          ?.whereType<String>()
          .where((c) => c.startsWith('en:'))
          .map((c) => c.replaceFirst('en:', '').replaceAll('-', ' '))
          .firstOrNull;

      final imageUrls = _extractImageUrls(product);

      if (kDebugMode) {
        debugPrint('[OBF-search($query)] ✓ '
            'name=$name | brand=$brand | '
            'images(${imageUrls.length})=$imageUrls | '
            'categoryHint=$categoryHint | '
            'ingredients=${_nonEmpty(product['ingredients_text'] as String?)} | '
            'quantity=${_nonEmpty(product['quantity'] as String?)}');
      }

      return ScannedProductInfo(
        barcode: '',
        name: name,
        brand: brand,
        imageUrls: imageUrls,
        categoryHint: categoryHint,
        ingredients: _nonEmpty(product['ingredients_text'] as String?),
        quantity: _nonEmpty(product['quantity'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  static List<String> _extractImageUrls(Map<String, dynamic> product) {
    final urls = <String?>[
      product['image_url'] as String?,
      product['image_front_url'] as String?,
    ];
    final selected = product['selected_images'];
    if (selected is Map<String, dynamic>) {
      for (final imageType in selected.values) {
        if (imageType is! Map<String, dynamic>) continue;
        final display = imageType['display'];
        if (display is! Map<String, dynamic>) continue;
        for (final url in display.values) {
          if (url is String) urls.add(url);
        }
      }
    }
    final seen = <String>{};
    final result = <String>[];
    for (final raw in urls) {
      final url = _nonEmpty(raw);
      if (url != null && seen.add(url)) result.add(url);
    }
    return result;
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
