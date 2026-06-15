import 'dart:convert';
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
        _lookupUpcItemDb(barcode),
      ]);

      final obf = results[0];
      final upc = results[1];

      if (obf == null && upc == null) return null;

      return ScannedProductInfo(
        barcode: barcode,
        name: obf?.name ?? upc?.name,
        brand: obf?.brand ?? upc?.brand,
        imageUrl: obf?.imageUrl ?? upc?.imageUrl,
        categoryHint: obf?.categoryHint ?? upc?.categoryHint,
        ingredients: obf?.ingredients ?? upc?.ingredients,
        quantity: obf?.quantity ?? upc?.quantity,
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

  static String? _nonEmpty(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s.trim();
}
