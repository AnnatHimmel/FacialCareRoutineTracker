import 'package:drift/drift.dart' show Value;
import 'package:uuid/uuid.dart';
import '../../core/utils/json_list.dart';
import '../../data/local/database/app_database.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/muted_conflict.dart';
import '../../domain/entities/order_override.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/entities/user_data_export.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/slot.dart';
import '../../domain/repositories/user_data_repository.dart';

const _uuid = Uuid();

class UserDataRepositoryImpl implements UserDataRepository {
  final AppDatabase _db;

  UserDataRepositoryImpl(this._db);

  // ── Selections ────────────────────────────────────────────────────────────

  @override
  Stream<List<ProductSelection>> watchSelections(Slot slot) =>
      _db.selectionsDao.watchBySlot(slot.name).map(
            (rows) => rows.map(_selectionFromRow).toList(),
          );

  @override
  Future<void> upsertSelection(ProductSelection s) =>
      _db.selectionsDao.upsert(
        ProductSelectionsCompanion(
          id: Value(s.id),
          productId: Value(s.productId),
          slot: Value(s.slot.name),
          isSelected: Value(s.isSelected),
          lastModifiedMs: Value(s.lastModified.millisecondsSinceEpoch),
        ),
      );

  // ── Schedules ─────────────────────────────────────────────────────────────

