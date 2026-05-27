import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/muted_conflicts.dart';

part 'muted_conflicts_dao.g.dart';

@DriftAccessor(tables: [MutedConflicts])
class MutedConflictsDao extends DatabaseAccessor<AppDatabase>
    with _$MutedConflictsDaoMixin {
  MutedConflictsDao(super.db);

  Stream<List<MutedConflictRow>> watchAll() =>
      select(mutedConflicts).watch();

  Future<void> upsert(MutedConflictsCompanion entry) =>
      into(mutedConflicts).insertOnConflictUpdate(entry);

  Future<void> deleteByRuleId(String ruleId) =>
      (delete(mutedConflicts)..where((t) => t.ruleId.equals(ruleId))).go();

  Future<void> deleteAll() => delete(mutedConflicts).go();
}
