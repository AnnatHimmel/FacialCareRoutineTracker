import 'package:meta/meta.dart';

/// A fine-grained, active-ingredient class within a [Category] (phase).
///
/// Sub-categories are the second sort key (PRD §15): within a phase, products
/// order by their sub-category's [order]. [categoryId] ties a sub-category to
/// the phase it belongs to. Authored in master content alongside categories.
@immutable
class SubCategory {
  final String id;
  final String name;
  final String? nameEn;

  /// The phase (Category) this sub-category belongs to.
  final String categoryId;

  /// Order within the phase.
  final int order;

  const SubCategory({
    required this.id,
    required this.name,
    this.nameEn,
    required this.categoryId,
    required this.order,
  });

  String localizedName(String locale) =>
      locale == 'en' ? (nameEn ?? name) : name;

  @override
  bool operator ==(Object other) =>
      other is SubCategory &&
      other.id == id &&
      other.name == name &&
      other.categoryId == categoryId &&
      other.order == order;

  @override
  int get hashCode => Object.hash(id, name, categoryId, order);

  SubCategory copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? categoryId,
    int? order,
  }) =>
      SubCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        nameEn: nameEn ?? this.nameEn,
        categoryId: categoryId ?? this.categoryId,
        order: order ?? this.order,
      );
}
