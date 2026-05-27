import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/weekday_schedules.dart';

part 'schedules_dao.g.dart';

@DriftAccessor(tables: [WeekdaySchedules])
class SchedulesDao extends DatabaseAccessor<AppDatabase>
    with _$SchedulesDaoMixin {
  SchedulesDao(super.db);

  Stream<List<ScheduleRow>> watchByProductAndSlot(
    String productId,
    String slot,
  ) =>
      (select(weekdaySchedules)
            ..where(
              (t) => t.productId.equals(productId) & t.slot.equals(slot),
            ))
          .watch();

  Stream<List<ScheduleRow>> watchAll() => select(weekdaySchedules).watch();

  Future<void> upsert(WeekdaySchedulesCompanion entry) =>
      into(weekdaySchedules).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(weekdaySchedules)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(weekdaySchedules).go();
}
