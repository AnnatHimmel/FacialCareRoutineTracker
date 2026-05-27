import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/order_overrides.dart';

part 'order_overrides_dao.g.dart';

@DriftAccessor(tables: [OrderOverrides])
class OrderOverridesDao extends DatabaseAccessor<AppDatabase>
    with _$OrderOverridesDaoMixin {
  OrderOverridesDao(super.db);

  Stream<List<OrderOverrideRow>> watchBySlot(String slot) =>
      (select(orderOverrides)..where((t) => t.slot.equals(slot))).watch();

  Stream<List<OrderOverrideRow>> watchAll() => select(orderOverrides).watch();

  Future<void> upsert(OrderOverridesCompanion entry) =>
      into(orderOverrides).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(orderOverrides)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(orderOverrides).go();
}
