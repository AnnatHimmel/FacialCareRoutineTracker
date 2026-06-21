import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/scanned_product_info.dart';
import 'retailer_search_scraper.dart';

class BarcodeProductLookupService {
  final http.Client _client;
  final List<RetailerSearchScraper> _scrapers;

  BarcodeProductLookupService({
    http.Client? client,
    List<RetailerSearchScraper> scrapers = const [],
  })  : _client = client ?? http.Client(),
        _scrapers = scrapers;

  Future<ScannedProductInfo?> lookup(String barcode) async {
    try {
      final results = await Future.wait([
        _lookupOpenBeautyFacts(barcode),
        _lookupOpenFoodFacts(barcode),
        _lookupUpcItemDb(barcode),
        _lookupInciBeauty(barcode),
        _lookupBarcodeSpider(barcode),
      ]);

      final obf = results[0];
      final off = results[1];
      final upc = results[2];
      final inci = results[3];
      final spider = results[4];

      const labels = ['OBF', 'OFF', 'UPC', 'InciBeauty', 'BarcodeSpider'];
      if (kDebugMode) {
        // Raw data returned by each service (every field).
        for (var i = 0; i < results.length; i++) {
          final r = results[i];
          if (r == null) {
            debugPrint('[Barcode:$barcode] ${labels[i]}: —');
            continue;
          }
          debugPrint('[Barcode:$barcode] ${labels[i]}: ✓ '
              'name=${r.name} | brand=${r.brand} | '
              'images(${r.imageUrls.length})=${r.imageUrls} | '
              'categoryHint=${r.categoryHint} | '
              'ingredients=${r.ingredients} | '
              'comment=${r.comment} | '
              'quantity=${r.quantity}');
        }
      }

      if (obf == null && off == null && upc == null && inci == null && spider == null) {
        if (kDebugMode) debugPrint('[Barcode:$barcode] no source matched');
        return _augmentWithScrapers(barcode, null);
      }

      // Priority: OBF > OFF > UPC > InciBeauty > BarcodeSpider
      if (kDebugMode) {
        // For a given field selector, report which source the merged value came from.
        String winner(Object? Function(ScannedProductInfo?) sel) {
          for (var i = 0; i < results.length; i++) {
            if (sel(results[i]) != null) return labels[i];
          }
          return '—';
        }
        debugPrint('[Barcode:$barcode] merged field sources → '
            'name=${winner((r) => r?.name)} | '
            'brand=${winner((r) => r?.brand)} | '
            'categoryHint=${winner((r) => r?.categoryHint)} | '
            'ingredients=${winner((r) => r?.ingredients)} | '
            'comment=${winner((r) => r?.comment)} | '
            'quantity=${winner((r) => r?.quantity)} | '
            'firstImage=${winner((r) => r?.imageUrl)}');
      }

      // Combine all candidate images across sources, priority OBF > OFF > UPC >
      // InciBeauty, deduped (first occurrence wins).
      final imageUrls = _dedupNonEmpty([
        ...?obf?.imageUrls,
        ...?off?.imageUrls,
        ...?upc?.imageUrls,
        ...?inci?.imageUrls,
      ]);
      if (kDebugMode) {
        debugPrint('[Barcode:$barcode] merged candidate images '
            '(${imageUrls.length}): $imageUrls');
      }

      final merged = ScannedProductInfo(
        barcode: barcode,
        name: obf?.name ?? off?.name ?? upc?.name ?? inci?.name ?? spider?.name,
        brand: obf?.brand ?? off?.brand ?? upc?.brand ?? inci?.brand ?? spider?.brand,
        imageUrls: imageUrls,
        categoryHint: obf?.categoryHint ?? off?.categoryHint ?? upc?.categoryHint ?? inci?.categoryHint,
        ingredients: obf?.ingredients ?? off?.ingredients ?? inci?.ingredients,
        comment: obf?.comment ?? off?.comment ?? upc?.comment ?? inci?.comment,
        quantity: obf?.quantity ?? off?.quantity ?? upc?.quantity ?? inci?.quantity,
      );
      if (kDebugMode) {
        debugPrint('[Barcode:$barcode] merged result → '
            'name=${merged.name} | brand=${merged.brand} | '
            'categoryHint=${merged.categoryHint} | quantity=${merged.quantity} | '
            'images(${merged.imageUrls.length})=${merged.imageUrls} | '
            'ingredients=${merged.ingredients} | comment=${merged.comment}');
      }
      return _augmentWithScrapers(barcode, merged);
    } catch (_) {
      return null;
    }
  }

