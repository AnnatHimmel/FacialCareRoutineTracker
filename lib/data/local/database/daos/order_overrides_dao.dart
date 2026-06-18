import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/order_overrides.dart';

part 'order_overrides_dao.g.dart';

@DriftAccessor(tables: [OrderOverrides])
class OrderOverridesDao extends DatabaseAccessor<AppDatabase>
    with _$OrderOverridesDaoMixin {
  OrderOverridesDao(super.db);

  // Returns ALL rows for a slot (both global and per-day) — used for export.
  Stream<List<OrderOverrideRow>> watchBySlot(String slot) =>
      (select(orderOverrides)..where((t) => t.slot.equals(slot))).watch();

  // Global override (weekday IS NULL) for a slot.
  Stream<List<OrderOverrideRow>> watchGlobalBySlot(String slot) =>
      (select(orderOverrides)
            ..where((t) => t.slot.equals(slot) & t.weekday.isNull()))
          .watch();

  // All per-day overrides (weekday IS NOT NULL) for a slot.
  Stream<List<OrderOverrideRow>> watchPerDayBySlot(String slot) =>
      (select(orderOverrides)
            ..where((t) => t.slot.equals(slot) & t.weekday.isNotNull()))
          .watch();

  // Override for a specific slot + weekday.
  Stream<List<OrderOverrideRow>> watchBySlotAndWeekday(
      String slot, int weekday) =>
      (select(orderOverrides)
            ..where(
                (t) => t.slot.equals(slot) & t.weekday.equals(weekday)))
          .watch();

  Stream<List<OrderOverrideRow>> watchAll() => select(orderOverrides).watch();

  Future<void> upsert(OrderOverridesCompanion entry) =>
      into(orderOverrides).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(orderOverrides)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(orderOverrides).go();
}
