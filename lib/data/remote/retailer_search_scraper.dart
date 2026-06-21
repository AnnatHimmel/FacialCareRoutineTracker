import '../../domain/entities/scanned_product_info.dart';

abstract interface class RetailerSearchScraper {
  /// Search by product name or barcode string. Returns null if nothing found
  /// or if not supported on the current platform (e.g. web CORS restriction).
  Future<ScannedProductInfo?> search(String query);

  /// Whether this source returns accurate results when queried with a raw
  /// barcode (vs only a product name). When true, the lookup service queries
  /// this scraper with the scanned barcode and treats its result as the
  /// highest-priority source.
  bool get supportsBarcodeSearch;
}
