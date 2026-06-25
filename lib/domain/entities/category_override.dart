import 'package:meta/meta.dart';

@immutable
class CategoryOverride {
  final String id;
  final String productId;
  final String categoryId;

  /// Optional sub-category override. Null means "use the product's default".
  final String? subCategoryId;

  final DateTime lastModified;

  const CategoryOverride({
    required this.id,
    required this.productId,
    required this.categoryId,
    this.subCategoryId,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is CategoryOverride &&
      other.id == id &&
      other.productId == productId &&
      other.categoryId == categoryId &&
      other.subCategoryId == subCategoryId &&
      other.lastModified == lastModified;

  @override
  int get hashCode =>
      Object.hash(id, productId, categoryId, subCategoryId, lastModified);

  CategoryOverride copyWith({
    String? id,
    String? productId,
    String? categoryId,
    Object? subCategoryId = _sentinel,
    DateTime? lastModified,
  }) =>
      CategoryOverride(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        categoryId: categoryId ?? this.categoryId,
        subCategoryId: subCategoryId == _sentinel
            ? this.subCategoryId
            : subCategoryId as String?,
        lastModified: lastModified ?? this.lastModified,
      );
}

const _sentinel = Object();
