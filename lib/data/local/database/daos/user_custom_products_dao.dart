import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/user_custom_products.dart';

part 'user_custom_products_dao.g.dart';

@DriftAccessor(tables: [UserCustomProducts])
class UserCustomProductsDao extends DatabaseAccessor<AppDatabase>
    with _$UserCustomProductsDaoMixin {
  UserCustomProductsDao(super.db);

  Stream<List<CustomProductRow>> watchAll() =>
      select(userCustomProducts).watch();

  Future<void> upsert(UserCustomProductsCompanion entry) =>
      into(userCustomProducts).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(userCustomProducts)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(userCustomProducts).go();
}