  Future<ScannedProductInfo?> _augmentWithScrapers(
    String barcode,
    ScannedProductInfo? base,
  ) async {
    if (_scrapers.isEmpty) return base;

    final baseName = base != null && base.hasUsefulData ? base.name : null;
    final useNameQuery = baseName != null;
    final query = useNameQuery ? baseName : barcode;

    if (kDebugMode) {
      if (useNameQuery) {
        debugPrint('[Barcode:$barcode] augment: by-name="$query"');
      } else {
        debugPrint('[Barcode:$barcode] augment: by-barcode (no base data)');
      }
    }

    final scraperResults = await Future.wait(
      _scrapers.map((s) => s.search(query)),
    );

    if (kDebugMode) {
      for (var i = 0; i < scraperResults.length; i++) {
        final r = scraperResults[i];
        final label = _scrapers[i].runtimeType.toString();
        if (r == null) {
          debugPrint('[Barcode:$barcode] $label($query): —');
        } else {
          debugPrint('[Barcode:$barcode] $label($query): ✓ '
              'name=${r.name} | brand=${r.brand} | '
              'images(${r.imageUrls.length})=${r.imageUrls}');
        }
      }
    }

    if (base == null || !base.hasUsefulData) {
      // Fallback: use first scraper result that has useful data and does not
      // look like a site-level title (e.g. Cloudflare challenge pages from
      // YesStyle return "YesStyle - Fashion and Beauty" as og:title).
      final fallback = scraperResults
          .whereType<ScannedProductInfo>()
          .where((r) => r.hasUsefulData && !_isSiteLevelName(r.name))
          .firstOrNull;
      if (fallback == null) return null;
      return ScannedProductInfo(
        barcode: barcode,
        name: fallback.name,
        brand: fallback.brand,
        imageUrls: fallback.imageUrls,
        categoryHint: fallback.categoryHint,
        ingredients: fallback.ingredients,
        comment: fallback.comment,
        quantity: fallback.quantity,
      );
    }

    // Augment: fill only null fields; append new images (deduped).
    String? brand = base.brand;
    String? categoryHint = base.categoryHint;
    String? ingredients = base.ingredients;
    String? comment = base.comment;
    String? quantity = base.quantity;
    final imageUrls = List<String>.from(base.imageUrls);

    for (final r in scraperResults.whereType<ScannedProductInfo>()) {
      brand ??= r.brand;
      categoryHint ??= r.categoryHint;
      ingredients ??= r.ingredients;
      comment ??= r.comment;
      quantity ??= r.quantity;
      for (final url in r.imageUrls) {
        if (!imageUrls.contains(url)) imageUrls.add(url);
      }
    }

    return ScannedProductInfo(
      barcode: barcode,
      name: base.name,
      brand: brand,
      imageUrls: imageUrls,
      categoryHint: categoryHint,
      ingredients: ingredients,
      comment: comment,
      quantity: quantity,
    );
  }

  // Matches generic site/page titles that scrapers may return from Cloudflare
  // challenge pages or non-product search results.
  static final _siteNamePattern = RegExp(
    r'(yesstyle|olive.?young|search|results|fashion|beauty)',
    caseSensitive: false,
  );

  static bool _isSiteLevelName(String? name) =>
      name != null && _siteNamePattern.hasMatch(name);

