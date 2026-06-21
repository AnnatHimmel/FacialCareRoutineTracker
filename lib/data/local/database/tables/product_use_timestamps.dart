import 'package:drift/drift.dart';

/// One row per product recording when it was first and last used (marked done).
/// Derived from [DayRecords]: timestamps are the epoch-ms of the earliest /
/// latest recorded date the product appears in. Maintained by the repository.
@DataClassName('ProductUseTimestampRow')
class ProductUseTimestamps extends Table {
  TextColumn get productId => text()();
  IntColumn get firstUsedAtMs => integer()();
  IntColumn get lastUsedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {productId};
}
