import 'package:meta/meta.dart';
import '../enums/collection_status.dart';

@immutable
class CollectionItem {
  final String id;
  final String productId;
  final CollectionStatus status;
  final DateTime? openedDate;
  final int paoMonths;
  final bool notificationsEnabled;
  final DateTime lastModified;

  const CollectionItem({
    required this.id,
    required this.productId,
    required this.status,
    this.openedDate,
    required this.paoMonths,
    this.notificationsEnabled = true,
    required this.lastModified,
  });

  @override
  bool operator ==(Object other) =>
      other is CollectionItem &&
      other.id == id &&
      other.productId == productId &&
      other.status == status &&
      other.openedDate == openedDate &&
      other.paoMonths == paoMonths &&
      other.notificationsEnabled == notificationsEnabled &&
      other.lastModified == lastModified;

  @override
  int get hashCode => Object.hash(
        id,
        productId,
        status,
        openedDate,
        paoMonths,
        notificationsEnabled,
        lastModified,
      );

  CollectionItem copyWith({
    String? id,
    String? productId,
    CollectionStatus? status,
    Object? openedDate = _sentinel,
    int? paoMonths,
    bool? notificationsEnabled,
    DateTime? lastModified,
  }) =>
      CollectionItem(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        status: status ?? this.status,
        openedDate:
            openedDate == _sentinel ? this.openedDate : openedDate as DateTime?,
        paoMonths: paoMonths ?? this.paoMonths,
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        lastModified: lastModified ?? this.lastModified,
      );
}

const _sentinel = Object();
