import 'package:meta/meta.dart';

/// When a product was first and last used (marked done in a routine slot).
/// Derived from the recorded routine dates in [DayRecord]s.
@immutable
class ProductUseTimestamp {
  final String productId;
  final DateTime firstUsedAt;
  final DateTime lastUsedAt;

  const ProductUseTimestamp({
    required this.productId,
    required this.firstUsedAt,
    required this.lastUsedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is ProductUseTimestamp &&
      other.productId == productId &&
      other.firstUsedAt == firstUsedAt &&
      other.lastUsedAt == lastUsedAt;

  @override
  int get hashCode => Object.hash(productId, firstUsedAt, lastUsedAt);
}
