import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/scanned_product_info.dart';

class BarcodeProductLookupService {
  final http.Client _client;

  BarcodeProductLookupService({http.Client? client})
      : _client = client ?? http.Client();

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

      if (kDebugMode) {
        const labels = ['OBF', 'OFF', 'UPC', 'InciBeauty', 'BarcodeSpider'];
        for (var i = 0; i < results.length; i++) {
          final r = results[i];
          debugPrint('[Barcode:$barcode] ${labels[i]}: '
              '${r == null ? "—" : "✓ name=${r.name} brand=${r.brand}"}');
        }
      }

      if (obf == null && off == null && upc == null && inci == null && spider == null) {
        if (kDebugMode) debugPrint('[Barcode:$barcode] no source matched');
        return null;
      }

      // Priority: OBF > OFF > UPC > InciBeauty > BarcodeSpider
      if (kDebugMode) {
        final winnerName = obf?.name != null ? 'OBF'
            : off?.name != null ? 'OFF'
            : upc?.name != null ? 'UPC'
            : inci?.name != null ? 'InciBeauty'
            : spider?.name != null ? 'BarcodeSpider'
            : '—';
        final winnerBrand = obf?.brand != null ? 'OBF'
            : off?.brand != null ? 'OFF'
            : upc?.brand != null ? 'UPC'
            : inci?.brand != null ? 'InciBeauty'
            : spider?.brand != null ? 'BarcodeSpider'
            : '—';
        debugPrint('[Barcode:$barcode] merged → name from $winnerName, brand from $winnerBrand');
      }

      return ScannedProductInfo(
        barcode: barcode,
        name: obf?.name ?? off?.name ?? upc?.name ?? inci?.name ?? spider?.name,
        brand: obf?.brand ?? off?.brand ?? upc?.brand ?? inci?.brand ?? spider?.brand,
        imageUrl: obf?.imageUrl ?? off?.imageUrl ?? upc?.imageUrl ?? inci?.imageUrl,
        categoryHint: obf?.categoryHint ?? off?.categoryHint ?? upc?.categoryHint ?? inci?.categoryHint,
        ingredients: obf?.ingredients ?? off?.ingredients ?? upc?.ingredients ?? inci?.ingredients,
        quantity: obf?.quantity ?? off?.quantity ?? upc?.quantity ?? inci?.quantity,
      );
    } catch (_) {
      return null;
    }
  }

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
        imageUrl: _nonEmpty(product['image_url'] as String?),
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
        imageUrl: _nonEmpty(product['image_url'] as String?),
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
        imageUrl: images?.firstOrNull,
        categoryHint: _nonEmpty(item['category'] as String?),
        ingredients: _nonEmpty(item['description'] as String?),
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

          return ScannedProductInfo(
            barcode: barcode,
            name: name,
            brand: brand,
            imageUrl: _nonEmpty(data['image'] as String?),
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
        imageUrl: null,
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
}
