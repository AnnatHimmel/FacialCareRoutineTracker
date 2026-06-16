import '../entities/collection_item.dart';
import '../entities/product_selection.dart';
import '../entities/weekday_schedule.dart';
import '../entities/order_override.dart';
import '../entities/day_record.dart';
import '../entities/skin_log_entry.dart';
import '../entities/muted_conflict.dart';
import '../entities/user_custom_product.dart';
import '../entities/user_data_export.dart';
import '../enums/slot.dart';

abstract class UserDataRepository {
  Stream<List<ProductSelection>> watchSelections(Slot slot);
  Future<void> upsertSelection(ProductSelection s);

  Stream<WeekdaySchedule?> watchSchedule(String productId, Slot slot);
  Stream<List<WeekdaySchedule>> watchAllSchedules();
  Future<void> upsertSchedule(WeekdaySchedule s);

  Stream<OrderOverride?> watchOrderOverride(Slot slot);
  Future<void> upsertOrderOverride(OrderOverride o);
  Future<void> deleteOrderOverride(Slot slot);

  Stream<DayRecord?> watchDayRecord(String date, Slot slot);
  Future<DayRecord> snapshotAndGetDayRecord(
    String date,
    Slot slot,
    List<String> resolvedProductIds,
    String masterVersion,
  );
  Future<void> updateDayRecord(DayRecord r);
  Stream<List<DayRecord>> watchDayRecordsForMonth(String yearMonth);
  Stream<List<DayRecord>> watchAllDayRecords();

  Stream<SkinLogEntry?> watchSkinLog(String date);
  Future<void> upsertSkinLog(SkinLogEntry e);
  Stream<List<SkinLogEntry>> watchAllSkinLogs();

  Stream<List<MutedConflict>> watchMutedConflicts();
  Future<void> muteConflict(MutedConflict m);
  Future<void> unmuteConflict(String ruleId);

  Stream<List<UserCustomProduct>> watchCustomProducts();
  Future<void> upsertCustomProduct(UserCustomProduct p);
  Future<void> deleteCustomProduct(String id);

  Stream<List<CollectionItem>> watchCollectionItems();
  Future<void> upsertCollectionItem(CollectionItem item);
  Future<void> deleteCollectionItem(String id);

  Future<UserDataExport> exportAllData();
  Future<void> replaceAllData(UserDataExport export);
}
