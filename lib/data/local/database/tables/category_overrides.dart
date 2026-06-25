import 'package:drift/drift.dart';

@DataClassName('CategoryOverrideRow')
class CategoryOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get productId => text()();
  TextColumn get categoryId => text()();
  TextColumn get subCategoryId => text().nullable()();
  IntColumn get lastModifiedMs => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
