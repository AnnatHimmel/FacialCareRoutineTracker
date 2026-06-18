import 'package:meta/meta.dart';
import 'category_override.dart';
import 'product_selection.dart';
import 'weekday_schedule.dart';
import 'order_override.dart';
import 'day_record.dart';
import 'skin_log_entry.dart';
import 'muted_conflict.dart';
import 'collection_item.dart';
import '../enums/slot.dart';
import '../enums/collection_status.dart';

@immutable
class UserDataExport {
  final String schemaVersion;
  final String exportDate;
  final String appVersion;
  final String masterContentVersion;
  final List<ProductSelection> selections;
  final List<WeekdaySchedule> schedules;
  final List<OrderOverride> overrides;
  final List<DayRecord> dayRecords;
  final List<SkinLogEntry> skinLogs;
  final List<MutedConflict> mutedConflicts;
  final List<CollectionItem> collectionItems;
  final List<CategoryOverride> categoryOverrides;
  final String? lastExportDate;
  final String? lastKnownMasterVersion;

  const UserDataExport({
    required this.schemaVersion,
    required this.exportDate,
    required this.appVersion,
    required this.masterContentVersion,
    required this.selections,
    required this.schedules,
    required this.overrides,
    required this.dayRecords,
    required this.skinLogs,
    required this.mutedConflicts,
    this.collectionItems = const [],
    this.categoryOverrides = const [],
    this.lastExportDate,
    this.lastKnownMasterVersion,
  });

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'exportDate': exportDate,
        'appVersion': appVersion,
        'masterContentVersion': masterContentVersion,
        'lastExportDate': lastExportDate,
        'lastKnownMasterVersion': lastKnownMasterVersion,
        'selections': selections.map(_selectionToJson).toList(),
        'schedules': schedules.map(_scheduleToJson).toList(),
        'overrides': overrides.map(_overrideToJson).toList(),
        'dayRecords': dayRecords.map(_dayRecordToJson).toList(),
        'skinLogs': skinLogs.map(_skinLogToJson).toList(),
        'mutedConflicts': mutedConflicts.map(_mutedConflictToJson).toList(),
        'collectionItems':
            collectionItems.map(_collectionItemToJson).toList(),
        'categoryOverrides':
            categoryOverrides.map(_categoryOverrideToJson).toList(),
      };

  static UserDataExport fromJson(Map<String, dynamic> json) => UserDataExport(
        schemaVersion: json['schemaVersion'] as String? ?? '1',
        exportDate: json['exportDate'] as String? ?? '',
        appVersion: json['appVersion'] as String? ?? '1.0.0',
        masterContentVersion: json['masterContentVersion'] as String? ?? '',
        lastExportDate: json['lastExportDate'] as String?,
        lastKnownMasterVersion: json['lastKnownMasterVersion'] as String?,
        selections: (json['selections'] as List<dynamic>? ?? [])
            .map((e) => _selectionFromJson(e as Map<String, dynamic>))
            .toList(),
        schedules: (json['schedules'] as List<dynamic>? ?? [])
            .map((e) => _scheduleFromJson(e as Map<String, dynamic>))
            .toList(),
        overrides: (json['overrides'] as List<dynamic>? ?? [])
            .map((e) => _overrideFromJson(e as Map<String, dynamic>))
            .toList(),
        dayRecords: (json['dayRecords'] as List<dynamic>? ?? [])
            .map((e) => _dayRecordFromJson(e as Map<String, dynamic>))
            .toList(),
        skinLogs: (json['skinLogs'] as List<dynamic>? ?? [])
            .map((e) => _skinLogFromJson(e as Map<String, dynamic>))
            .toList(),
        mutedConflicts: (json['mutedConflicts'] as List<dynamic>? ?? [])
            .map((e) => _mutedConflictFromJson(e as Map<String, dynamic>))
            .toList(),
        collectionItems: (json['collectionItems'] as List<dynamic>? ?? [])
            .map((e) => _collectionItemFromJson(e as Map<String, dynamic>))
            .toList(),
        categoryOverrides:
            (json['categoryOverrides'] as List<dynamic>? ?? [])
                .map((e) => _categoryOverrideFromJson(e as Map<String, dynamic>))
                .toList(),
      );

  @override
  bool operator ==(Object other) =>
      other is UserDataExport &&
      other.schemaVersion == schemaVersion &&
      other.exportDate == exportDate &&
      other.appVersion == appVersion &&
      other.masterContentVersion == masterContentVersion &&
      other.lastExportDate == lastExportDate &&
      other.lastKnownMasterVersion == lastKnownMasterVersion;

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        exportDate,
        appVersion,
        masterContentVersion,
        lastExportDate,
        lastKnownMasterVersion,
      );

  UserDataExport copyWith({
    String? schemaVersion,
    String? exportDate,
    String? appVersion,
    String? masterContentVersion,
    List<ProductSelection>? selections,
    List<WeekdaySchedule>? schedules,
    List<OrderOverride>? overrides,
    List<DayRecord>? dayRecords,
    List<SkinLogEntry>? skinLogs,
    List<MutedConflict>? mutedConflicts,
    List<CollectionItem>? collectionItems,
    List<CategoryOverride>? categoryOverrides,
    String? lastExportDate,
    String? lastKnownMasterVersion,
  }) =>
      UserDataExport(
        schemaVersion: schemaVersion ?? this.schemaVersion,
        exportDate: exportDate ?? this.exportDate,
        appVersion: appVersion ?? this.appVersion,
        masterContentVersion: masterContentVersion ?? this.masterContentVersion,
        selections: selections ?? this.selections,
        schedules: schedules ?? this.schedules,
        overrides: overrides ?? this.overrides,
        dayRecords: dayRecords ?? this.dayRecords,
        skinLogs: skinLogs ?? this.skinLogs,
        mutedConflicts: mutedConflicts ?? this.mutedConflicts,
        collectionItems: collectionItems ?? this.collectionItems,
        categoryOverrides: categoryOverrides ?? this.categoryOverrides,
        lastExportDate: lastExportDate ?? this.lastExportDate,
        lastKnownMasterVersion:
            lastKnownMasterVersion ?? this.lastKnownMasterVersion,
      );

  // ── Serialization helpers ─────────────────────────────────────────────────

  static Map<String, dynamic> _selectionToJson(ProductSelection s) => {
        'id': s.id,
        'productId': s.productId,
        'slot': s.slot.name,
        'isSelected': s.isSelected,
        'lastModified': s.lastModified.toIso8601String(),
      };

  static ProductSelection _selectionFromJson(Map<String, dynamic> m) =>
      ProductSelection(
        id: m['id'] as String,
        productId: m['productId'] as String,
        slot: Slot.values.firstWhere((s) => s.name == m['slot']),
        isSelected: m['isSelected'] as bool,
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _scheduleToJson(WeekdaySchedule s) => {
        'id': s.id,
        'productId': s.productId,
        'slot': s.slot.name,
        'weekdays': s.weekdays.toList()..sort(),
        'lastModified': s.lastModified.toIso8601String(),
      };

  static WeekdaySchedule _scheduleFromJson(Map<String, dynamic> m) =>
      WeekdaySchedule(
        id: m['id'] as String,
        productId: m['productId'] as String,
        slot: Slot.values.firstWhere((s) => s.name == m['slot']),
        weekdays: (m['weekdays'] as List<dynamic>).cast<int>().toSet(),
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _overrideToJson(OrderOverride o) => {
        'id': o.id,
        'slot': o.slot.name,
        'weekday': o.weekday,
        'orderedProductIds': o.orderedProductIds,
        'lastModified': o.lastModified.toIso8601String(),
      };

  static OrderOverride _overrideFromJson(Map<String, dynamic> m) =>
      OrderOverride(
        id: m['id'] as String,
        slot: Slot.values.firstWhere((s) => s.name == m['slot']),
        weekday: m['weekday'] as int?,
        orderedProductIds:
            (m['orderedProductIds'] as List<dynamic>).cast<String>(),
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _dayRecordToJson(DayRecord r) => {
        'id': r.id,
        'date': r.date,
        'slot': r.slot.name,
        'resolvedProductIds': r.resolvedProductIds,
        'recordedProductIds': r.recordedProductIds,
        'resolvedAtMasterVersion': r.resolvedAtMasterVersion,
        'lastModified': r.lastModified.toIso8601String(),
      };

  static DayRecord _dayRecordFromJson(Map<String, dynamic> m) => DayRecord(
        id: m['id'] as String,
        date: m['date'] as String,
        slot: Slot.values.firstWhere((s) => s.name == m['slot']),
        resolvedProductIds:
            (m['resolvedProductIds'] as List<dynamic>).cast<String>(),
        recordedProductIds:
            (m['recordedProductIds'] as List<dynamic>).cast<String>(),
        resolvedAtMasterVersion: m['resolvedAtMasterVersion'] as String,
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _skinLogToJson(SkinLogEntry e) => {
        'id': e.id,
        'date': e.date,
        'notes': e.notes,
        'skinState': e.skinState,
        'photoPaths': e.photoPaths,
        'lastModified': e.lastModified.toIso8601String(),
      };

  static SkinLogEntry _skinLogFromJson(Map<String, dynamic> m) => SkinLogEntry(
        id: m['id'] as String,
        date: m['date'] as String,
        notes: m['notes'] as String?,
        skinState: m['skinState'] as String?,
        photoPaths: (m['photoPaths'] as List<dynamic>).cast<String>(),
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _mutedConflictToJson(MutedConflict c) => {
        'id': c.id,
        'ruleId': c.ruleId,
        'mutedAt': c.mutedAt.toIso8601String(),
      };

  static MutedConflict _mutedConflictFromJson(Map<String, dynamic> m) =>
      MutedConflict(
        id: m['id'] as String,
        ruleId: m['ruleId'] as String,
        mutedAt: DateTime.parse(m['mutedAt'] as String),
      );

  static Map<String, dynamic> _collectionItemToJson(CollectionItem c) => {
        'id': c.id,
        'productId': c.productId,
        'status': c.status.name,
        'openedDate': c.openedDate?.toIso8601String(),
        'paoMonths': c.paoMonths,
        'notificationsEnabled': c.notificationsEnabled,
        'lastModified': c.lastModified.toIso8601String(),
      };

  static CollectionItem _collectionItemFromJson(Map<String, dynamic> m) =>
      CollectionItem(
        id: m['id'] as String,
        productId: m['productId'] as String,
        status: CollectionStatus.values.firstWhere(
          (s) => s.name == m['status'],
          orElse: () => CollectionStatus.inUse,
        ),
        openedDate: m['openedDate'] == null
            ? null
            : DateTime.parse(m['openedDate'] as String),
        paoMonths: m['paoMonths'] as int,
        notificationsEnabled: m['notificationsEnabled'] as bool? ?? true,
        lastModified: DateTime.parse(m['lastModified'] as String),
      );

  static Map<String, dynamic> _categoryOverrideToJson(CategoryOverride o) => {
        'id': o.id,
        'productId': o.productId,
        'categoryId': o.categoryId,
        'lastModified': o.lastModified.toIso8601String(),
      };

  static CategoryOverride _categoryOverrideFromJson(Map<String, dynamic> m) =>
      CategoryOverride(
        id: m['id'] as String,
        productId: m['productId'] as String,
        categoryId: m['categoryId'] as String,
        lastModified: DateTime.parse(m['lastModified'] as String),
      );
}
