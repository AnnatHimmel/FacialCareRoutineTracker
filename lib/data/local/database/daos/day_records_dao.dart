import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/day_records.dart';

part 'day_records_dao.g.dart';

@DriftAccessor(tables: [DayRecords])
class DayRecordsDao extends DatabaseAccessor<AppDatabase>
    with _$DayRecordsDaoMixin {
  DayRecordsDao(super.db);

  Stream<List<DayRecordRow>> watchByDateAndSlot(String date, String slot) =>
      (select(dayRecords)
            ..where(
              (t) => t.date.equals(date) & t.slot.equals(slot),
            ))
          .watch();

  Stream<List<DayRecordRow>> watchForMonth(String yearMonth) =>
      (select(dayRecords)
            ..where((t) => t.date.like('$yearMonth%'))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<List<DayRecordRow>> watchAll() => select(dayRecords).watch();

  Future<List<DayRecordRow>> getAll() => select(dayRecords).get();

  Future<void> upsert(DayRecordsCompanion entry) =>
      into(dayRecords).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(dayRecords)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(dayRecords).go();
}
