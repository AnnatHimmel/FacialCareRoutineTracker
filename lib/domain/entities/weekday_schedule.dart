import 'package:meta/meta.dart';
import '../enums/slot.dart';

@immutable
class WeekdaySchedule {
  final String id;
  final String productId;
  final Slot slot;
  final Set<int> weekdays;
  final DateTime lastModified;

  const WeekdaySchedule({
    required this.id,
    required this.productId,
    required this.slot,
    required this.weekdays,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is WeekdaySchedule &&
      other.id == id &&
      other.productId == productId &&
      other.slot == slot &&
      _setEqual(other.weekdays, weekdays) &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        productId,
        slot,
        Object.hashAll(weekdays.toList()..sort()),
        lastModified,
      );

  WeekdaySchedule copyWith({
    String? id,
    String? productId,
    Slot? slot,
    Set<int>? weekdays,
    DateTime? lastModified,
  }) =>
      WeekdaySchedule(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        slot: slot ?? this.slot,
        weekdays: weekdays ?? this.weekdays,
        lastModified: lastModified ?? this.lastModified,
      );

  static bool _setEqual(Set<int> a, Set<int> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
