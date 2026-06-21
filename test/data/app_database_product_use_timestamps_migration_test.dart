// REQ: schema migration — the product_use_timestamps table is present at the
// current schema version (v14) and a row inserted through its DAO survives a
// fresh DB open. Mirrors app_database_ingredients_migration_test.dart.
//
// Migration form chosen: lightweight "table existence via round-trip" test.
// Rationale: the project has NO drift schema-test harness. We therefore open
// the DB at the current schema version with NativeDatabase.memory(), insert a
// row referencing the new table, read it back, and assert it round-trips.

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

  group('product_use_timestamps table migration (v13 → v14)', () {
    test('persists a row inserted at the current schema version', () async {
      await db.productUseTimestampsDao.upsert(
        ProductUseTimestampsCompanion(
          productId: const Value('prod-1'),
          firstUsedAtMs: Value(DateTime(2026, 6, 10).millisecondsSinceEpoch),
          lastUsedAtMs: Value(DateTime(2026, 6, 15).millisecondsSinceEpoch),
        ),
      );

      final rows = await db.productUseTimestampsDao.watchAll().first;
      final row = rows.firstWhere((r) => r.productId == 'prod-1');

      expect(row.firstUsedAtMs, DateTime(2026, 6, 10).millisecondsSinceEpoch,
          reason: 'product_use_timestamps table must exist after migration');
      expect(row.lastUsedAtMs, DateTime(2026, 6, 15).millisecondsSinceEpoch);
    });
  });
}
