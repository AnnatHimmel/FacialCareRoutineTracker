import 'package:drift/drift.dart';

@DataClassName('OrderOverrideRow')
class OrderOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get slot => text()();
  // null = global override; 0=Sun…6=Sat for per-day overrides
  IntColumn get weekday => integer().nullable()();
  TextColumn get orderedProductIdsJson => text()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
