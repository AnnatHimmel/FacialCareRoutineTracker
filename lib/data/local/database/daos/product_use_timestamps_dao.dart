import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_use_timestamps.dart';

part 'product_use_timestamps_dao.g.dart';

@DriftAccessor(tables: [ProductUseTimestamps])
class ProductUseTimestampsDao extends DatabaseAccessor<AppDatabase>
    with _$ProductUseTimestampsDaoMixin {
  ProductUseTimestampsDao(super.db);

  Stream<List<ProductUseTimestampRow>> watchAll() =>
      select(productUseTimestamps).watch();

  Future<List<ProductUseTimestampRow>> getAll() =>
      select(productUseTimestamps).get();

  Future<void> upsert(ProductUseTimestampsCompanion entry) =>
      into(productUseTimestamps).insertOnConflictUpdate(entry);

  Future<void> deleteByProductId(String productId) =>
      (delete(productUseTimestamps)..where((t) => t.productId.equals(productId)))
          .go();

  Future<void> deleteAll() => delete(productUseTimestamps).go();
}
