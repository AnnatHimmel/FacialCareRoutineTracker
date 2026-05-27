import 'package:drift/drift.dart';

@DataClassName('OrderOverrideRow')
class OrderOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get slot => text()();
  TextColumn get orderedProductIdsJson => text()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
