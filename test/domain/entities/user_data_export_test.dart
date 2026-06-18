// ignore_for_file: directives_ordering
import 'package:flutter_test/flutter_test.dart';
import 'package:skincare_tracker/domain/entities/category_override.dart';
import 'package:skincare_tracker/domain/entities/day_record.dart';
import 'package:skincare_tracker/domain/entities/muted_conflict.dart';
import 'package:skincare_tracker/domain/entities/order_override.dart';
import 'package:skincare_tracker/domain/entities/product_selection.dart';
import 'package:skincare_tracker/domain/entities/skin_log_entry.dart';
import 'package:skincare_tracker/domain/entities/user_data_export.dart';
import 'package:skincare_tracker/domain/entities/weekday_schedule.dart';
import 'package:skincare_tracker/domain/enums/slot.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

ProductSelection makeSelection({String id = 'sel1'}) => ProductSelection(
      id: id,
      productId: 'prod1',
      slot: Slot.morning,
      isSelected: true,
      lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 123),
    );

WeekdaySchedule makeSchedule({String id = 'sch1'}) => WeekdaySchedule(
      id: id,
      productId: 'prod2',
      slot: Slot.evening,
      weekdays: {1, 3, 5},
      lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 456),
    );

OrderOverride makeOverride({String id = 'ovr1'}) => OrderOverride(
      id: id,
      slot: Slot.morning,
      orderedProductIds: ['prod3', 'prod1', 'prod2'],
      lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 789),
    );

DayRecord makeDayRecord({String id = 'dr1'}) => DayRecord(
      id: id,
      date: '2024-03-15',
      slot: Slot.morning,
      resolvedProductIds: ['prod1', 'prod2'],
      recordedProductIds: ['prod1'],
      resolvedAtMasterVersion: '1.2.0',
      lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 111),
    );

SkinLogEntry makeSkinLog({String id = 'log1'}) => SkinLogEntry(
      id: id,
      date: '2024-03-15',
      notes: 'feeling good',
      skinState: 'calm',
      photoPaths: ['photo_a', 'photo_b'],
      lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 222),
    );

MutedConflict makeMutedConflict({String id = 'mc1'}) => MutedConflict(
      id: id,
      ruleId: 'rule1',
      mutedAt: DateTime.utc(2024, 3, 15, 10, 0, 0, 333),
    );

