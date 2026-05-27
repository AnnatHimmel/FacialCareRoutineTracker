import 'package:meta/meta.dart';
import '../enums/slot.dart';

@immutable
class ProductSelection {
  final String id;
  final String productId;
  final Slot slot;
  final bool isSelected;
  final DateTime lastModified;

  const ProductSelection({
    required this.id,
    required this.productId,
    required this.slot,
    required this.isSelected,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is ProductSelection &&
      other.id == id &&
      other.productId == productId &&
      other.slot == slot &&
      other.isSelected == isSelected &&
      other.lastModified == lastModified;

  @override
  int get hashCode =>
      Object.hash(id, productId, slot, isSelected, lastModified);

  ProductSelection copyWith({
    String? id,
    String? productId,
    Slot? slot,
    bool? isSelected,
    DateTime? lastModified,
  }) =>
      ProductSelection(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        slot: slot ?? this.slot,
        isSelected: isSelected ?? this.isSelected,
        lastModified: lastModified ?? this.lastModified,
      );
}
