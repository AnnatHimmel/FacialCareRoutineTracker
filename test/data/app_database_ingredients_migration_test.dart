// REQ: schema migration — ingredients column is present at the current schema
// version (v13) and a custom product inserted with an ingredients value
// survives a fresh DB open. Mirrors app_database_brand_migration_test.dart.
//
// Migration form chosen: lightweight "column existence via round-trip" test.
// Rationale: The project has NO drift schema-test harness. Therefore we:
//   1. Open the DB at the current schema version with NativeDatabase.memory().
//   2. Insert a row that references the ingredients column in the companion.
//   3. Read it back and assert ingredients is stored correctly.
//   4. Also assert that a row inserted WITHOUT ingredients still round-trips
//      with ingredients == null (simulating an old row surviving the migration).

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

  group('ingredients column migration (v12 → v13)', () {
    test(
        'should persist ingredients value when a custom product is inserted '
        'with ingredients at the current schema version', () async {
      // Given: the DB is open at the current (post-migration) version
      await db.userCustomProductsDao.upsert(
        UserCustomProductsCompanion(
          id: const Value('ing-1'),
          name: const Value('Niacinamide Serum'),
          categoryId: const Value('cat-serums'),
          inMorning: const Value(false),
          inEvening: const Value(true),
          isDaily: const Value(true),
          ingredients: const Value('Aqua, Niacinamide, Zinc PCA'),
          lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
        ),
      );

      // When
      final rows = await db.userCustomProductsDao.watchAll().first;
      final row = rows.firstWhere((r) => r.id == 'ing-1');

      // Then: ingredients column exists and stores the value
      expect(row.ingredients, 'Aqua, Niacinamide, Zinc PCA',
          reason:
              'ingredients column must be present and readable after migration');
    });

    test(
        'should preserve existing custom product rows with ingredients == null '
        'when no ingredients was supplied (simulates pre-migration rows)',
        () async {
      // Given: a row inserted without ingredients (old-style row)
      await db.userCustomProductsDao.upsert(
        UserCustomProductsCompanion(
          id: const Value('ing-2'),
          name: const Value('Hyaluronic Acid'),
          categoryId: const Value('cat-serums'),
          inMorning: const Value(true),
          inEvening: const Value(true),
          isDaily: const Value(true),
          // ingredients intentionally omitted — mirrors a pre-v13 row
          lastModifiedMs: Value(DateTime(2026).millisecondsSinceEpoch),
        ),
      );

      // When
      final rows = await db.userCustomProductsDao.watchAll().first;
      final row = rows.firstWhere((r) => r.id == 'ing-2');

      // Then: column exists; old rows default to NULL
      expect(row.ingredients, isNull,
          reason: 'pre-migration rows must survive with ingredients == null');
    });
  });
}
