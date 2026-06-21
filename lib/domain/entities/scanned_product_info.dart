class ScannedProductInfo {
  final String barcode;
  final String? name;
  final String? brand;

  /// All candidate product images surfaced by the lookup sources, in priority
  /// order, deduped. The first entry (if any) is treated as the default image.
  final List<String> imageUrls;
  final String? categoryHint;
  final String? ingredients;

  /// Free-text product description / marketing blurb (e.g. UPCItemDB's
  /// `description`). This is NOT an INCI list — it prefills the comment field,
  /// never the ingredients field.
  final String? comment;
  final String? quantity;

  const ScannedProductInfo({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrls = const [],
    this.categoryHint,
    this.ingredients,
    this.comment,
    this.quantity,
  });

  /// The default (first) candidate image, or null when none were found.
  String? get imageUrl => imageUrls.isEmpty ? null : imageUrls.first;

  bool get hasUsefulData => name != null || brand != null;
}
