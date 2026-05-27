import 'package:meta/meta.dart';
import '../enums/slot.dart';

@immutable
class DayRecord {
  final String id;
  final String date;
  final Slot slot;
  final List<String> resolvedProductIds;
  final List<String> recordedProductIds;
  final String resolvedAtMasterVersion;
  final DateTime lastModified;

  const DayRecord({
    required this.id,
    required this.date,
    required this.slot,
    required this.resolvedProductIds,
    required this.recordedProductIds,
    required this.resolvedAtMasterVersion,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is DayRecord &&
      other.id == id &&
      other.date == date &&
      other.slot == slot &&
      _listEqual(other.resolvedProductIds, resolvedProductIds) &&
      _listEqual(other.recordedProductIds, recordedProductIds) &&
      other.resolvedAtMasterVersion == resolvedAtMasterVersion &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        date,
        slot,
        Object.hashAll(resolvedProductIds),
        Object.hashAll(recordedProductIds),
        resolvedAtMasterVersion,
        lastModified,
      );

  DayRecord copyWith({
    String? id,
    String? date,
    Slot? slot,
    List<String>? resolvedProductIds,
    List<String>? recordedProductIds,
    String? resolvedAtMasterVersion,
    DateTime? lastModified,
  }) =>
      DayRecord(
        id: id ?? this.id,
        date: date ?? this.date,
        slot: slot ?? this.slot,
        resolvedProductIds: resolvedProductIds ?? this.resolvedProductIds,
        recordedProductIds: recordedProductIds ?? this.recordedProductIds,
        resolvedAtMasterVersion:
            resolvedAtMasterVersion ?? this.resolvedAtMasterVersion,
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
