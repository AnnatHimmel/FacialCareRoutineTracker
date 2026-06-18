import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/category_overrides.dart';

part 'category_overrides_dao.g.dart';

@DriftAccessor(tables: [CategoryOverrides])
class CategoryOverridesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryOverridesDaoMixin {
  CategoryOverridesDao(super.db);

  Stream<List<CategoryOverrideRow>> watchAll() =>
      select(categoryOverrides).watch();

  Stream<List<CategoryOverrideRow>> watchByProductId(String productId) =>
      (select(categoryOverrides)
            ..where((t) => t.productId.equals(productId)))
          .watch();

  Future<void> upsert(CategoryOverridesCompanion entry) =>
      into(categoryOverrides).insertOnConflictUpdate(entry);

  Future<void> deleteByProductId(String productId) =>
      (delete(categoryOverrides)
            ..where((t) => t.productId.equals(productId)))
          .go();

  Future<void> deleteAll() => delete(categoryOverrides).go();
}
