import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:uuid/uuid.dart';
import '../../core/utils/json_list.dart';
import '../../data/local/database/app_database.dart';
import '../../domain/entities/category_override.dart';
import '../../domain/entities/collection_item.dart';
import '../../domain/entities/day_record.dart';
import '../../domain/entities/muted_conflict.dart';
import '../../domain/entities/order_override.dart';
import '../../domain/entities/product_selection.dart';
import '../../domain/entities/product_use_timestamp.dart';
import '../../domain/entities/skin_log_entry.dart';
import '../../domain/entities/user_custom_product.dart';
import '../../domain/entities/user_data_export.dart';
import '../../domain/entities/weekday_schedule.dart';
import '../../domain/enums/collection_status.dart';
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
      _db.orderOverridesDao.watchGlobalBySlot(slot.name).map(
            (rows) => rows.isEmpty ? null : _overrideFromRow(rows.first),
          );

  @override
  Future<void> upsertOrderOverride(OrderOverride o) =>
      _db.orderOverridesDao.upsert(
        OrderOverridesCompanion(
          id: Value(o.id),
          slot: Value(o.slot.name),
          weekday: Value(o.weekday),
          orderedProductIdsJson: Value(encodeIds(o.orderedProductIds)),
          lastModifiedMs: Value(o.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> deleteOrderOverride(Slot slot) async {
    final rows =
        await _db.orderOverridesDao.watchGlobalBySlot(slot.name).first;
    for (final row in rows) {
      await _db.orderOverridesDao.deleteById(row.id);
    }
  }

  @override
  Stream<List<OrderOverride>> watchPerDayOrderOverrides(Slot slot) =>
      _db.orderOverridesDao.watchPerDayBySlot(slot.name).map(
            (rows) => rows.map(_overrideFromRow).toList(),
          );

  @override
  Future<OrderOverride?> getEffectiveOrderOverride(
      Slot slot, int weekday) async {
    final perDay = await _db.orderOverridesDao
        .watchBySlotAndWeekday(slot.name, weekday)
        .first;
    if (perDay.isNotEmpty) return _overrideFromRow(perDay.first);
    final global =
        await _db.orderOverridesDao.watchGlobalBySlot(slot.name).first;
    return global.isNotEmpty ? _overrideFromRow(global.first) : null;
  }

  @override
  Future<void> deletePerDayOrderOverride(Slot slot, int weekday) async {
    final rows = await _db.orderOverridesDao
        .watchBySlotAndWeekday(slot.name, weekday)
        .first;
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
  Future<void> updateDayRecord(DayRecord r) async {
    await _db.transaction(() async {
      // Capture which products were recorded before this write so we know whose
      // first/last-used timestamps need recomputing.
      final all = await _db.dayRecordsDao.getAll();
      final prior = all.where((row) => row.id == r.id).toList();
      final before = prior.isEmpty
          ? <String>{}
          : decodeIds(prior.first.recordedProductIdsJson).toSet();

      await _db.dayRecordsDao.upsert(_dayRecordToCompanion(r));

      final after = r.recordedProductIds.toSet();
      final changed = {
        ...before.difference(after),
        ...after.difference(before),
      };
      if (kDebugMode) {
        debugPrint('[ProductUse] updateDayRecord ${r.date}/${r.slot.name}: '
            'marked=${after.difference(before)} '
            'unmarked=${before.difference(after)}');
      }
      for (final productId in changed) {
        await _recomputeProductUse(productId);
      }
    });
  }

  /// Rebuilds the derived first/last-used timestamps for [productId] from the
  /// recorded dates across all day records. Deletes the row if the product is
  /// no longer recorded anywhere (e.g. an accidental tap that was undone).
  Future<void> _recomputeProductUse(String productId) async {
    final rows = await _db.dayRecordsDao.getAll();
    final dates = <String>[
      for (final row in rows)
        if (decodeIds(row.recordedProductIdsJson).contains(productId)) row.date,
    ]..sort(); // "YYYY-MM-DD" sorts chronologically

    if (dates.isEmpty) {
      if (kDebugMode) {
        debugPrint('[ProductUse] $productId no longer recorded → row deleted');
      }
      await _db.productUseTimestampsDao.deleteByProductId(productId);
      return;
    }
    if (kDebugMode) {
      debugPrint('[ProductUse] $productId firstUsed=${dates.first} '
          'lastUsed=${dates.last} (${dates.length} day(s))');
    }
    await _db.productUseTimestampsDao.upsert(
      ProductUseTimestampsCompanion(
        productId: Value(productId),
        firstUsedAtMs: Value(DateTime.parse(dates.first).millisecondsSinceEpoch),
        lastUsedAtMs: Value(DateTime.parse(dates.last).millisecondsSinceEpoch),
      ),
    );
  }

  /// First/last time each product was marked done, derived from day records.
  /// Concrete-only (not on [UserDataRepository]) — recording happens inside
  /// [updateDayRecord]; this read exists for future display.
  Stream<List<ProductUseTimestamp>> watchProductUseTimestamps() =>
      _db.productUseTimestampsDao.watchAll().map(
            (rows) => rows.map(_productUseTimestampFromRow).toList(),
          );

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
          brand: Value(p.brand),
          name: Value(p.name),
          photoKey: Value(p.photoKey),
          categoryId: Value(p.categoryId),
          subCategoryId: Value(p.subCategoryId),
          inMorning: Value(p.inMorning),
          inEvening: Value(p.inEvening),
          isDaily: Value(p.isDaily),
          maxTimesPerWeek: Value(p.maxTimesPerWeek),
          lastModifiedMs: Value(p.lastModified.millisecondsSinceEpoch),
          commentJson: Value(
            p.comment != null && p.comment!.isNotEmpty
                ? encodeComment(p.comment!)
                : null,
          ),
          ingredients: Value(p.ingredients),
        ),
      );

  @override
  Future<void> deleteCustomProduct(String id) =>
      _db.userCustomProductsDao.deleteById(id);

  // ── Collection items (product lifecycle) ──────────────────────────────────

  @override
  Stream<List<CollectionItem>> watchCollectionItems() =>
      _db.collectionItemsDao.watchAll().map(
            (rows) => rows.map(_collectionItemFromRow).toList(),
          );

  @override
  Future<void> upsertCollectionItem(CollectionItem item) =>
      _db.collectionItemsDao.upsert(
        CollectionItemsCompanion(
          id: Value(item.id),
          productId: Value(item.productId),
          status: Value(item.status.name),
          openedDateMs: Value(item.openedDate?.millisecondsSinceEpoch),
          paoMonths: Value(item.paoMonths),
          notificationsEnabled: Value(item.notificationsEnabled),
          lastModifiedMs: Value(item.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> deleteCollectionItem(String id) =>
      _db.collectionItemsDao.deleteById(id);

  // ── Category overrides ────────────────────────────────────────────────────

  @override
  Stream<List<CategoryOverride>> watchCategoryOverrides() =>
      _db.categoryOverridesDao.watchAll().map(
            (rows) => rows.map(_categoryOverrideFromRow).toList(),
          );

  @override
  Future<void> upsertCategoryOverride(CategoryOverride o) =>
      _db.categoryOverridesDao.upsert(
        CategoryOverridesCompanion(
          id: Value(o.id),
          productId: Value(o.productId),
          categoryId: Value(o.categoryId),
          lastModifiedMs: Value(o.lastModified.millisecondsSinceEpoch),
        ),
      );

  @override
  Future<void> deleteCategoryOverride(String productId) =>
      _db.categoryOverridesDao.deleteByProductId(productId);

  // ── Export / Import ───────────────────────────────────────────────────────

  @override
  Future<UserDataExport> exportAllData() async {
    final selRows = await _db.selectionsDao.watchAll().first;
    final schRows = await _db.schedulesDao.watchAll().first;
    final ovrRows = await _db.orderOverridesDao.watchAll().first;
    final drRows = await _db.dayRecordsDao.watchAll().first;
    final slRows = await _db.skinLogDao.watchAll().first;
    final mcRows = await _db.mutedConflictsDao.watchAll().first;
    final ciRows = await _db.collectionItemsDao.watchAll().first;
    final coRows = await _db.categoryOverridesDao.watchAll().first;

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
      collectionItems: ciRows.map(_collectionItemFromRow).toList(),
      categoryOverrides: coRows.map(_categoryOverrideFromRow).toList(),
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
      await _db.collectionItemsDao.deleteAll();
      await _db.categoryOverridesDao.deleteAll();
      // Derived cache — rebuilt by the updateDayRecord loop below.
      await _db.productUseTimestampsDao.deleteAll();

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
      for (final c in export.collectionItems) {
        await upsertCollectionItem(c);
      }
      for (final o in export.categoryOverrides) {
        await upsertCategoryOverride(o);
      }
    });
  }

  @override
  Future<void> clearRoutineData() async {
    await _db.transaction(() async {
      await _db.schedulesDao.deleteAll();
      await _db.orderOverridesDao.deleteAll();
      await _db.dayRecordsDao.deleteAll();
      await _db.skinLogDao.deleteAll();
      await _db.mutedConflictsDao.deleteAll();
      // Derived from day records — clear it when day records are cleared.
      await _db.productUseTimestampsDao.deleteAll();
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
        weekday: r.weekday,
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

  ProductUseTimestamp _productUseTimestampFromRow(ProductUseTimestampRow r) =>
      ProductUseTimestamp(
        productId: r.productId,
        firstUsedAt: DateTime.fromMillisecondsSinceEpoch(r.firstUsedAtMs),
        lastUsedAt: DateTime.fromMillisecondsSinceEpoch(r.lastUsedAtMs),
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
        brand: r.brand,
        name: r.name,
        photoKey: r.photoKey,
        categoryId: r.categoryId,
        subCategoryId: r.subCategoryId,
        inMorning: r.inMorning,
        inEvening: r.inEvening,
        isDaily: r.isDaily,
        maxTimesPerWeek: r.maxTimesPerWeek,
        lastModified: DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
        comment: r.commentJson != null ? decodeComment(r.commentJson!) : null,
        ingredients: r.ingredients,
      );

  CollectionItem _collectionItemFromRow(CollectionItemRow r) => CollectionItem(
        id: r.id,
        productId: r.productId,
        status: CollectionStatus.values.firstWhere((s) => s.name == r.status),
        openedDate: r.openedDateMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r.openedDateMs!),
        paoMonths: r.paoMonths,
        notificationsEnabled: r.notificationsEnabled,
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

  CategoryOverride _categoryOverrideFromRow(CategoryOverrideRow r) =>
      CategoryOverride(
        id: r.id,
        productId: r.productId,
        categoryId: r.categoryId,
        lastModified: DateTime.fromMillisecondsSinceEpoch(r.lastModifiedMs),
      );
}
