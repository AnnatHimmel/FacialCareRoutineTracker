import 'package:drift/drift.dart';

@DataClassName('MutedConflictRow')
class MutedConflicts extends Table {
  TextColumn get id => text()();
  TextColumn get ruleId => text()();
  IntColumn get mutedAtMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
