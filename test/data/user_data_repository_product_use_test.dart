// REQ: marking a product done records first-used / last-used timestamps, keyed
// off the recorded routine date and derived from the DayRecords table. Marking
// extends the window; un-marking (incl. accidental tap) reverts it.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';
import 'package:skincare_tracker/data/repositories_impl/user_data_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/product_use_timestamp.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';

void main() {
  late AppDatabase db;
  late UserDataRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = UserDataRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  DayRecord rec(String date, Slot slot, List<String> recorded) => DayRecord(
        id: '${date}_${slot.name}',
        date: date,
        slot: slot,
        resolvedProductIds: recorded,
        recordedProductIds: recorded,
        resolvedAtMasterVersion: '1.0.0',
        lastModified: DateTime(2026),
      );

  Future<ProductUseTimestamp?> usage(String productId) async {
    final all = await repo.watchProductUseTimestamps().first;
    final match = all.where((u) => u.productId == productId);
    return match.isEmpty ? null : match.first;
  }

  test('marking a product sets firstUsed == lastUsed == the recorded date',
      () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1']));

    final u = await usage('p1');
    expect(u, isNotNull);
    expect(u!.firstUsedAt, DateTime(2026, 6, 10));
    expect(u.lastUsedAt, DateTime(2026, 6, 10));
  });

  test('marking on a later date extends lastUsed only', () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1']));
    await repo.updateDayRecord(rec('2026-06-15', Slot.evening, ['p1']));

    final u = await usage('p1');
    expect(u!.firstUsedAt, DateTime(2026, 6, 10));
    expect(u.lastUsedAt, DateTime(2026, 6, 15));
  });

  test('marking on an earlier (past) date moves firstUsed only', () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1']));
    await repo.updateDayRecord(rec('2026-06-15', Slot.evening, ['p1']));
    await repo.updateDayRecord(rec('2026-06-01', Slot.morning, ['p1']));

    final u = await usage('p1');
    expect(u!.firstUsedAt, DateTime(2026, 6, 1));
    expect(u.lastUsedAt, DateTime(2026, 6, 15));
  });

  test('un-marking the only record deletes the timestamp (accidental tap)',
      () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1']));
    // immediately un-mark: same record, p1 removed
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, []));

    expect(await usage('p1'), isNull);
  });

  test('un-marking the latest record recomputes lastUsed to previous max',
      () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1']));
    await repo.updateDayRecord(rec('2026-06-15', Slot.evening, ['p1']));
    // un-mark the later record
    await repo.updateDayRecord(rec('2026-06-15', Slot.evening, []));

    final u = await usage('p1');
    expect(u!.firstUsedAt, DateTime(2026, 6, 10));
    expect(u.lastUsedAt, DateTime(2026, 6, 10));
  });

  test('timestamps are independent per product', () async {
    await repo.updateDayRecord(rec('2026-06-10', Slot.morning, ['p1', 'p2']));
    await repo.updateDayRecord(rec('2026-06-20', Slot.morning, ['p2']));

    expect((await usage('p1'))!.lastUsedAt, DateTime(2026, 6, 10));
    expect((await usage('p2'))!.lastUsedAt, DateTime(2026, 6, 20));
  });
}