  @override
  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot) =>
      _db.schedulesDao.watchByProductAndSlot(productId, slot.name).map(
            (rows) => rows.isEmpty ? null : _scheduleFromRow(rows.first),
          );

  @override
  Stream<List<WeekdaySchedule>> watchAllSchedules() =>
      _db.schedulesDao.watchAll().map(
            (rows) => rows.map(_scheduleFromRow).toList(),
          );

  @override
  Future<void> upsertSchedule(WeekdaySchedule s) =>
      _db.schedulesDao.upsert(
        WeekdaySchedulesCompanion(
          id: Value(s.id),
          productId: Value(s.productId),
          slot: Value(s.slot.name),
          weekdaysJson: Value(encodeWeekdays(s.weekdays)),
          lastModifiedMs: Value(s.lastModified.millisecondsSinceEpoch),
        ),
      );

  // ── Order overrides ───────────────────────────────────────────────────────

  @override
  Stream<OrderOverride?> watchOrderOverride(Slot slot) =>
      _db.orderOverridesDao.watchBySlot(slot.name).map(
            (rows) => rows.isEmpty ? null : _overrideFromRow(rows.first),
          );

  @override
  Future<void> upsertOrderOverride(OrderOverride o) =>
      _db.orderOverridesDao.upsert(
        OrderOverridesCompanion(
          id: Value(o.id),
          slot: Value(o.slot.name),
          orderedProductIdsJson: Value(encodeIds(o.orderedProductIds)),
          lastModifiedMs: Value(o.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> deleteOrderOverride(Slot slot) async {
    final rows = await _db.orderOverridesDao.watchBySlot(slot.name).first;
    for (final row in rows) {
      await _db.orderOverridesDao.deleteById(row.id);
    }
  }

  // ── Day records ───────────────────────────────────────────────────────────

  @override
  Stream<DayRecord?> watchDayRecord(String date, Slot slot) =>
      _db.dayRecordsDao.watchByDateAndSlot(date, slot.name).map(
            (rows) => rows.isEmpty ? null : _dayRecordFromRow(rows.first),
          );

  @override
  Future<DayRecord> snapshotAndGetDayRecord(
    String date,
    Slot slot,
    List<String> resolvedProductIds,
    String masterVersion,
  ) async {
    final existing =
        await _db.dayRecordsDao.watchByDateAndSlot(date, slot.name).first;
    if (existing.isNotEmpty) return _dayRecordFromRow(existing.first);

    final record = DayRecord(
      id: _uuid.v4(),
      date: date,
      slot: slot,
      resolvedProductIds: resolvedProductIds,
      recordedProductIds: [],
      resolvedAtMasterVersion: masterVersion,
      lastModified: DateTime.now(),
    );
    await _db.dayRecordsDao.upsert(_dayRecordToCompanion(record));
    return record;
  }

  @override
  Future<void> updateDayRecord(DayRecord r) =>
      _db.dayRecordsDao.upsert(_dayRecordToCompanion(r));

  @override
  Stream<List<DayRecord>> watchDayRecordsForMonth(String yearMonth) =>
      _db.dayRecordsDao.watchForMonth(yearMonth).map(
            (rows) => rows.map(_dayRecordFromRow).toList(),
          );

  @override
  Stream<List<DayRecord>> watchAllDayRecords() =>
      _db.dayRecordsDao.watchAll().map(
            (rows) => rows.map(_dayRecordFromRow).toList(),
          );

  // ── Skin log ──────────────────────────────────────────────────────────────

  @override
  Stream<SkinLogEntry?> watchSkinLog(String date) =>
      _db.skinLogDao.watchByDate(date).map(
            (rows) => rows.isEmpty ? null : _skinLogFromRow(rows.first),
          );

  @override
  Future<void> upsertSkinLog(SkinLogEntry e) =>
      _db.skinLogDao.upsert(
        SkinLogEntriesCompanion(
          id: Value(e.id),
          date: Value(e.date),
          notes: Value(e.notes),
          skinState: Value(e.skinState),
          photoPathsJson: Value(encodeIds(e.photoPaths)),
          lastModifiedMs: Value(e.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Stream<List<SkinLogEntry>> watchAllSkinLogs() =>
      _db.skinLogDao.watchAll().map(
            (rows) => rows.map(_skinLogFromRow).toList(),
          );

  // ── Muted conflicts ───────────────────────────────────────────────────────

  @override
  Stream<List<MutedConflict>> watchMutedConflicts() =>
      _db.mutedConflictsDao.watchAll().map(
            (rows) => rows.map(_mutedConflictFromRow).toList(),
          );

  @override
  Future<void> muteConflict(MutedConflict m) =>
      _db.mutedConflictsDao.upsert(
        MutedConflictsCompanion(
          id: Value(m.id),
          ruleId: Value(m.ruleId),
          mutedAtMs: Value(m.mutedAt.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> unmuteConflict(String ruleId) =>
      _db.mutedConflictsDao.deleteByRuleId(ruleId);

  // ── Custom products ───────────────────────────────────────────────────────

  @override
  Stream<List<UserCustomProduct>> watchCustomProducts() =>
      _db.userCustomProductsDao.watchAll().map(
            (rows) => rows.map(_customProductFromRow).toList(),
          );

  @override
  Future<void> upsertCustomProduct(UserCustomProduct p) =>
      _db.userCustomProductsDao.upsert(
        UserCustomProductsCompanion(
          id: Value(p.id),
          name: Value(p.name),
          photoKey: Value(p.photoKey),
          categoryId: Value(p.categoryId),
          inMorning: Value(p.inMorning),
          inEvening: Value(p.inEvening),
          isDaily: Value(p.isDaily),
          timesPerWeek: Value(p.timesPerWeek),
          lastModifiedMs: Value(p.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> deleteCustomProduct(String id) =>
      _db.userCustomProductsDao.deleteById(id);

  // ── Export / Import ───────────────────────────────────────────────────────

  @override
  Future<UserDataExport> exportAllData() async {
    final selRows = await _db.selectionsDao.watchAll().first;
    final schRows = await _db.schedulesDao.watchAll().first;
    final ovrRows = await _db.orderOverridesDao.watchAll().first;
    final drRows = await _db.dayRecordsDao.watchAll().first;
    final slRows = await _db.skinLogDao.watchAll().first;
    final mcRows = await _db.mutedConflictsDao.watchAll().first;

    return UserDataExport(
      schemaVersion: '1',
      exportDate: DateTime.now().toIso8601String(),
      appVersion: '1.0.0',
      masterContentVersion: '',
      selections: selRows.map(_selectionFromRow).toList(),
      schedules: schRows.map(_scheduleFromRow).toList(),
      overrides: ovrRows.map(_overrideFromRow).toList(),
      dayRecords: drRows.map(_dayRecordFromRow).toList(),
      skinLogs: slRows.map(_skinLogFromRow).toList(),
      mutedConflicts: mcRows.map(_mutedConflictFromRow).toList(),
    );
  }

  @override
  Future<void> replaceAllData(UserDataExport export) async {
    await _db.transaction(() async {
      await _db.selectionsDao.deleteAll();
      await _db.schedulesDao.deleteAll();
      await _db.orderOverridesDao.deleteAll();
      await _db.dayRecordsDao.deleteAll();
      await _db.skinLogDao.deleteAll();
      await _db.mutedConflictsDao.deleteAll();

      for (final s in export.selections) {
        await upsertSelection(s);
      }
      for (final s in export.schedules) {
        await upsertSchedule(s);
      }
      for (final o in export.overrides) {
        await upsertOrderOverride(o);
      }
      for (final r in export.dayRecords) {
        await updateDayRecord(r);
      }
      for (final e in export.skinLogs) {
        await upsertSkinLog(e);
      }
      for (final m in export.mutedConflicts) {
        await muteConflict(m);
      }
    });
  }

  // ── Row → Domain mappers ──────────────────────────────────────────────────

  ProductSelection _selectionFromRow(SelectionRow r) => ProductSelection(
        id: r.id,
        productId: r.productId,
        slot: Slot.values.firstWhere((s) => s.name == r.slot),
        isSelected: r.isSelected,
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  WeekdaySchedule _scheduleFromRow(ScheduleRow r) => WeekdaySchedule(
        id: r.id,
        productId: r.productId,
        slot: Slot.values.firstWhere((s) => s.name == r.slot),
        weekdays: decodeWeekdays(r.weekdaysJson),
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  OrderOverride _overrideFromRow(OrderOverrideRow r) => OrderOverride(
        id: r.id,
        slot: Slot.values.firstWhere((s) => s.name == r.slot),
        orderedProductIds: decodeIds(r.orderedProductIdsJson),
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  DayRecord _dayRecordFromRow(DayRecordRow r) => DayRecord(
        id: r.id,
        date: r.date,
        slot: Slot.values.firstWhere((s) => s.name == r.slot),
        resolvedProductIds: decodeIds(r.resolvedProductIdsJson),
        recordedProductIds: decodeIds(r.recordedProductIdsJson),
        resolvedAtMasterVersion: r.resolvedAtMasterVersion,
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  SkinLogEntry _skinLogFromRow(SkinLogRow r) => SkinLogEntry(
        id: r.id,
        date: r.date,
        notes: r.notes,
        skinState: r.skinState,
        photoPaths: decodeIds(r.photoPathsJson),
        lastModified:
            DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  MutedConflict _mutedConflictFromRow(MutedConflictRow r) => MutedConflict(
        id: r.id,
        ruleId: r.ruleId,
        mutedAt: DateTime.fromMillisecondsSinceEpoch(r.mutedAtMs),
      );

  UserCustomProduct _customProductFromRow(CustomProductRow r) =>
      UserCustomProduct(
        id: r.id,
        name: r.name,
        photoKey: r.photoKey,
        categoryId: r.categoryId,
        inMorning: r.inMorning,
        inEvening: r.inEvening,
        isDaily: r.isDaily,
        timesPerWeek: r.timesPerWeek,
        lastModified: DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );

  DayRecordsCompanion _dayRecordToCompanion(DayRecord r) =>
      DayRecordsCompanion(
        id: Value(r.id),
        date: Value(r.date),
        slot: Value(r.slot.name),
        resolvedProductIdsJson: Value(encodeIds(r.resolvedProductIds)),
        recordedProductIdsJson: Value(encodeIds(r.recordedProductIds)),
        resolvedAtMasterVersion: Value(r.resolvedAtMasterVersion),
        lastModifiedMs: Value(r.lastModified.millisecondsSinceEpoch),
      );
}
