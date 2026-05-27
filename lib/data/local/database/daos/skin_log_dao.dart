import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/skin_log_entries.dart';

part 'skin_log_dao.g.dart';

@DriftAccessor(tables: [SkinLogEntries])
class SkinLogDao extends DatabaseAccessor<AppDatabase>
    with _$SkinLogDaoMixin {
  SkinLogDao(super.db);

  Stream<List<SkinLogRow>> watchAll() =>
      (select(skinLogEntries)
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Stream<List<SkinLogRow>> watchByDate(String date) =>
      (select(skinLogEntries)..where((t) => t.date.equals(date))).watch();

  Future<void> upsert(SkinLogEntriesCompanion entry) =>
      into(skinLogEntries).insertOnConflictUpdate(entry);

  Future<void> deleteById(String id) =>
      (delete(skinLogEntries)..where((t) => t.id.equals(id))).go();

  Future<void> deleteAll() => delete(skinLogEntries).go();
}