  Future<ScannedProductInfo?> _lookupOpenBeautyFacts(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openbeautyfacts.org/api/v2/product/$barcode.json',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if ((json['status'] as int?) != 1) return null;

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final categoryHint = (product['categories_tags'] as List<dynamic>?)
          ?.whereType<String>()
          .where((c) => c.startsWith('en:'))
          .map((c) => c.replaceFirst('en:', '').replaceAll('-', ' '))
          .firstOrNull;

      final name = _nonEmpty(product['product_name'] as String?);
      final brand = _nonEmpty(product['brands'] as String?);
      if (name == null && brand == null) return null;

      return ScannedProductInfo(
        barcode: barcode,
        name: name,
        brand: brand,
        imageUrls: _openFactsImages(product),
        categoryHint: categoryHint,
        ingredients: _nonEmpty(product['ingredients_text'] as String?),
        quantity: _nonEmpty(product['quantity'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ScannedProductInfo?> _lookupOpenFoodFacts(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
      );
      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      if ((json['status'] as int?) != 1) return null;

      final product = json['product'] as Map<String, dynamic>?;
      if (product == null) return null;

      final categoryHint = (product['categories_tags'] as List<dynamic>?)
          ?.whereType<String>()
          .where((c) => c.startsWith('en:'))
          .map((c) => c.replaceFirst('en:', '').replaceAll('-', ' '))
          .firstOrNull;

      final name = _nonEmpty(product['product_name'] as String?);
      final brand = _nonEmpty(product['brands'] as String?);
      if (name == null && brand == null) return null;

      return ScannedProductInfo(
        barcode: barcode,
        name: name,
        brand: brand,
        imageUrls: _openFactsImages(product),
        categoryHint: categoryHint,
        ingredients: _nonEmpty(product['ingredients_text'] as String?),
        quantity: _nonEmpty(product['quantity'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ScannedProductInfo?> _lookupUpcItemDb(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://api.upcitemdb.com/prod/trial/lookup?upc=$barcode',
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (json['items'] as List<dynamic>?)
          ?.whereType<Map<String, dynamic>>();
      final item = items?.firstOrNull;
      if (item == null) return null;

      final images = (item['images'] as List<dynamic>?)?.whereType<String>();

      final name = _nonEmpty(item['title'] as String?);
      final brand = _nonEmpty(item['brand'] as String?);
      if (name == null && brand == null) return null;

      return ScannedProductInfo(
        barcode: barcode,
        name: name,
        brand: brand,
        imageUrls: _dedupNonEmpty(images?.toList() ?? const []),
        categoryHint: _nonEmpty(item['category'] as String?),
        // UPCItemDB's "description" is a marketing blurb, not INCI — treat it as
        // a comment, not ingredients.
        comment: _nonEmpty(item['description'] as String?),
        quantity: _nonEmpty(item['size'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ScannedProductInfo?> _lookupInciBeauty(String barcode) async {
    try {
      final uri = Uri.parse(
        'https://world.incibeauty.com/en/produit/$barcode',
      );
      final response = await _client
          .get(uri, headers: {'Accept': 'text/html'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = response.body;

      // Extract JSON-LD schema.org product block
      final ldMatch = RegExp(
        '<script[^>]+type=["\']{1}application/ld\\+json["\']{1}[^>]*>(.*?)</script>',
        dotAll: true,
      ).allMatches(body);

      for (final match in ldMatch) {
        try {
          final raw = match.group(1);
          if (raw == null) continue;
          final decoded = jsonDecode(raw.trim());
          final data = decoded is List ? decoded.firstOrNull : decoded;
          if (data is! Map<String, dynamic>) continue;
          if ((data['@type'] as String?)?.toLowerCase() != 'product') continue;

          final name = _nonEmpty(data['name'] as String?);
          final brand = _nonEmpty(
            (data['brand'] is Map)
                ? (data['brand'] as Map<String, dynamic>)['name'] as String?
                : data['brand'] as String?,
          );
          if (name == null && brand == null) continue;

          final image = _nonEmpty(data['image'] as String?);
          return ScannedProductInfo(
            barcode: barcode,
            name: name,
            brand: brand,
            imageUrls: image == null ? const [] : [image],
            categoryHint: null,
            ingredients: _nonEmpty(data['description'] as String?),
            quantity: null,
          );
        } catch (_) {
          continue;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  Future<ScannedProductInfo?> _lookupBarcodeSpider(String barcode) async {
    try {
      final uri = Uri.parse('https://www.barcodespider.com/$barcode');
      final response = await _client
          .get(uri, headers: {
            'Accept': 'text/html',
            'User-Agent': 'Mozilla/5.0',
          })
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = response.body;

      // Try og:title meta tag first, then <h1>, then <title>
      String? name;
      final ogTitle = RegExp(
        '<meta[^>]+property=["\']{1}og:title["\']{1}[^>]+content=["\']{1}([^"\']+)["\']{1}',
      ).firstMatch(body)?.group(1);
      if (ogTitle != null && ogTitle.isNotEmpty) {
        name = _nonEmpty(ogTitle);
      } else {
        final h1 = RegExp(r'<h1[^>]*>([^<]+)</h1>').firstMatch(body)?.group(1);
        name = _nonEmpty(h1?.trim());
      }

      if (name == null) return null;

      // Try og:description for brand hint
      final ogDesc = RegExp(
        '<meta[^>]+property=["\']{1}og:description["\']{1}[^>]+content=["\']{1}([^"\']+)["\']{1}',
      ).firstMatch(body)?.group(1);

      return ScannedProductInfo(
        barcode: barcode,
        name: name,
        brand: null,
        categoryHint: _nonEmpty(ogDesc),
        ingredients: null,
        quantity: null,
      );
    } catch (_) {
      return null;
    }
  }

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();

  /// Trims, drops empty/null entries, and dedupes preserving first occurrence.
  static List<String> _dedupNonEmpty(List<String?> urls) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in urls) {
      final url = _nonEmpty(raw);
      if (url != null && seen.add(url)) result.add(url);
    }
    return result;
  }

  /// Gathers candidate image URLs from an Open(Beauty|Food)Facts product:
  /// `image_url`, `image_front_url`, and every `selected_images.*.display.*`.
  static List<String> _openFactsImages(Map<String, dynamic> product) {
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
    return _dedupNonEmpty(urls);
  }
}
