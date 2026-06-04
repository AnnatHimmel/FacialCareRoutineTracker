import 'package:meta/meta.dart';

@immutable
class Category {
  final String id;
  final String name;
  final String? nameEn;
  final int order;
  final String? icon;

  const Category({required this.id, required this.name, this.nameEn, required this.order, this.icon});

  String localizedName(String locale) => locale == 'en' ? (nameEn ?? name) : name;

  @override
  bool operator ==(Object other) =>
      other is Category && other.id == id && other.name == name && other.order == order;

  @override
  int get hashCode => Object.hash(id, name, order);

  Category copyWith({String? id, String? name, String? nameEn, int? order, String? icon}) =>
      Category(id: id ?? this.id, name: name ?? this.name, nameEn: nameEn ?? this.nameEn, order: order ?? this.order, icon: icon ?? this.icon);
}
