import 'package:drift/drift.dart';

@DataClassName('DayRecordRow')
class DayRecords extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get slot => text()();
  TextColumn get resolvedProductIdsJson => text()();
  TextColumn get recordedProductIdsJson => text()();
  TextColumn get resolvedAtMasterVersion => text()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
