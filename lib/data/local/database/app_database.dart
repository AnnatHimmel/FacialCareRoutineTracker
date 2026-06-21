import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/product_selections.dart';
import 'tables/weekday_schedules.dart';
import 'tables/order_overrides.dart';
import 'tables/day_records.dart';
import 'tables/skin_log_entries.dart';
import 'tables/muted_conflicts.dart';
import 'tables/user_custom_products.dart';
import 'tables/collection_items.dart';
import 'tables/category_overrides.dart';
import 'tables/product_use_timestamps.dart';
import 'daos/selections_dao.dart';
import 'daos/schedules_dao.dart';
import 'daos/order_overrides_dao.dart';
import 'daos/day_records_dao.dart';
import 'daos/skin_log_dao.dart';
import 'daos/muted_conflicts_dao.dart';
import 'daos/user_custom_products_dao.dart';
import 'daos/collection_items_dao.dart';
import 'daos/category_overrides_dao.dart';
import 'daos/product_use_timestamps_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ProductSelections,
    WeekdaySchedules,
    OrderOverrides,
    DayRecords,
    SkinLogEntries,
    MutedConflicts,
    UserCustomProducts,
    CollectionItems,
    CategoryOverrides,
    ProductUseTimestamps,
  ],
  daos: [
    SelectionsDao,
    SchedulesDao,
    OrderOverridesDao,
    DayRecordsDao,
    SkinLogDao,
    MutedConflictsDao,
    UserCustomProductsDao,
    CollectionItemsDao,
    CategoryOverridesDao,
    ProductUseTimestampsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 15;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 3) {
            // Recreate day_records in case an early dev database was missing
            // resolved_at_master_version (added before the first formal version).
            await m.alterTable(
              TableMigration(
                dayRecords,
                columnTransformer: {
                  dayRecords.resolvedAtMasterVersion:
                      const CustomExpression("'1.0.0'"),
                },
              ),
            );
            // Add skin_state column to skin_log_entries (added in v2).
            await m.addColumn(skinLogEntries, skinLogEntries.skinState);
          }
          if (from < 4) {
            await m.createTable(userCustomProducts);
          }
          if (from < 5) {
            await customStatement(
              'ALTER TABLE user_custom_products ADD COLUMN comment_json TEXT',
            );
          }
          if (from < 6) {
            await m.createTable(collectionItems);
          }
          if (from < 7) {
            // Add per-day weekday column to order_overrides.
            // Existing rows get NULL = global override (existing behavior preserved).
            await m.addColumn(orderOverrides, orderOverrides.weekday);
          }
          if (from < 8) {
            await m.createTable(categoryOverrides);
          }
          if (from < 9) {
            await m.addColumn(
                userCustomProducts, userCustomProducts.subCategoryId);
          }
          if (from < 10) {
            await m.addColumn(userCustomProducts, userCustomProducts.brand);
          }
          if (from < 11) {
            // Merge cat-cleanser-step1 and cat-cleanser-step2 into cat-cleanser.
            await customStatement(
              "UPDATE user_custom_products SET category_id = 'cat-cleanser' "
              "WHERE category_id IN ('cat-cleanser-step1', 'cat-cleanser-step2')",
            );
            // Rename sub-oil-cleanser → sub-first-cleanser.
            await customStatement(
              "UPDATE user_custom_products SET sub_category_id = 'sub-first-cleanser' "
              "WHERE sub_category_id = 'sub-oil-cleanser'",
            );
          }
          if (from < 12) {
            // Rename sub-water-cleanser → sub-second-cleanser.
            await customStatement(
              "UPDATE user_custom_products SET sub_category_id = 'sub-second-cleanser' "
              "WHERE sub_category_id = 'sub-water-cleanser'",
            );
          }
          if (from < 13) {
            await m.addColumn(userCustomProducts, userCustomProducts.ingredients);
          }
          if (from < 14) {
            await m.createTable(productUseTimestamps);
          }
          if (from < 15) {
            await m.addColumn(
                userCustomProducts, userCustomProducts.isDeprecated);
          }
        },
      );
}

AppDatabase openDatabase() {
  return AppDatabase(driftDatabase(
    name: 'skincare_tracker',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ));
}
