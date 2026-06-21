// REQ: ProductUseTimestampsDao — upsert + watch/get round-trip and delete.
// Mirrors user_custom_products_dao_test.dart.

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

  ProductUseTimestampsCompanion row(String id, int first, int last) =>
      ProductUseTimestampsCompanion(
        productId: Value(id),
        firstUsedAtMs: Value(first),
        lastUsedAtMs: Value(last),
      );

  test('upsert + watchAll round-trips a row', () async {
    await db.productUseTimestampsDao.upsert(row('p1', 100, 200));

    final rows = await db.productUseTimestampsDao.watchAll().first;
    expect(rows, hasLength(1));
    expect(rows.single.productId, 'p1');
    expect(rows.single.firstUsedAtMs, 100);
    expect(rows.single.lastUsedAtMs, 200);
  });

  test('upsert overwrites an existing row by productId', () async {
    await db.productUseTimestampsDao.upsert(row('p1', 100, 200));
    await db.productUseTimestampsDao.upsert(row('p1', 100, 500));

    final rows = await db.productUseTimestampsDao.getAll();
    expect(rows, hasLength(1));
    expect(rows.single.lastUsedAtMs, 500);
  });

  test('deleteByProductId removes only the matching row', () async {
    await db.productUseTimestampsDao.upsert(row('p1', 100, 200));
    await db.productUseTimestampsDao.upsert(row('p2', 300, 400));

    await db.productUseTimestampsDao.deleteByProductId('p1');

    final rows = await db.productUseTimestampsDao.getAll();
    expect(rows.map((r) => r.productId), ['p2']);
  });

  test('deleteAll clears the table', () async {
    await db.productUseTimestampsDao.upsert(row('p1', 100, 200));
    await db.productUseTimestampsDao.upsert(row('p2', 300, 400));

    await db.productUseTimestampsDao.deleteAll();

    expect(await db.productUseTimestampsDao.getAll(), isEmpty);
  });
}
