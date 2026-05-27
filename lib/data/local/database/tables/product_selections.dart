import 'package:drift/drift.dart';

@DataClassName('SelectionRow')
class ProductSelections extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get slot => text()();
  BoolColumn get isSelected => boolean()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
