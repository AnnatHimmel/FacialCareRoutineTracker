import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';
import 'package:skincare_tracker/data/repositories_impl/user_data_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
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

  group('clearRoutineData', () {
    test('deletes schedules, order overrides, and muted conflicts', () async {
      await repo.upsertSchedule(WeekdaySchedule(
        id: 's1',
        productId: 'prod-1',
        slot: Slot.evening,
        weekdays: {0, 2, 4},
        lastModified: DateTime(2026),
      ));
      await repo.upsertOrderOverride(OrderOverride(
        id: 'o1',
        slot: Slot.evening,
        orderedProductIds: ['prod-1', 'prod-2'],
        lastModified: DateTime(2026),
      ));
      await repo.muteConflict(MutedConflict(
        id: 'mc-1',
        ruleId: 'rule-003',
        mutedAt: DateTime(2026),
      ));

      await repo.clearRoutineData();

      final schedules = await repo.watchAllSchedules().first;
      expect(schedules, isEmpty, reason: 'schedules must be deleted');

      final overrides = await repo.watchPerDayOrderOverrides(Slot.evening).first;
      expect(overrides, isEmpty, reason: 'order overrides must be deleted');

      final muted = await repo.watchMutedConflicts().first;
      expect(muted, isEmpty, reason: 'muted conflicts must be deleted');
    });

    test('keeps product selections intact', () async {
      await repo.upsertSelection(ProductSelection(
        id: 'sel-1',
        productId: 'prod-acid',
        slot: Slot.evening,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSelection(ProductSelection(
        id: 'sel-2',
        productId: 'prod-retinoid',
        slot: Slot.evening,
        isSelected: true,
        lastModified: DateTime(2026),
      ));

      await repo.clearRoutineData();

      final selections = await repo.watchSelections(Slot.evening).first;
      expect(
        selections.where((s) => s.isSelected).length,
        equals(2),
        reason: 'product selections must survive clearRoutineData',
      );
    });

    test('schedules deleted but selections kept when both present', () async {
      await repo.upsertSelection(ProductSelection(
        id: 'sel-3',
        productId: 'prod-X',
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSchedule(WeekdaySchedule(
        id: 's2',
        productId: 'prod-X',
        slot: Slot.morning,
        weekdays: {1, 3, 5},
        lastModified: DateTime(2026),
      ));

      await repo.clearRoutineData();

      final schedules = await repo.watchAllSchedules().first;
      final selections = await repo.watchSelections(Slot.morning).first;

      expect(schedules, isEmpty);
      expect(selections.where((s) => s.isSelected).length, equals(1));
    });
  });
}
