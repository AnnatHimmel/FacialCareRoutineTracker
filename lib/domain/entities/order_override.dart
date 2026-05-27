import 'package:meta/meta.dart';
import '../enums/slot.dart';

@immutable
class OrderOverride {
  final String id;
  final Slot slot;
  final List<String> orderedProductIds;
  final DateTime lastModified;

  const OrderOverride({
    required this.id,
    required this.slot,
    required this.orderedProductIds,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is OrderOverride &&
      other.id == id &&
      other.slot == slot &&
      _listEqual(other.orderedProductIds, orderedProductIds) &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        slot,
        Object.hashAll(orderedProductIds),
        lastModified,
      );

  OrderOverride copyWith({
    String? id,
    Slot? slot,
    List<String>? orderedProductIds,
    DateTime? lastModified,
  }) =>
      OrderOverride(
        id: id ?? this.id,
        slot: slot ?? this.slot,
        orderedProductIds: orderedProductIds ?? this.orderedProductIds,
        lastModified: lastModified ?? this.lastModified,
      );

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
