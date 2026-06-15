class ScannedProductInfo {
  final String barcode;
  final String? name;
  final String? brand;
  final String? imageUrl;
  final String? categoryHint;
  final String? ingredients;
  final String? quantity;

  const ScannedProductInfo({
    required this.barcode,
    this.name,
    this.brand,
    this.imageUrl,
    this.categoryHint,
    this.ingredients,
    this.quantity,
  });

  bool get hasUsefulData => name != null || brand != null;
}
