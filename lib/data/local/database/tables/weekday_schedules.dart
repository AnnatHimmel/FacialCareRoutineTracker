import 'package:drift/drift.dart';

@DataClassName('ScheduleRow')
class WeekdaySchedules extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get slot => text()();
  TextColumn get weekdaysJson => text()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
