import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables/product_selections.dart';
import 'tables/weekday_schedules.dart';
import 'tables/order_overrides.dart';
import 'tables/day_records.dart';
import 'tables/skin_log_entries.dart';
import 'tables/muted_conflicts.dart';
import 'daos/selections_dao.dart';
import 'daos/schedules_dao.dart';
import 'daos/order_overrides_dao.dart';
import 'daos/day_records_dao.dart';
import 'daos/skin_log_dao.dart';
import 'daos/muted_conflicts_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    ProductSelections,
    WeekdaySchedules,
    OrderOverrides,
    DayRecords,
    SkinLogEntries,
    MutedConflicts,
  ],
  daos: [
    SelectionsDao,
    SchedulesDao,
    OrderOverridesDao,
    DayRecordsDao,
    SkinLogDao,
    MutedConflictsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.alterTable(TableMigration(skinLogEntries));
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
