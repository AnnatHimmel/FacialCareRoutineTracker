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
      // Run the two barcode-based tiers concurrently:
      //  • Tier 1 — barcode-capable scrapers queried by the barcode (most
      //    accurate; overrides the APIs for the fields it provides).
      //  • Tier 2 — the 5 barcode-lookup APIs, merged among themselves.
      final tiers = await Future.wait([
        _scrapeByBarcode(barcode),
        _lookupBarcodeApis(barcode),
      ]);

      // Tier 1 placed first → its non-null fields win over the APIs.
      final base = _mergeInfos(barcode, [tiers[0], tiers[1]]);

      // Tier 3 — name-based augmentation via the name-only scrapers fills gaps.
      return _augmentWithScrapers(barcode, base);
    } catch (_) {
      return null;
    }
  }

  /// Queries every barcode-capable scraper with the raw [barcode] and returns
  /// the first result that carries useful, non-site-level data. The barcode is
  /// an exact key, so no name-similarity check is needed.
  Future<ScannedProductInfo?> _scrapeByBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return null;
    final capable =
        _scrapers.where((s) => s.supportsBarcodeSearch).toList();
    if (capable.isEmpty) return null;

    final results = await Future.wait(capable.map((s) => s.search(barcode)));

    if (kDebugMode) {
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        final label = capable[i].runtimeType.toString();
        debugPrint('[Barcode:$barcode] $label(by-barcode): '
            '${r == null ? '—' : '✓ name=${r.name} | brand=${r.brand}'}');
      }
    }

    return results
        .whereType<ScannedProductInfo>()
        .where((r) => r.hasUsefulData && !_isSiteLevelName(r.name))
        .firstOrNull;
  }

  /// Merges a priority-ordered list of [sources] into a single product:
  /// first non-null value wins for each scalar field, images are concatenated
  /// in order then deduped. Returns null when every source is null.
  ScannedProductInfo? _mergeInfos(
    String barcode,
    List<ScannedProductInfo?> sources,
  ) {
    final present = sources.whereType<ScannedProductInfo>().toList();
    if (present.isEmpty) return null;

    String? pick(String? Function(ScannedProductInfo) sel) {
      for (final s in present) {
        final v = sel(s);
        if (v != null) return v;
      }
      return null;
    }

    return ScannedProductInfo(
      barcode: barcode,
      name: pick((s) => s.name),
      brand: pick((s) => s.brand),
      imageUrls: _dedupImageUrls([for (final s in present) ...s.imageUrls]),
      categoryHint: pick((s) => s.categoryHint),
      ingredients: pick((s) => s.ingredients),
      comment: pick((s) => s.comment),
      quantity: pick((s) => s.quantity),
    );
  }

  /// The 5 barcode-lookup APIs, merged among themselves (priority
  /// OBF > OFF > UPC > InciBeauty > BarcodeSpider). Returns null when none
  /// matched.
  Future<ScannedProductInfo?> _lookupBarcodeApis(String barcode) async {
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
        return null;
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
      // InciBeauty, deduped at address level (first occurrence wins).
      final imageUrls = _dedupImageUrls([
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
      return merged;
    } catch (_) {
      return null;
    }
  }

  /// Looks a product up by its [name] (optionally narrowed by [brand]) instead
  /// of a barcode — used by the manual "find the details for me" flow. The
  /// barcode-only APIs can't help here, so this queries the [_scrapers] (which
  /// include name-search sources) with a single combined query, then merges
  /// their results the same way as the barcode path: first useful source wins
  /// for each scalar field, later sources fill the gaps, and images are
  /// appended deduped. Site-level / garbage names are rejected. Returns null
  /// when nothing usable was found.
  Future<ScannedProductInfo?> lookupByName(String name, {String? brand}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || _scrapers.isEmpty) return null;

    final trimmedBrand = brand?.trim();
    final query = (trimmedBrand != null && trimmedBrand.isNotEmpty)
        ? '$trimmedBrand $trimmedName'
        : trimmedName;

    final results = await Future.wait(_scrapers.map((s) => s.search(query)));

    if (kDebugMode) {
      for (var i = 0; i < results.length; i++) {
        final r = results[i];
        final label = _scrapers[i].runtimeType.toString();
        if (r == null) {
          debugPrint('[ByName:"$query"] $label: —');
        } else {
          debugPrint('[ByName:"$query"] $label: ✓ '
              'name=${r.name} | brand=${r.brand} | '
              'images(${r.imageUrls.length})=${r.imageUrls} | '
              'categoryHint=${r.categoryHint} | '
              'ingredients=${r.ingredients} | comment=${r.comment}');
        }
      }
    }

    final useful = results
        .whereType<ScannedProductInfo>()
        .where((r) => r.hasUsefulData && !_isSiteLevelName(r.name))
        .toList();
    if (useful.isEmpty) return null;

    String? mergedName;
    String? mergedBrand;
    String? categoryHint;
    String? ingredients;
    String? comment;
    String? quantity;
    final candidateImages = <String>[];

    for (final r in useful) {
      mergedName ??= r.name;
      mergedBrand ??= r.brand;
      categoryHint ??= r.categoryHint;
      ingredients ??= r.ingredients;
      comment ??= r.comment;
      quantity ??= r.quantity;
      candidateImages.addAll(r.imageUrls);
    }

    return ScannedProductInfo(
      barcode: '',
      name: mergedName,
      brand: mergedBrand,
      imageUrls: _dedupImageUrls(candidateImages),
      categoryHint: categoryHint,
      ingredients: ingredients,
      comment: comment,
      quantity: quantity,
    );
  }

  Future<ScannedProductInfo?> _augmentWithScrapers(
    String barcode,
    ScannedProductInfo? base,
  ) async {
    // Barcode-capable scrapers already ran by barcode in tier 1 — augment only
    // with the name-only scrapers so we don't re-query them by a fuzzy name.
    final nameScrapers =
        _scrapers.where((s) => !s.supportsBarcodeSearch).toList();
    if (nameScrapers.isEmpty) return base;

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
      nameScrapers.map((s) => s.search(query)),
    );

    if (kDebugMode) {
      for (var i = 0; i < scraperResults.length; i++) {
        final r = scraperResults[i];
        final label = nameScrapers[i].runtimeType.toString();
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
        imageUrls: _dedupImageUrls(fallback.imageUrls),
        categoryHint: fallback.categoryHint,
        ingredients: fallback.ingredients,
        comment: fallback.comment,
        quantity: fallback.quantity,
      );
    }

    // Augment: fill only null fields; append scraper images after the base
    // ones, deduped at address level (base copy of any shared image wins).
    String? brand = base.brand;
    String? categoryHint = base.categoryHint;
    String? ingredients = base.ingredients;
    String? comment = base.comment;
    String? quantity = base.quantity;
    final candidateImages = <String>[...base.imageUrls];

    for (final r in scraperResults.whereType<ScannedProductInfo>()) {
      brand ??= r.brand;
      categoryHint ??= r.categoryHint;
      ingredients ??= r.ingredients;
      comment ??= r.comment;
      quantity ??= r.quantity;
      candidateImages.addAll(r.imageUrls);
    }

    return ScannedProductInfo(
      barcode: barcode,
      name: base.name,
      brand: brand,
      imageUrls: _dedupImageUrls(candidateImages),
      categoryHint: categoryHint,
      ingredients: ingredients,
      comment: comment,
      quantity: quantity,
    );
  }

  // Matches generic site/page titles that scrapers may return from Cloudflare
  // challenge pages or non-product search results.
  static final _siteNamePattern = RegExp(
    r'(yesstyle|olive.?young|iherb|search|results|fashion|beauty)',
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
        imageUrls: _dedupImageUrls(images?.toList() ?? const []),
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

  /// Trims, drops empty/null entries, and dedupes image URLs at the **address
  /// level** — preserving the first-seen original. Two URLs collapse when they
  /// point at the same address ignoring scheme (http/https), host case, default
  /// ports, an empty trailing `?`, and a trailing path slash. Distinct CDN size
  /// variants (different paths) are intentionally kept.
  static List<String> _dedupImageUrls(List<String?> urls) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in urls) {
      final url = _nonEmpty(raw);
      if (url != null && seen.add(_addressKey(url))) result.add(url);
    }
    return result;
  }

  /// Normalized comparison key for an image address (see [_dedupImageUrls]).
  static String _addressKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url.toLowerCase();
    final host = uri.host.toLowerCase();
    final port = (uri.hasPort && uri.port != 80 && uri.port != 443)
        ? ':${uri.port}'
        : '';
    var path = uri.path;
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    // Scheme deliberately omitted so http/https fold together.
    return '$host$port$path${uri.query.isEmpty ? '' : '?${uri.query}'}';
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
    return _dedupImageUrls(urls);
  }
}
