import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/data/local/database/app_database.dart';
import 'package:skincare_tracker/data/repositories_impl/user_data_repository_impl.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/collection_item.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/entities/user_custom_product.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/enums/collection_status.dart';
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

  group('clearShelf', () {
    test('wipes products + routine wiring, keeps history', () async {
      // Shelf data
      await repo.upsertSelection(ProductSelection(
        id: 'sel-1',
        productId: 'prod-1',
        slot: Slot.morning,
        isSelected: true,
        lastModified: DateTime(2026),
      ));
      await repo.upsertSchedule(WeekdaySchedule(
        id: 's1',
        productId: 'prod-1',
        slot: Slot.morning,
        weekdays: {1, 3, 5},
        lastModified: DateTime(2026),
      ));
      await repo.upsertOrderOverride(OrderOverride(
        id: 'o1',
        slot: Slot.morning,
        orderedProductIds: ['prod-1'],
        lastModified: DateTime(2026),
      ));
      await repo.upsertCollectionItem(CollectionItem(
        id: 'ci-1',
        productId: 'prod-1',
        status: CollectionStatus.inUse,
        paoMonths: 12,
        lastModified: DateTime(2026),
      ));
      await repo.upsertCategoryOverride(CategoryOverride(
        id: 'co-1',
        productId: 'prod-1',
        categoryId: 'cat-x',
        lastModified: DateTime(2026),
      ));
      await repo.upsertCustomProduct(UserCustomProduct(
        id: 'cp-1',
        name: 'My Custom Serum',
        categoryId: 'cat-x',
        inMorning: true,
        inEvening: false,
        isDaily: true,
        lastModified: DateTime(2026),
      ));

      // History that must survive
      await repo.upsertSkinLog(SkinLogEntry(
        id: 'sl-1',
        date: '2026-06-20',
        photoPaths: const ['p1'],
        lastModified: DateTime(2026),
      ));

      await repo.clearShelf();

      expect(await repo.watchSelections(Slot.morning).first, isEmpty);
      expect(await repo.watchAllSchedules().first, isEmpty);
      expect(await repo.watchPerDayOrderOverrides(Slot.morning).first, isEmpty);
      expect(await repo.watchCollectionItems().first, isEmpty);
      expect(await repo.watchCategoryOverrides().first, isEmpty);
      expect(await repo.watchCustomProducts().first, isEmpty);

      // History preserved.
      expect(await repo.watchSkinLog('2026-06-20').first, isNotNull);
    });
  });
}
