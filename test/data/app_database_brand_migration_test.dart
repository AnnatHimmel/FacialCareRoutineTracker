// REQ: schema migration — brand column is present at the current schema version
// and a custom product inserted with a brand value survives a fresh DB open.
//
// Migration form chosen: lightweight "column existence via round-trip" test.
// Rationale: The project has NO drift schema-test harness (no drift_schemas/
// directory, no SchemaVerifier, no generated migration helpers). Therefore we
// cannot replay an actual v9 → v10 upgrade path in isolation. Instead we:
//   1. Open the DB at the current schema version with NativeDatabase.memory().
//   2. Insert a row that references the brand column in the companion.
//   3. Read it back and assert brand is stored correctly.
//   4. Also assert that a row inserted WITHOUT a brand still round-trips with
//      brand == null (simulating an old row surviving the migration).
//
// RED phase: both tests FAIL because the `brand` column does not yet exist on
// the UserCustomProducts table and UserCustomProductsCompanion has no `brand`
// field, causing a compile error / runtime crash.

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

  group('brand column migration (v9 → v10)', () {
    test(
        'should persist brand value when a custom product is inserted '
        'with a brand at the current schema version', () async {
      // Given: the DB is open at the current (post-migration) version
      await db.userCustomProductsDao.upsert(
        UserCustomProductsCompanion(
          id: const Value('mig-1'),
          name: const Value('Retinol Serum'),
          categoryId: const Value('cat-serums'),
          inMorning: const Value(false),
          inEvening: const Value(true),
          isDaily: const Value(false),
          brand: const Value('The Ordinary'),
          lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
        ),
      );

      // When
      final rows = await db.userCustomProductsDao.watchAll().first;
      final row = rows.firstWhere((r) => r.id == 'mig-1');

      // Then: brand column exists and stores the value
      expect(row.brand, 'The Ordinary',
          reason: 'brand column must be present and readable after migration');
    });

    test(
        'should preserve existing custom product rows with brand == null '
        'when no brand was supplied (simulates pre-migration rows)', () async {
      // Given: a row inserted without a brand (old-style row)
      await db.userCustomProductsDao.upsert(
        UserCustomProductsCompanion(
          id: const Value('mig-2'),
          name: const Value('Hyaluronic Acid'),
          categoryId: const Value('cat-serums'),
          inMorning: const Value(true),
          inEvening: const Value(true),
          isDaily: const Value(true),
          // brand intentionally omitted — mirrors a pre-v10 row
          lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
        ),
      );

      // When
      final rows = await db.userCustomProductsDao.watchAll().first;
      final row = rows.firstWhere((r) => r.id == 'mig-2');

      // Then: column exists; old rows default to NULL
      expect(row.brand, isNull,
          reason: 'pre-migration rows must survive with brand == null');
    });
  });
}
