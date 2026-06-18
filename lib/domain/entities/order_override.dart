import 'package:meta/meta.dart';
import '../enums/slot.dart';

@immutable
class OrderOverride {
  final String id;
  final Slot slot;
  // null = global override (applies all days); 0=Sun…6=Sat
  final int? weekday;
  final List<String> orderedProductIds;
  final DateTime lastModified;

  const OrderOverride({
    required this.id,
    required this.slot,
    this.weekday,
    required this.orderedProductIds,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is OrderOverride &&
      other.id == id &&
      other.slot == slot &&
      other.weekday == weekday &&
      _listEqual(other.orderedProductIds, orderedProductIds) &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        slot,
        weekday,
        Object.hashAll(orderedProductIds),
        lastModified,
      );

  OrderOverride copyWith({
    String? id,
    Slot? slot,
    Object? weekday = _sentinel,
    List<String>? orderedProductIds,
    DateTime? lastModified,
  }) =>
      OrderOverride(
        id: id ?? this.id,
        slot: slot ?? this.slot,
        weekday: weekday == _sentinel ? this.weekday : weekday as int?,
        orderedProductIds: orderedProductIds ?? this.orderedProductIds,
        lastModified: lastModified ?? this.lastModified,
      );

  static const _sentinel = Object();

  static bool _listEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
