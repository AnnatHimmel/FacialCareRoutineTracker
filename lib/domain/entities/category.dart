import 'package:meta/meta.dart';

@immutable
class Category {
  final String id;
  final String name;

  const Category({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  Category copyWith({String? id, String? name}) =>
      Category(id: id ?? this.id, name: name ?? this.name);
}
