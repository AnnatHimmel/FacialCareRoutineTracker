import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/collection_items.dart';

part 'collection_items_dao.g.dart';

@DriftAccessor(tables: [CollectionItems])
class CollectionItemsDao extends DatabaseAccessor<AppDatabase>
    with _$CollectionItemsDaoMixin {
  CollectionItemsDao(super.db);

  Stream<List<CollectionItemRow>> watchAll() =>
      select(collectionItems).watch();

  Future<void> upsert(CollectionItemsCompanion entry) =>
      into(collectionItems).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(collectionItems)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(collectionItems).go();
}
