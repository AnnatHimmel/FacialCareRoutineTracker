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

  // REQ: brand column — nullable text, round-trip through the DAO layer.

  test('brand round-trips a non-null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p3'),
        name: const Value('Toner'),
        categoryId: const Value('cat-toners'),
        inMorning: const Value(true),
        inEvening: const Value(false),
        isDaily: const Value(true),
        brand: const Value('The Ordinary'),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Toner');
    expect(row.brand, 'The Ordinary');
  });

  test('brand round-trips a null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p4'),
        name: const Value('Moisturiser'),
        categoryId: const Value('cat-moisturisers'),
        inMorning: const Value(true),
        inEvening: const Value(true),
        isDaily: const Value(true),
        brand: const Value(null),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Moisturiser');
    expect(row.brand, isNull);
  });

  // REQ: ingredients column — nullable text, round-trip through the DAO layer.

  test('ingredients round-trips a non-null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p5'),
        name: const Value('Niacinamide'),
        categoryId: const Value('cat-serums'),
        inMorning: const Value(false),
        inEvening: const Value(true),
        isDaily: const Value(true),
        ingredients: const Value('Aqua, Niacinamide, Zinc PCA'),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Niacinamide');
    expect(row.ingredients, 'Aqua, Niacinamide, Zinc PCA');
  });

  test('ingredients round-trips a null value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p6'),
        name: const Value('Cleanser'),
        categoryId: const Value('cat-cleansers'),
        inMorning: const Value(true),
        inEvening: const Value(true),
        isDaily: const Value(true),
        ingredients: const Value(null),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Cleanser');
    expect(row.ingredients, isNull);
  });

  // REQ: isDeprecated column — soft-delete flag for user-added products.
  // Products are never hard-deleted; instead they are marked deprecated so
  // they disappear from active screens but remain visible in calendar history.

  test('isDeprecated defaults to false for a new product', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p7'),
        name: const Value('New Serum'),
        categoryId: const Value('cat-serum'),
        inMorning: const Value(true),
        inEvening: const Value(false),
        isDaily: const Value(true),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'New Serum');
    expect(row.isDeprecated, isFalse);
  });

  test('isDeprecated round-trips a true value', () async {
    await db.userCustomProductsDao.upsert(
      UserCustomProductsCompanion(
        id: const Value('p8'),
        name: const Value('Deleted Product'),
        categoryId: const Value('cat-serum'),
        inMorning: const Value(true),
        inEvening: const Value(false),
        isDaily: const Value(true),
        isDeprecated: const Value(true),
        lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
      ),
    );

    final rows = await db.userCustomProductsDao.watchAll().first;
    final row = rowWithName(rows, 'Deleted Product');
    expect(row.isDeprecated, isTrue);
  });
}
