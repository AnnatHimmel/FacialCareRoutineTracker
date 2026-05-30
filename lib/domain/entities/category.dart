import 'package:meta/meta.dart';

@immutable
class Category {
  final String id;
  final String name;
  final int order;

  const Category({required this.id, required this.name, required this.order});

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name && other.order == order;

  @override
  int get hashCode => Object.hash(id, name, order);

  Category copyWith({String? id, String? name, int? order}) =>
      Category(id: id ?? this.id, name: name ?? this.name, order: order ?? this.order);
}
