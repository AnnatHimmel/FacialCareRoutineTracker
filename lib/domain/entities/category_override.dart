import 'package:meta/meta.dart';

@immutable
class CategoryOverride {
  final String id;
  final String productId;
  final String categoryId;
  final DateTime lastModified;

  const CategoryOverride({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is CategoryOverride &&
      other.id == id &&
      other.productId == productId &&
      other.categoryId == categoryId &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(id, productId, categoryId, lastModified);

  CategoryOverride copyWith({
    String? id,
    String? productId,
    String? categoryId,
    DateTime? lastModified,
  }) =>
      CategoryOverride(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        categoryId: categoryId ?? this.categoryId,
        lastModified: lastModified ?? this.lastModified,
      );
}
