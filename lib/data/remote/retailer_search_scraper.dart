import '../../domain/entities/scanned_product_info.dart';

abstract interface class RetailerSearchScraper {
  /// Search by product name or barcode string. Returns null if nothing found
  /// or if not supported on the current platform (e.g. web CORS restriction).
  Future<ScannedProductInfo?> search(String query);
}
