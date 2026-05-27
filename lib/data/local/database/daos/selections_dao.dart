import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/product_selections.dart';

part 'selections_dao.g.dart';

@DriftAccessor(tables: [ProductSelections])
class SelectionsDao extends DatabaseAccessor<AppDatabase>
    with _$SelectionsDaoMixin {
  SelectionsDao(super.db);

  Stream<List<SelectionRow>> watchBySlot(String slot) =>
      (select(productSelections)..where((t) => t.slot.equals(slot))).watch();

  Stream<List<SelectionRow>> watchAll() =>
      select(productSelections).watch();

  Future<void> upsert(ProductSelectionsCompanion entry) =>
      into(productSelections).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(productSelections)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(productSelections).go();
}