UserDataExport fullExport() => UserDataExport(
      schemaVersion: '2',
      exportDate: '2024-03-15T10:00:00.000Z',
      appVersion: '1.0.0',
      masterContentVersion: '1.2.0',
      selections: [makeSelection()],
      schedules: [makeSchedule()],
      overrides: [makeOverride()],
      dayRecords: [makeDayRecord()],
      skinLogs: [makeSkinLog()],
      mutedConflicts: [makeMutedConflict()],
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('UserDataExport — full round-trip for all entity types', () {
    test('ProductSelection survives toJson → fromJson', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final sel = restored.selections.first;
      expect(sel.id, 'sel1');
      expect(sel.productId, 'prod1');
      expect(sel.slot, Slot.morning);
      expect(sel.isSelected, isTrue);
      expect(sel.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 123));
    });

    test('WeekdaySchedule survives toJson → fromJson', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final sch = restored.schedules.first;
      expect(sch.id, 'sch1');
      expect(sch.productId, 'prod2');
      expect(sch.slot, Slot.evening);
      expect(sch.weekdays, {1, 3, 5});
      expect(sch.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 456));
    });

    test('OrderOverride survives toJson → fromJson', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final ovr = restored.overrides.first;
      expect(ovr.id, 'ovr1');
      expect(ovr.slot, Slot.morning);
      expect(ovr.orderedProductIds, ['prod3', 'prod1', 'prod2']);
      expect(ovr.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 789));
    });

    test('DayRecord survives toJson → fromJson', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final dr = restored.dayRecords.first;
      expect(dr.id, 'dr1');
      expect(dr.date, '2024-03-15');
      expect(dr.slot, Slot.morning);
      expect(dr.resolvedProductIds, ['prod1', 'prod2']);
      expect(dr.recordedProductIds, ['prod1']);
      expect(dr.resolvedAtMasterVersion, '1.2.0');
      expect(dr.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 111));
    });

    test('SkinLogEntry survives toJson → fromJson with all fields', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final log = restored.skinLogs.first;
      expect(log.id, 'log1');
      expect(log.date, '2024-03-15');
      expect(log.notes, 'feeling good');
      expect(log.skinState, 'calm');
      expect(log.photoPaths, ['photo_a', 'photo_b']);
      expect(log.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 222));
    });

    test('MutedConflict survives toJson → fromJson', () {
      final export = fullExport();
      final restored = UserDataExport.fromJson(export.toJson());

      final mc = restored.mutedConflicts.first;
      expect(mc.id, 'mc1');
      expect(mc.ruleId, 'rule1');
      expect(mc.mutedAt, DateTime.utc(2024, 3, 15, 10, 0, 0, 333));
    });

    test('schemaVersion present in output', () {
      final json = fullExport().toJson();
      expect(json['schemaVersion'], isNotNull);
    });

    test('all lastModified timestamps preserved to millisecond', () {
      final export = fullExport();
      final json = export.toJson();
      final restored = UserDataExport.fromJson(json);

      expect(restored.selections.first.lastModified.millisecondsSinceEpoch,
          makeSelection().lastModified.millisecondsSinceEpoch);
      expect(restored.schedules.first.lastModified.millisecondsSinceEpoch,
          makeSchedule().lastModified.millisecondsSinceEpoch);
      expect(restored.overrides.first.lastModified.millisecondsSinceEpoch,
          makeOverride().lastModified.millisecondsSinceEpoch);
      expect(restored.dayRecords.first.lastModified.millisecondsSinceEpoch,
          makeDayRecord().lastModified.millisecondsSinceEpoch);
      expect(restored.skinLogs.first.lastModified.millisecondsSinceEpoch,
          makeSkinLog().lastModified.millisecondsSinceEpoch);
      expect(restored.mutedConflicts.first.mutedAt.millisecondsSinceEpoch,
          makeMutedConflict().mutedAt.millisecondsSinceEpoch);
    });

    test('missing optional fields in legacy JSON default gracefully', () {
      final json = <String, dynamic>{
        'schemaVersion': '1',
        'exportDate': '2024-01-01T00:00:00.000Z',
        'appVersion': '1.0.0',
        'masterContentVersion': '1.0.0',
        'selections': <dynamic>[],
        'schedules': <dynamic>[],
        'overrides': <dynamic>[],
        'dayRecords': <dynamic>[],
        'skinLogs': <dynamic>[],
        'mutedConflicts': <dynamic>[],
        // lastExportDate and lastKnownMasterVersion deliberately absent
      };

      final restored = UserDataExport.fromJson(json);

      expect(restored.lastExportDate, isNull);
      expect(restored.lastKnownMasterVersion, isNull);
    });
  });

  group('OrderOverride weekday round-trip', () {
    test('per-day override with weekday survives toJson → fromJson', () {
      final override = OrderOverride(
        id: 'ovr-wed',
        slot: Slot.morning,
        weekday: 3,
        orderedProductIds: ['p1', 'p2'],
        lastModified: DateTime.utc(2024, 3, 15),
      );
      final export = UserDataExport(
        schemaVersion: '2',
        exportDate: '2024-03-15T00:00:00.000Z',
        appVersion: '1.0.0',
        masterContentVersion: '1.0.0',
        selections: const [],
        schedules: const [],
        overrides: [override],
        dayRecords: const [],
        skinLogs: const [],
        mutedConflicts: const [],
      );

      final restored = UserDataExport.fromJson(export.toJson());
      expect(restored.overrides.first.weekday, 3);
    });

    test('global override (weekday=null) survives round-trip', () {
      final override = OrderOverride(
        id: 'ovr-global',
        slot: Slot.evening,
        orderedProductIds: ['p1'],
        lastModified: DateTime.utc(2024, 3, 15),
      );
      final export = UserDataExport(
        schemaVersion: '2',
        exportDate: '2024-03-15T00:00:00.000Z',
        appVersion: '1.0.0',
        masterContentVersion: '1.0.0',
        selections: const [],
        schedules: const [],
        overrides: [override],
        dayRecords: const [],
        skinLogs: const [],
        mutedConflicts: const [],
      );

      final restored = UserDataExport.fromJson(export.toJson());
      expect(restored.overrides.first.weekday, isNull);
    });

    test('legacy export without weekday field deserializes to null', () {
      final json = <String, dynamic>{
        'schemaVersion': '1',
        'exportDate': '2024-01-01T00:00:00.000Z',
        'appVersion': '1.0.0',
        'masterContentVersion': '1.0.0',
        'selections': <dynamic>[],
        'schedules': <dynamic>[],
        'overrides': <dynamic>[
          {
            'id': 'ovr1',
            'slot': 'morning',
            'orderedProductIds': <dynamic>['p1'],
            'lastModified': '2024-01-01T00:00:00.000Z',
            // weekday key deliberately absent (legacy format)
          }
        ],
        'dayRecords': <dynamic>[],
        'skinLogs': <dynamic>[],
        'mutedConflicts': <dynamic>[],
      };

      final restored = UserDataExport.fromJson(json);
      expect(restored.overrides.first.weekday, isNull);
    });
  });

  group('SkinLogEntry skinState round-trip through UserDataExport', () {
    UserDataExport makeExport(List<SkinLogEntry> skinLogs) => UserDataExport(
          schemaVersion: '2',
          exportDate: '2024-01-01T00:00:00.000Z',
          appVersion: '1.0.0',
          masterContentVersion: '1.0.0',
          selections: const <ProductSelection>[],
          schedules: const <WeekdaySchedule>[],
          overrides: const <OrderOverride>[],
          dayRecords: const <DayRecord>[],
          skinLogs: skinLogs,
          mutedConflicts: const <MutedConflict>[],
        );

    test('skinState preserved when non-null', () {
      final entry = SkinLogEntry(
        id: 'id1',
        date: '2024-01-01',
        skinState: 'oily',
        photoPaths: const [],
        lastModified: DateTime.utc(2024, 1, 1),
      );

      final json = makeExport([entry]).toJson();
      final restored = UserDataExport.fromJson(json);

      expect(restored.skinLogs.first.skinState, 'oily');
    });

    test('skinState preserved when null', () {
      final entry = SkinLogEntry(
        id: 'id1',
        date: '2024-01-01',
        photoPaths: const [],
        lastModified: DateTime.utc(2024, 1, 1),
      );

      final json = makeExport([entry]).toJson();
      final restored = UserDataExport.fromJson(json);

      expect(restored.skinLogs.first.skinState, isNull);
    });

    test('legacy export without skinState field deserializes to null', () {
      final json = <String, dynamic>{
        'schemaVersion': '1',
        'exportDate': '2024-01-01T00:00:00.000Z',
        'appVersion': '1.0.0',
        'masterContentVersion': '1.0.0',
        'selections': <dynamic>[],
        'schedules': <dynamic>[],
        'overrides': <dynamic>[],
        'dayRecords': <dynamic>[],
        'skinLogs': <dynamic>[
          {
            'id': 'id1',
            'date': '2024-01-01',
            'notes': null,
            'photoPaths': <dynamic>[],
            'lastModified': '2024-01-01T00:00:00.000Z',
            // skinState key deliberately absent (legacy format)
          }
        ],
        'mutedConflicts': <dynamic>[],
      };

      final restored = UserDataExport.fromJson(json);

      expect(restored.skinLogs.first.skinState, isNull);
    });
  });

  group('CategoryOverride round-trip', () {
    CategoryOverride makeCatOverride({String id = 'co1'}) => CategoryOverride(
          id: id,
          productId: 'prod1',
          categoryId: 'cat-toner',
          lastModified: DateTime.utc(2024, 3, 15, 10, 0, 0, 444),
        );

    UserDataExport exportWith(List<CategoryOverride> catOverrides) =>
        UserDataExport(
          schemaVersion: '2',
          exportDate: '2024-03-15T10:00:00.000Z',
          appVersion: '1.0.0',
          masterContentVersion: '1.2.0',
          selections: const [],
          schedules: const [],
          overrides: const [],
          dayRecords: const [],
          skinLogs: const [],
          mutedConflicts: const [],
          categoryOverrides: catOverrides,
        );

    test('CategoryOverride survives toJson → fromJson', () {
      final export = exportWith([makeCatOverride()]);
      final restored = UserDataExport.fromJson(export.toJson());

      final co = restored.categoryOverrides.first;
      expect(co.id, 'co1');
      expect(co.productId, 'prod1');
      expect(co.categoryId, 'cat-toner');
      expect(co.lastModified, DateTime.utc(2024, 3, 15, 10, 0, 0, 444));
    });

    test('lastModified preserved to millisecond', () {
      final export = exportWith([makeCatOverride()]);
      final restored = UserDataExport.fromJson(export.toJson());

      expect(
        restored.categoryOverrides.first.lastModified.millisecondsSinceEpoch,
        makeCatOverride().lastModified.millisecondsSinceEpoch,
      );
    });

    test('legacy export without categoryOverrides field defaults to empty list',
        () {
      final json = <String, dynamic>{
        'schemaVersion': '1',
        'exportDate': '2024-01-01T00:00:00.000Z',
        'appVersion': '1.0.0',
        'masterContentVersion': '1.0.0',
        'selections': <dynamic>[],
        'schedules': <dynamic>[],
        'overrides': <dynamic>[],
        'dayRecords': <dynamic>[],
        'skinLogs': <dynamic>[],
        'mutedConflicts': <dynamic>[],
        // categoryOverrides deliberately absent
      };

      final restored = UserDataExport.fromJson(json);
      expect(restored.categoryOverrides, isEmpty);
    });
  });
}
