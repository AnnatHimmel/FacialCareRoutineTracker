import 'package:drift/drift.dart';

@DataClassName('CollectionItemRow')
class CollectionItems extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get status => text()(); // 'inUse' | 'sealed' | 'archive'
  IntColumn get openedDateMs => integer().nullable()();
  IntColumn get paoMonths => integer()();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
