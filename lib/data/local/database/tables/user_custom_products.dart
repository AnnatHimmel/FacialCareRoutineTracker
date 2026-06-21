import 'package:drift/drift.dart';

@DataClassName('CustomProductRow')
class UserCustomProducts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get photoKey => text().nullable()();
  TextColumn get categoryId => text()();
  TextColumn get subCategoryId => text().nullable()();
  BoolColumn get inMorning => boolean()();
  BoolColumn get inEvening => boolean()();
  BoolColumn get isDaily => boolean()();
  IntColumn get maxTimesPerWeek => integer().nullable().named('times_per_week')();
  IntColumn get lastModifiedMs => integer()();
  TextColumn get commentJson => text().nullable()();
  TextColumn get brand => text().nullable()();
  TextColumn get ingredients => text().nullable()();
  BoolColumn get isDeprecated =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
