import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  CustomProductRow rowWithName(List<CustomProductRow> rows, String name) =>
      rows.firstWhere((r) => r.name == name);

  test('subCategoryId round-trips a non-null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p1'),
        name: const Value('Serum'),
        categoryId: const Value('cat-serums'),
        subCategoryId: const Value('sub-vitamin-c'),
        inMorning: const Value(true),
        inEvening: const Value(false),
        isDaily: const Value(true),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Serum');
    expect(row.subCategoryId, 'sub-vitamin-c');
  });

  test('subCategoryId round-trips a null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p2'),
        name: const Value('Cleanser'),
        categoryId: const Value('cat-cleansers'),
        subCategoryId: const Value(null),
        inMorning: const Value(true),
        inEvening: const Value(true),
        isDaily: const Value(true),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Cleanser');
    expect(row.subCategoryId, isNull);
  });
}
