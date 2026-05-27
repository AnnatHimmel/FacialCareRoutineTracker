import 'package:drift/drift.dart';

@DataClassName('SkinLogRow')
class SkinLogEntries extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoPathsJson => text()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
