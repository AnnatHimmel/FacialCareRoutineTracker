// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductSelectionsTable extends ProductSelections
    with TableInfo<$ProductSelectionsTable, SelectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductSelectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSelectedMeta = const VerificationMeta(
    'isSelected',
  );
  @override
  late final GeneratedColumn<bool> isSelected = GeneratedColumn<bool>(
    'is_selected',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_selected" IN (0, 1))',
    ),
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    slot,
    isSelected,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_selections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('is_selected')) {
      context.handle(
        _isSelectedMeta,
        isSelected.isAcceptableOrUnknown(data['is_selected']!, _isSelectedMeta),
      );
    } else if (isInserting) {
      context.missing(_isSelectedMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SelectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      isSelected: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_selected'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $ProductSelectionsTable createAlias(String alias) {
    return $ProductSelectionsTable(attachedDatabase, alias);
  }
}

class SelectionRow extends DataClass implements Insertable<SelectionRow> {
  final String id;
  final String productId;
  final String slot;
  final bool isSelected;
  final int lastModifiedMs;
  const SelectionRow({
    required this.id,
    required this.productId,
    required this.slot,
    required this.isSelected,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['slot'] = Variable<String>(slot);
    map['is_selected'] = Variable<bool>(isSelected);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  ProductSelectionsCompanion toCompanion(bool nullToAbsent) {
    return ProductSelectionsCompanion(
      id: Value(id),
      productId: Value(productId),
      slot: Value(slot),
      isSelected: Value(isSelected),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory SelectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectionRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      slot: serializer.fromJson<String>(json['slot']),
      isSelected: serializer.fromJson<bool>(json['isSelected']),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'slot': serializer.toJson<String>(slot),
      'isSelected': serializer.toJson<bool>(isSelected),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  SelectionRow copyWith({
    String? id,
    String? productId,
    String? slot,
    bool? isSelected,
    int? lastModifiedMs,
  }) => SelectionRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    slot: slot ?? this.slot,
    isSelected: isSelected ?? this.isSelected,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  SelectionRow copyWithCompanion(ProductSelectionsCompanion data) {
    return SelectionRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      slot: data.slot.present ? data.slot.value : this.slot,
      isSelected: data.isSelected.present
          ? data.isSelected.value
          : this.isSelected,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectionRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('slot: $slot, ')
          ..write('isSelected: $isSelected, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, slot, isSelected, lastModifiedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectionRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.slot == this.slot &&
          other.isSelected == this.isSelected &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class ProductSelectionsCompanion extends UpdateCompanion<SelectionRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> slot;
  final Value<bool> isSelected;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const ProductSelectionsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.slot = const Value.absent(),
    this.isSelected = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductSelectionsCompanion.insert({
    required String id,
    required String productId,
    required String slot,
    required bool isSelected,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       slot = Value(slot),
       isSelected = Value(isSelected),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<SelectionRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? slot,
    Expression<bool>? isSelected,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (slot != null) 'slot': slot,
      if (isSelected != null) 'is_selected': isSelected,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductSelectionsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? slot,
    Value<bool>? isSelected,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return ProductSelectionsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      slot: slot ?? this.slot,
      isSelected: isSelected ?? this.isSelected,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (isSelected.present) {
      map['is_selected'] = Variable<bool>(isSelected.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductSelectionsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('slot: $slot, ')
          ..write('isSelected: $isSelected, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WeekdaySchedulesTable extends WeekdaySchedules
    with TableInfo<$WeekdaySchedulesTable, ScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WeekdaySchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdaysJsonMeta = const VerificationMeta(
    'weekdaysJson',
  );
  @override
  late final GeneratedColumn<String> weekdaysJson = GeneratedColumn<String>(
    'weekdays_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    slot,
    weekdaysJson,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'weekday_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('weekdays_json')) {
      context.handle(
        _weekdaysJsonMeta,
        weekdaysJson.isAcceptableOrUnknown(
          data['weekdays_json']!,
          _weekdaysJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_weekdaysJsonMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      weekdaysJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}weekdays_json'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $WeekdaySchedulesTable createAlias(String alias) {
    return $WeekdaySchedulesTable(attachedDatabase, alias);
  }
}

class ScheduleRow extends DataClass implements Insertable<ScheduleRow> {
  final String id;
  final String productId;
  final String slot;
  final String weekdaysJson;
  final int lastModifiedMs;
  const ScheduleRow({
    required this.id,
    required this.productId,
    required this.slot,
    required this.weekdaysJson,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['slot'] = Variable<String>(slot);
    map['weekdays_json'] = Variable<String>(weekdaysJson);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  WeekdaySchedulesCompanion toCompanion(bool nullToAbsent) {
    return WeekdaySchedulesCompanion(
      id: Value(id),
      productId: Value(productId),
      slot: Value(slot),
      weekdaysJson: Value(weekdaysJson),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory ScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      slot: serializer.fromJson<String>(json['slot']),
      weekdaysJson: serializer.fromJson<String>(json['weekdaysJson']),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'slot': serializer.toJson<String>(slot),
      'weekdaysJson': serializer.toJson<String>(weekdaysJson),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  ScheduleRow copyWith({
    String? id,
    String? productId,
    String? slot,
    String? weekdaysJson,
    int? lastModifiedMs,
  }) => ScheduleRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    slot: slot ?? this.slot,
    weekdaysJson: weekdaysJson ?? this.weekdaysJson,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  ScheduleRow copyWithCompanion(WeekdaySchedulesCompanion data) {
    return ScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      slot: data.slot.present ? data.slot.value : this.slot,
      weekdaysJson: data.weekdaysJson.present
          ? data.weekdaysJson.value
          : this.weekdaysJson,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('slot: $slot, ')
          ..write('weekdaysJson: $weekdaysJson, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, slot, weekdaysJson, lastModifiedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.slot == this.slot &&
          other.weekdaysJson == this.weekdaysJson &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class WeekdaySchedulesCompanion extends UpdateCompanion<ScheduleRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> slot;
  final Value<String> weekdaysJson;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const WeekdaySchedulesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.slot = const Value.absent(),
    this.weekdaysJson = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WeekdaySchedulesCompanion.insert({
    required String id,
    required String productId,
    required String slot,
    required String weekdaysJson,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       slot = Value(slot),
       weekdaysJson = Value(weekdaysJson),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<ScheduleRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? slot,
    Expression<String>? weekdaysJson,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (slot != null) 'slot': slot,
      if (weekdaysJson != null) 'weekdays_json': weekdaysJson,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WeekdaySchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? slot,
    Value<String>? weekdaysJson,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return WeekdaySchedulesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      slot: slot ?? this.slot,
      weekdaysJson: weekdaysJson ?? this.weekdaysJson,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (weekdaysJson.present) {
      map['weekdays_json'] = Variable<String>(weekdaysJson.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WeekdaySchedulesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('slot: $slot, ')
          ..write('weekdaysJson: $weekdaysJson, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OrderOverridesTable extends OrderOverrides
    with TableInfo<$OrderOverridesTable, OrderOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weekdayMeta = const VerificationMeta(
    'weekday',
  );
  @override
  late final GeneratedColumn<int> weekday = GeneratedColumn<int>(
    'weekday',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _orderedProductIdsJsonMeta =
      const VerificationMeta('orderedProductIdsJson');
  @override
  late final GeneratedColumn<String> orderedProductIdsJson =
      GeneratedColumn<String>(
        'ordered_product_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    slot,
    weekday,
    orderedProductIdsJson,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'order_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('weekday')) {
      context.handle(
        _weekdayMeta,
        weekday.isAcceptableOrUnknown(data['weekday']!, _weekdayMeta),
      );
    }
    if (data.containsKey('ordered_product_ids_json')) {
      context.handle(
        _orderedProductIdsJsonMeta,
        orderedProductIdsJson.isAcceptableOrUnknown(
          data['ordered_product_ids_json']!,
          _orderedProductIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_orderedProductIdsJsonMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderOverrideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      weekday: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weekday'],
      ),
      orderedProductIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ordered_product_ids_json'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $OrderOverridesTable createAlias(String alias) {
    return $OrderOverridesTable(attachedDatabase, alias);
  }
}

class OrderOverrideRow extends DataClass
    implements Insertable<OrderOverrideRow> {
  final String id;
  final String slot;
  final int? weekday;
  final String orderedProductIdsJson;
  final int lastModifiedMs;
  const OrderOverrideRow({
    required this.id,
    required this.slot,
    this.weekday,
    required this.orderedProductIdsJson,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['slot'] = Variable<String>(slot);
    if (!nullToAbsent || weekday != null) {
      map['weekday'] = Variable<int>(weekday);
    }
    map['ordered_product_ids_json'] = Variable<String>(orderedProductIdsJson);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  OrderOverridesCompanion toCompanion(bool nullToAbsent) {
    return OrderOverridesCompanion(
      id: Value(id),
      slot: Value(slot),
      weekday: weekday == null && nullToAbsent
          ? const Value.absent()
          : Value(weekday),
      orderedProductIdsJson: Value(orderedProductIdsJson),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory OrderOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderOverrideRow(
      id: serializer.fromJson<String>(json['id']),
      slot: serializer.fromJson<String>(json['slot']),
      weekday: serializer.fromJson<int?>(json['weekday']),
      orderedProductIdsJson: serializer.fromJson<String>(
        json['orderedProductIdsJson'],
      ),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'slot': serializer.toJson<String>(slot),
      'weekday': serializer.toJson<int?>(weekday),
      'orderedProductIdsJson': serializer.toJson<String>(orderedProductIdsJson),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  OrderOverrideRow copyWith({
    String? id,
    String? slot,
    Value<int?> weekday = const Value.absent(),
    String? orderedProductIdsJson,
    int? lastModifiedMs,
  }) => OrderOverrideRow(
    id: id ?? this.id,
    slot: slot ?? this.slot,
    weekday: weekday.present ? weekday.value : this.weekday,
    orderedProductIdsJson: orderedProductIdsJson ?? this.orderedProductIdsJson,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  OrderOverrideRow copyWithCompanion(OrderOverridesCompanion data) {
    return OrderOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      slot: data.slot.present ? data.slot.value : this.slot,
      weekday: data.weekday.present ? data.weekday.value : this.weekday,
      orderedProductIdsJson: data.orderedProductIdsJson.present
          ? data.orderedProductIdsJson.value
          : this.orderedProductIdsJson,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderOverrideRow(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('weekday: $weekday, ')
          ..write('orderedProductIdsJson: $orderedProductIdsJson, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, slot, weekday, orderedProductIdsJson, lastModifiedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderOverrideRow &&
          other.id == this.id &&
          other.slot == this.slot &&
          other.weekday == this.weekday &&
          other.orderedProductIdsJson == this.orderedProductIdsJson &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class OrderOverridesCompanion extends UpdateCompanion<OrderOverrideRow> {
  final Value<String> id;
  final Value<String> slot;
  final Value<int?> weekday;
  final Value<String> orderedProductIdsJson;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const OrderOverridesCompanion({
    this.id = const Value.absent(),
    this.slot = const Value.absent(),
    this.weekday = const Value.absent(),
    this.orderedProductIdsJson = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderOverridesCompanion.insert({
    required String id,
    required String slot,
    this.weekday = const Value.absent(),
    required String orderedProductIdsJson,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       slot = Value(slot),
       orderedProductIdsJson = Value(orderedProductIdsJson),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<OrderOverrideRow> custom({
    Expression<String>? id,
    Expression<String>? slot,
    Expression<int>? weekday,
    Expression<String>? orderedProductIdsJson,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slot != null) 'slot': slot,
      if (weekday != null) 'weekday': weekday,
      if (orderedProductIdsJson != null)
        'ordered_product_ids_json': orderedProductIdsJson,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderOverridesCompanion copyWith({
    Value<String>? id,
    Value<String>? slot,
    Value<int?>? weekday,
    Value<String>? orderedProductIdsJson,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return OrderOverridesCompanion(
      id: id ?? this.id,
      slot: slot ?? this.slot,
      weekday: weekday ?? this.weekday,
      orderedProductIdsJson:
          orderedProductIdsJson ?? this.orderedProductIdsJson,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (weekday.present) {
      map['weekday'] = Variable<int>(weekday.value);
    }
    if (orderedProductIdsJson.present) {
      map['ordered_product_ids_json'] = Variable<String>(
        orderedProductIdsJson.value,
      );
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderOverridesCompanion(')
          ..write('id: $id, ')
          ..write('slot: $slot, ')
          ..write('weekday: $weekday, ')
          ..write('orderedProductIdsJson: $orderedProductIdsJson, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DayRecordsTable extends DayRecords
    with TableInfo<$DayRecordsTable, DayRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotMeta = const VerificationMeta('slot');
  @override
  late final GeneratedColumn<String> slot = GeneratedColumn<String>(
    'slot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedProductIdsJsonMeta =
      const VerificationMeta('resolvedProductIdsJson');
  @override
  late final GeneratedColumn<String> resolvedProductIdsJson =
      GeneratedColumn<String>(
        'resolved_product_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recordedProductIdsJsonMeta =
      const VerificationMeta('recordedProductIdsJson');
  @override
  late final GeneratedColumn<String> recordedProductIdsJson =
      GeneratedColumn<String>(
        'recorded_product_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _resolvedAtMasterVersionMeta =
      const VerificationMeta('resolvedAtMasterVersion');
  @override
  late final GeneratedColumn<String> resolvedAtMasterVersion =
      GeneratedColumn<String>(
        'resolved_at_master_version',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    slot,
    resolvedProductIdsJson,
    recordedProductIdsJson,
    resolvedAtMasterVersion,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('slot')) {
      context.handle(
        _slotMeta,
        slot.isAcceptableOrUnknown(data['slot']!, _slotMeta),
      );
    } else if (isInserting) {
      context.missing(_slotMeta);
    }
    if (data.containsKey('resolved_product_ids_json')) {
      context.handle(
        _resolvedProductIdsJsonMeta,
        resolvedProductIdsJson.isAcceptableOrUnknown(
          data['resolved_product_ids_json']!,
          _resolvedProductIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvedProductIdsJsonMeta);
    }
    if (data.containsKey('recorded_product_ids_json')) {
      context.handle(
        _recordedProductIdsJsonMeta,
        recordedProductIdsJson.isAcceptableOrUnknown(
          data['recorded_product_ids_json']!,
          _recordedProductIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordedProductIdsJsonMeta);
    }
    if (data.containsKey('resolved_at_master_version')) {
      context.handle(
        _resolvedAtMasterVersionMeta,
        resolvedAtMasterVersion.isAcceptableOrUnknown(
          data['resolved_at_master_version']!,
          _resolvedAtMasterVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_resolvedAtMasterVersionMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      slot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot'],
      )!,
      resolvedProductIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_product_ids_json'],
      )!,
      recordedProductIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recorded_product_ids_json'],
      )!,
      resolvedAtMasterVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolved_at_master_version'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $DayRecordsTable createAlias(String alias) {
    return $DayRecordsTable(attachedDatabase, alias);
  }
}

class DayRecordRow extends DataClass implements Insertable<DayRecordRow> {
  final String id;
  final String date;
  final String slot;
  final String resolvedProductIdsJson;
  final String recordedProductIdsJson;
  final String resolvedAtMasterVersion;
  final int lastModifiedMs;
  const DayRecordRow({
    required this.id,
    required this.date,
    required this.slot,
    required this.resolvedProductIdsJson,
    required this.recordedProductIdsJson,
    required this.resolvedAtMasterVersion,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    map['slot'] = Variable<String>(slot);
    map['resolved_product_ids_json'] = Variable<String>(resolvedProductIdsJson);
    map['recorded_product_ids_json'] = Variable<String>(recordedProductIdsJson);
    map['resolved_at_master_version'] = Variable<String>(
      resolvedAtMasterVersion,
    );
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  DayRecordsCompanion toCompanion(bool nullToAbsent) {
    return DayRecordsCompanion(
      id: Value(id),
      date: Value(date),
      slot: Value(slot),
      resolvedProductIdsJson: Value(resolvedProductIdsJson),
      recordedProductIdsJson: Value(recordedProductIdsJson),
      resolvedAtMasterVersion: Value(resolvedAtMasterVersion),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory DayRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayRecordRow(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      slot: serializer.fromJson<String>(json['slot']),
      resolvedProductIdsJson: serializer.fromJson<String>(
        json['resolvedProductIdsJson'],
      ),
      recordedProductIdsJson: serializer.fromJson<String>(
        json['recordedProductIdsJson'],
      ),
      resolvedAtMasterVersion: serializer.fromJson<String>(
        json['resolvedAtMasterVersion'],
      ),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'slot': serializer.toJson<String>(slot),
      'resolvedProductIdsJson': serializer.toJson<String>(
        resolvedProductIdsJson,
      ),
      'recordedProductIdsJson': serializer.toJson<String>(
        recordedProductIdsJson,
      ),
      'resolvedAtMasterVersion': serializer.toJson<String>(
        resolvedAtMasterVersion,
      ),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  DayRecordRow copyWith({
    String? id,
    String? date,
    String? slot,
    String? resolvedProductIdsJson,
    String? recordedProductIdsJson,
    String? resolvedAtMasterVersion,
    int? lastModifiedMs,
  }) => DayRecordRow(
    id: id ?? this.id,
    date: date ?? this.date,
    slot: slot ?? this.slot,
    resolvedProductIdsJson:
        resolvedProductIdsJson ?? this.resolvedProductIdsJson,
    recordedProductIdsJson:
        recordedProductIdsJson ?? this.recordedProductIdsJson,
    resolvedAtMasterVersion:
        resolvedAtMasterVersion ?? this.resolvedAtMasterVersion,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  DayRecordRow copyWithCompanion(DayRecordsCompanion data) {
    return DayRecordRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      slot: data.slot.present ? data.slot.value : this.slot,
      resolvedProductIdsJson: data.resolvedProductIdsJson.present
          ? data.resolvedProductIdsJson.value
          : this.resolvedProductIdsJson,
      recordedProductIdsJson: data.recordedProductIdsJson.present
          ? data.recordedProductIdsJson.value
          : this.recordedProductIdsJson,
      resolvedAtMasterVersion: data.resolvedAtMasterVersion.present
          ? data.resolvedAtMasterVersion.value
          : this.resolvedAtMasterVersion,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayRecordRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('resolvedProductIdsJson: $resolvedProductIdsJson, ')
          ..write('recordedProductIdsJson: $recordedProductIdsJson, ')
          ..write('resolvedAtMasterVersion: $resolvedAtMasterVersion, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    date,
    slot,
    resolvedProductIdsJson,
    recordedProductIdsJson,
    resolvedAtMasterVersion,
    lastModifiedMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayRecordRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.slot == this.slot &&
          other.resolvedProductIdsJson == this.resolvedProductIdsJson &&
          other.recordedProductIdsJson == this.recordedProductIdsJson &&
          other.resolvedAtMasterVersion == this.resolvedAtMasterVersion &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class DayRecordsCompanion extends UpdateCompanion<DayRecordRow> {
  final Value<String> id;
  final Value<String> date;
  final Value<String> slot;
  final Value<String> resolvedProductIdsJson;
  final Value<String> recordedProductIdsJson;
  final Value<String> resolvedAtMasterVersion;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const DayRecordsCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.slot = const Value.absent(),
    this.resolvedProductIdsJson = const Value.absent(),
    this.recordedProductIdsJson = const Value.absent(),
    this.resolvedAtMasterVersion = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayRecordsCompanion.insert({
    required String id,
    required String date,
    required String slot,
    required String resolvedProductIdsJson,
    required String recordedProductIdsJson,
    required String resolvedAtMasterVersion,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       slot = Value(slot),
       resolvedProductIdsJson = Value(resolvedProductIdsJson),
       recordedProductIdsJson = Value(recordedProductIdsJson),
       resolvedAtMasterVersion = Value(resolvedAtMasterVersion),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<DayRecordRow> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? slot,
    Expression<String>? resolvedProductIdsJson,
    Expression<String>? recordedProductIdsJson,
    Expression<String>? resolvedAtMasterVersion,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (slot != null) 'slot': slot,
      if (resolvedProductIdsJson != null)
        'resolved_product_ids_json': resolvedProductIdsJson,
      if (recordedProductIdsJson != null)
        'recorded_product_ids_json': recordedProductIdsJson,
      if (resolvedAtMasterVersion != null)
        'resolved_at_master_version': resolvedAtMasterVersion,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String>? slot,
    Value<String>? resolvedProductIdsJson,
    Value<String>? recordedProductIdsJson,
    Value<String>? resolvedAtMasterVersion,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return DayRecordsCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      slot: slot ?? this.slot,
      resolvedProductIdsJson:
          resolvedProductIdsJson ?? this.resolvedProductIdsJson,
      recordedProductIdsJson:
          recordedProductIdsJson ?? this.recordedProductIdsJson,
      resolvedAtMasterVersion:
          resolvedAtMasterVersion ?? this.resolvedAtMasterVersion,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (slot.present) {
      map['slot'] = Variable<String>(slot.value);
    }
    if (resolvedProductIdsJson.present) {
      map['resolved_product_ids_json'] = Variable<String>(
        resolvedProductIdsJson.value,
      );
    }
    if (recordedProductIdsJson.present) {
      map['recorded_product_ids_json'] = Variable<String>(
        recordedProductIdsJson.value,
      );
    }
    if (resolvedAtMasterVersion.present) {
      map['resolved_at_master_version'] = Variable<String>(
        resolvedAtMasterVersion.value,
      );
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayRecordsCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('slot: $slot, ')
          ..write('resolvedProductIdsJson: $resolvedProductIdsJson, ')
          ..write('recordedProductIdsJson: $recordedProductIdsJson, ')
          ..write('resolvedAtMasterVersion: $resolvedAtMasterVersion, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SkinLogEntriesTable extends SkinLogEntries
    with TableInfo<$SkinLogEntriesTable, SkinLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SkinLogEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skinStateMeta = const VerificationMeta(
    'skinState',
  );
  @override
  late final GeneratedColumn<String> skinState = GeneratedColumn<String>(
    'skin_state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _photoPathsJsonMeta = const VerificationMeta(
    'photoPathsJson',
  );
  @override
  late final GeneratedColumn<String> photoPathsJson = GeneratedColumn<String>(
    'photo_paths_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    date,
    notes,
    skinState,
    photoPathsJson,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'skin_log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SkinLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('skin_state')) {
      context.handle(
        _skinStateMeta,
        skinState.isAcceptableOrUnknown(data['skin_state']!, _skinStateMeta),
      );
    }
    if (data.containsKey('photo_paths_json')) {
      context.handle(
        _photoPathsJsonMeta,
        photoPathsJson.isAcceptableOrUnknown(
          data['photo_paths_json']!,
          _photoPathsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoPathsJsonMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SkinLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SkinLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      skinState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skin_state'],
      ),
      photoPathsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_paths_json'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $SkinLogEntriesTable createAlias(String alias) {
    return $SkinLogEntriesTable(attachedDatabase, alias);
  }
}

class SkinLogRow extends DataClass implements Insertable<SkinLogRow> {
  final String id;
  final String date;
  final String? notes;
  final String? skinState;
  final String photoPathsJson;
  final int lastModifiedMs;
  const SkinLogRow({
    required this.id,
    required this.date,
    this.notes,
    this.skinState,
    required this.photoPathsJson,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || skinState != null) {
      map['skin_state'] = Variable<String>(skinState);
    }
    map['photo_paths_json'] = Variable<String>(photoPathsJson);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  SkinLogEntriesCompanion toCompanion(bool nullToAbsent) {
    return SkinLogEntriesCompanion(
      id: Value(id),
      date: Value(date),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      skinState: skinState == null && nullToAbsent
          ? const Value.absent()
          : Value(skinState),
      photoPathsJson: Value(photoPathsJson),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory SkinLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SkinLogRow(
      id: serializer.fromJson<String>(json['id']),
      date: serializer.fromJson<String>(json['date']),
      notes: serializer.fromJson<String?>(json['notes']),
      skinState: serializer.fromJson<String?>(json['skinState']),
      photoPathsJson: serializer.fromJson<String>(json['photoPathsJson']),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'date': serializer.toJson<String>(date),
      'notes': serializer.toJson<String?>(notes),
      'skinState': serializer.toJson<String?>(skinState),
      'photoPathsJson': serializer.toJson<String>(photoPathsJson),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  SkinLogRow copyWith({
    String? id,
    String? date,
    Value<String?> notes = const Value.absent(),
    Value<String?> skinState = const Value.absent(),
    String? photoPathsJson,
    int? lastModifiedMs,
  }) => SkinLogRow(
    id: id ?? this.id,
    date: date ?? this.date,
    notes: notes.present ? notes.value : this.notes,
    skinState: skinState.present ? skinState.value : this.skinState,
    photoPathsJson: photoPathsJson ?? this.photoPathsJson,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  SkinLogRow copyWithCompanion(SkinLogEntriesCompanion data) {
    return SkinLogRow(
      id: data.id.present ? data.id.value : this.id,
      date: data.date.present ? data.date.value : this.date,
      notes: data.notes.present ? data.notes.value : this.notes,
      skinState: data.skinState.present ? data.skinState.value : this.skinState,
      photoPathsJson: data.photoPathsJson.present
          ? data.photoPathsJson.value
          : this.photoPathsJson,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SkinLogRow(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('skinState: $skinState, ')
          ..write('photoPathsJson: $photoPathsJson, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, date, notes, skinState, photoPathsJson, lastModifiedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SkinLogRow &&
          other.id == this.id &&
          other.date == this.date &&
          other.notes == this.notes &&
          other.skinState == this.skinState &&
          other.photoPathsJson == this.photoPathsJson &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class SkinLogEntriesCompanion extends UpdateCompanion<SkinLogRow> {
  final Value<String> id;
  final Value<String> date;
  final Value<String?> notes;
  final Value<String?> skinState;
  final Value<String> photoPathsJson;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const SkinLogEntriesCompanion({
    this.id = const Value.absent(),
    this.date = const Value.absent(),
    this.notes = const Value.absent(),
    this.skinState = const Value.absent(),
    this.photoPathsJson = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SkinLogEntriesCompanion.insert({
    required String id,
    required String date,
    this.notes = const Value.absent(),
    this.skinState = const Value.absent(),
    required String photoPathsJson,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       date = Value(date),
       photoPathsJson = Value(photoPathsJson),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<SkinLogRow> custom({
    Expression<String>? id,
    Expression<String>? date,
    Expression<String>? notes,
    Expression<String>? skinState,
    Expression<String>? photoPathsJson,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (date != null) 'date': date,
      if (notes != null) 'notes': notes,
      if (skinState != null) 'skin_state': skinState,
      if (photoPathsJson != null) 'photo_paths_json': photoPathsJson,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SkinLogEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? date,
    Value<String?>? notes,
    Value<String?>? skinState,
    Value<String>? photoPathsJson,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return SkinLogEntriesCompanion(
      id: id ?? this.id,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      skinState: skinState ?? this.skinState,
      photoPathsJson: photoPathsJson ?? this.photoPathsJson,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (skinState.present) {
      map['skin_state'] = Variable<String>(skinState.value);
    }
    if (photoPathsJson.present) {
      map['photo_paths_json'] = Variable<String>(photoPathsJson.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SkinLogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('date: $date, ')
          ..write('notes: $notes, ')
          ..write('skinState: $skinState, ')
          ..write('photoPathsJson: $photoPathsJson, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MutedConflictsTable extends MutedConflicts
    with TableInfo<$MutedConflictsTable, MutedConflictRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MutedConflictsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ruleIdMeta = const VerificationMeta('ruleId');
  @override
  late final GeneratedColumn<String> ruleId = GeneratedColumn<String>(
    'rule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutedAtMsMeta = const VerificationMeta(
    'mutedAtMs',
  );
  @override
  late final GeneratedColumn<int> mutedAtMs = GeneratedColumn<int>(
    'muted_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, ruleId, mutedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'muted_conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<MutedConflictRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rule_id')) {
      context.handle(
        _ruleIdMeta,
        ruleId.isAcceptableOrUnknown(data['rule_id']!, _ruleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ruleIdMeta);
    }
    if (data.containsKey('muted_at_ms')) {
      context.handle(
        _mutedAtMsMeta,
        mutedAtMs.isAcceptableOrUnknown(data['muted_at_ms']!, _mutedAtMsMeta),
      );
    } else if (isInserting) {
      context.missing(_mutedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MutedConflictRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MutedConflictRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ruleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rule_id'],
      )!,
      mutedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}muted_at_ms'],
      )!,
    );
  }

  @override
  $MutedConflictsTable createAlias(String alias) {
    return $MutedConflictsTable(attachedDatabase, alias);
  }
}

class MutedConflictRow extends DataClass
    implements Insertable<MutedConflictRow> {
  final String id;
  final String ruleId;
  final int mutedAtMs;
  const MutedConflictRow({
    required this.id,
    required this.ruleId,
    required this.mutedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rule_id'] = Variable<String>(ruleId);
    map['muted_at_ms'] = Variable<int>(mutedAtMs);
    return map;
  }

  MutedConflictsCompanion toCompanion(bool nullToAbsent) {
    return MutedConflictsCompanion(
      id: Value(id),
      ruleId: Value(ruleId),
      mutedAtMs: Value(mutedAtMs),
    );
  }

  factory MutedConflictRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MutedConflictRow(
      id: serializer.fromJson<String>(json['id']),
      ruleId: serializer.fromJson<String>(json['ruleId']),
      mutedAtMs: serializer.fromJson<int>(json['mutedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ruleId': serializer.toJson<String>(ruleId),
      'mutedAtMs': serializer.toJson<int>(mutedAtMs),
    };
  }

  MutedConflictRow copyWith({String? id, String? ruleId, int? mutedAtMs}) =>
      MutedConflictRow(
        id: id ?? this.id,
        ruleId: ruleId ?? this.ruleId,
        mutedAtMs: mutedAtMs ?? this.mutedAtMs,
      );
  MutedConflictRow copyWithCompanion(MutedConflictsCompanion data) {
    return MutedConflictRow(
      id: data.id.present ? data.id.value : this.id,
      ruleId: data.ruleId.present ? data.ruleId.value : this.ruleId,
      mutedAtMs: data.mutedAtMs.present ? data.mutedAtMs.value : this.mutedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MutedConflictRow(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('mutedAtMs: $mutedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, ruleId, mutedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MutedConflictRow &&
          other.id == this.id &&
          other.ruleId == this.ruleId &&
          other.mutedAtMs == this.mutedAtMs);
}

class MutedConflictsCompanion extends UpdateCompanion<MutedConflictRow> {
  final Value<String> id;
  final Value<String> ruleId;
  final Value<int> mutedAtMs;
  final Value<int> rowid;
  const MutedConflictsCompanion({
    this.id = const Value.absent(),
    this.ruleId = const Value.absent(),
    this.mutedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MutedConflictsCompanion.insert({
    required String id,
    required String ruleId,
    required int mutedAtMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ruleId = Value(ruleId),
       mutedAtMs = Value(mutedAtMs);
  static Insertable<MutedConflictRow> custom({
    Expression<String>? id,
    Expression<String>? ruleId,
    Expression<int>? mutedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ruleId != null) 'rule_id': ruleId,
      if (mutedAtMs != null) 'muted_at_ms': mutedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MutedConflictsCompanion copyWith({
    Value<String>? id,
    Value<String>? ruleId,
    Value<int>? mutedAtMs,
    Value<int>? rowid,
  }) {
    return MutedConflictsCompanion(
      id: id ?? this.id,
      ruleId: ruleId ?? this.ruleId,
      mutedAtMs: mutedAtMs ?? this.mutedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ruleId.present) {
      map['rule_id'] = Variable<String>(ruleId.value);
    }
    if (mutedAtMs.present) {
      map['muted_at_ms'] = Variable<int>(mutedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MutedConflictsCompanion(')
          ..write('id: $id, ')
          ..write('ruleId: $ruleId, ')
          ..write('mutedAtMs: $mutedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserCustomProductsTable extends UserCustomProducts
    with TableInfo<$UserCustomProductsTable, CustomProductRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserCustomProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoKeyMeta = const VerificationMeta(
    'photoKey',
  );
  @override
  late final GeneratedColumn<String> photoKey = GeneratedColumn<String>(
    'photo_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryIdMeta = const VerificationMeta(
    'subCategoryId',
  );
  @override
  late final GeneratedColumn<String> subCategoryId = GeneratedColumn<String>(
    'sub_category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _inMorningMeta = const VerificationMeta(
    'inMorning',
  );
  @override
  late final GeneratedColumn<bool> inMorning = GeneratedColumn<bool>(
    'in_morning',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_morning" IN (0, 1))',
    ),
  );
  static const VerificationMeta _inEveningMeta = const VerificationMeta(
    'inEvening',
  );
  @override
  late final GeneratedColumn<bool> inEvening = GeneratedColumn<bool>(
    'in_evening',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("in_evening" IN (0, 1))',
    ),
  );
  static const VerificationMeta _isDailyMeta = const VerificationMeta(
    'isDaily',
  );
  @override
  late final GeneratedColumn<bool> isDaily = GeneratedColumn<bool>(
    'is_daily',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_daily" IN (0, 1))',
    ),
  );
  static const VerificationMeta _maxTimesPerWeekMeta = const VerificationMeta(
    'maxTimesPerWeek',
  );
  @override
  late final GeneratedColumn<int> maxTimesPerWeek = GeneratedColumn<int>(
    'times_per_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _commentJsonMeta = const VerificationMeta(
    'commentJson',
  );
  @override
  late final GeneratedColumn<String> commentJson = GeneratedColumn<String>(
    'comment_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ingredientsMeta = const VerificationMeta(
    'ingredients',
  );
  @override
  late final GeneratedColumn<String> ingredients = GeneratedColumn<String>(
    'ingredients',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeprecatedMeta = const VerificationMeta(
    'isDeprecated',
  );
  @override
  late final GeneratedColumn<bool> isDeprecated = GeneratedColumn<bool>(
    'is_deprecated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deprecated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    photoKey,
    categoryId,
    subCategoryId,
    inMorning,
    inEvening,
    isDaily,
    maxTimesPerWeek,
    lastModifiedMs,
    commentJson,
    brand,
    ingredients,
    isDeprecated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_custom_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomProductRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('photo_key')) {
      context.handle(
        _photoKeyMeta,
        photoKey.isAcceptableOrUnknown(data['photo_key']!, _photoKeyMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('sub_category_id')) {
      context.handle(
        _subCategoryIdMeta,
        subCategoryId.isAcceptableOrUnknown(
          data['sub_category_id']!,
          _subCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('in_morning')) {
      context.handle(
        _inMorningMeta,
        inMorning.isAcceptableOrUnknown(data['in_morning']!, _inMorningMeta),
      );
    } else if (isInserting) {
      context.missing(_inMorningMeta);
    }
    if (data.containsKey('in_evening')) {
      context.handle(
        _inEveningMeta,
        inEvening.isAcceptableOrUnknown(data['in_evening']!, _inEveningMeta),
      );
    } else if (isInserting) {
      context.missing(_inEveningMeta);
    }
    if (data.containsKey('is_daily')) {
      context.handle(
        _isDailyMeta,
        isDaily.isAcceptableOrUnknown(data['is_daily']!, _isDailyMeta),
      );
    } else if (isInserting) {
      context.missing(_isDailyMeta);
    }
    if (data.containsKey('times_per_week')) {
      context.handle(
        _maxTimesPerWeekMeta,
        maxTimesPerWeek.isAcceptableOrUnknown(
          data['times_per_week']!,
          _maxTimesPerWeekMeta,
        ),
      );
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    if (data.containsKey('comment_json')) {
      context.handle(
        _commentJsonMeta,
        commentJson.isAcceptableOrUnknown(
          data['comment_json']!,
          _commentJsonMeta,
        ),
      );
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('ingredients')) {
      context.handle(
        _ingredientsMeta,
        ingredients.isAcceptableOrUnknown(
          data['ingredients']!,
          _ingredientsMeta,
        ),
      );
    }
    if (data.containsKey('is_deprecated')) {
      context.handle(
        _isDeprecatedMeta,
        isDeprecated.isAcceptableOrUnknown(
          data['is_deprecated']!,
          _isDeprecatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomProductRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomProductRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      photoKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_key'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      subCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category_id'],
      ),
      inMorning: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_morning'],
      )!,
      inEvening: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}in_evening'],
      )!,
      isDaily: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_daily'],
      )!,
      maxTimesPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}times_per_week'],
      ),
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
      commentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comment_json'],
      ),
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      ingredients: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ingredients'],
      ),
      isDeprecated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deprecated'],
      )!,
    );
  }

  @override
  $UserCustomProductsTable createAlias(String alias) {
    return $UserCustomProductsTable(attachedDatabase, alias);
  }
}

class CustomProductRow extends DataClass
    implements Insertable<CustomProductRow> {
  final String id;
  final String name;
  final String? photoKey;
  final String categoryId;
  final String? subCategoryId;
  final bool inMorning;
  final bool inEvening;
  final bool isDaily;
  final int? maxTimesPerWeek;
  final int lastModifiedMs;
  final String? commentJson;
  final String? brand;
  final String? ingredients;
  final bool isDeprecated;
  const CustomProductRow({
    required this.id,
    required this.name,
    this.photoKey,
    required this.categoryId,
    this.subCategoryId,
    required this.inMorning,
    required this.inEvening,
    required this.isDaily,
    this.maxTimesPerWeek,
    required this.lastModifiedMs,
    this.commentJson,
    this.brand,
    this.ingredients,
    required this.isDeprecated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || photoKey != null) {
      map['photo_key'] = Variable<String>(photoKey);
    }
    map['category_id'] = Variable<String>(categoryId);
    if (!nullToAbsent || subCategoryId != null) {
      map['sub_category_id'] = Variable<String>(subCategoryId);
    }
    map['in_morning'] = Variable<bool>(inMorning);
    map['in_evening'] = Variable<bool>(inEvening);
    map['is_daily'] = Variable<bool>(isDaily);
    if (!nullToAbsent || maxTimesPerWeek != null) {
      map['times_per_week'] = Variable<int>(maxTimesPerWeek);
    }
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    if (!nullToAbsent || commentJson != null) {
      map['comment_json'] = Variable<String>(commentJson);
    }
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || ingredients != null) {
      map['ingredients'] = Variable<String>(ingredients);
    }
    map['is_deprecated'] = Variable<bool>(isDeprecated);
    return map;
  }

  UserCustomProductsCompanion toCompanion(bool nullToAbsent) {
    return UserCustomProductsCompanion(
      id: Value(id),
      name: Value(name),
      photoKey: photoKey == null && nullToAbsent
          ? const Value.absent()
          : Value(photoKey),
      categoryId: Value(categoryId),
      subCategoryId: subCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(subCategoryId),
      inMorning: Value(inMorning),
      inEvening: Value(inEvening),
      isDaily: Value(isDaily),
      maxTimesPerWeek: maxTimesPerWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(maxTimesPerWeek),
      lastModifiedMs: Value(lastModifiedMs),
      commentJson: commentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(commentJson),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      ingredients: ingredients == null && nullToAbsent
          ? const Value.absent()
          : Value(ingredients),
      isDeprecated: Value(isDeprecated),
    );
  }

  factory CustomProductRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomProductRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      photoKey: serializer.fromJson<String?>(json['photoKey']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      subCategoryId: serializer.fromJson<String?>(json['subCategoryId']),
      inMorning: serializer.fromJson<bool>(json['inMorning']),
      inEvening: serializer.fromJson<bool>(json['inEvening']),
      isDaily: serializer.fromJson<bool>(json['isDaily']),
      maxTimesPerWeek: serializer.fromJson<int?>(json['maxTimesPerWeek']),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
      commentJson: serializer.fromJson<String?>(json['commentJson']),
      brand: serializer.fromJson<String?>(json['brand']),
      ingredients: serializer.fromJson<String?>(json['ingredients']),
      isDeprecated: serializer.fromJson<bool>(json['isDeprecated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'photoKey': serializer.toJson<String?>(photoKey),
      'categoryId': serializer.toJson<String>(categoryId),
      'subCategoryId': serializer.toJson<String?>(subCategoryId),
      'inMorning': serializer.toJson<bool>(inMorning),
      'inEvening': serializer.toJson<bool>(inEvening),
      'isDaily': serializer.toJson<bool>(isDaily),
      'maxTimesPerWeek': serializer.toJson<int?>(maxTimesPerWeek),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
      'commentJson': serializer.toJson<String?>(commentJson),
      'brand': serializer.toJson<String?>(brand),
      'ingredients': serializer.toJson<String?>(ingredients),
      'isDeprecated': serializer.toJson<bool>(isDeprecated),
    };
  }

  CustomProductRow copyWith({
    String? id,
    String? name,
    Value<String?> photoKey = const Value.absent(),
    String? categoryId,
    Value<String?> subCategoryId = const Value.absent(),
    bool? inMorning,
    bool? inEvening,
    bool? isDaily,
    Value<int?> maxTimesPerWeek = const Value.absent(),
    int? lastModifiedMs,
    Value<String?> commentJson = const Value.absent(),
    Value<String?> brand = const Value.absent(),
    Value<String?> ingredients = const Value.absent(),
    bool? isDeprecated,
  }) => CustomProductRow(
    id: id ?? this.id,
    name: name ?? this.name,
    photoKey: photoKey.present ? photoKey.value : this.photoKey,
    categoryId: categoryId ?? this.categoryId,
    subCategoryId: subCategoryId.present
        ? subCategoryId.value
        : this.subCategoryId,
    inMorning: inMorning ?? this.inMorning,
    inEvening: inEvening ?? this.inEvening,
    isDaily: isDaily ?? this.isDaily,
    maxTimesPerWeek: maxTimesPerWeek.present
        ? maxTimesPerWeek.value
        : this.maxTimesPerWeek,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
    commentJson: commentJson.present ? commentJson.value : this.commentJson,
    brand: brand.present ? brand.value : this.brand,
    ingredients: ingredients.present ? ingredients.value : this.ingredients,
    isDeprecated: isDeprecated ?? this.isDeprecated,
  );
  CustomProductRow copyWithCompanion(UserCustomProductsCompanion data) {
    return CustomProductRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      photoKey: data.photoKey.present ? data.photoKey.value : this.photoKey,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      subCategoryId: data.subCategoryId.present
          ? data.subCategoryId.value
          : this.subCategoryId,
      inMorning: data.inMorning.present ? data.inMorning.value : this.inMorning,
      inEvening: data.inEvening.present ? data.inEvening.value : this.inEvening,
      isDaily: data.isDaily.present ? data.isDaily.value : this.isDaily,
      maxTimesPerWeek: data.maxTimesPerWeek.present
          ? data.maxTimesPerWeek.value
          : this.maxTimesPerWeek,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
      commentJson: data.commentJson.present
          ? data.commentJson.value
          : this.commentJson,
      brand: data.brand.present ? data.brand.value : this.brand,
      ingredients: data.ingredients.present
          ? data.ingredients.value
          : this.ingredients,
      isDeprecated: data.isDeprecated.present
          ? data.isDeprecated.value
          : this.isDeprecated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomProductRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('photoKey: $photoKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('inMorning: $inMorning, ')
          ..write('inEvening: $inEvening, ')
          ..write('isDaily: $isDaily, ')
          ..write('maxTimesPerWeek: $maxTimesPerWeek, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('commentJson: $commentJson, ')
          ..write('brand: $brand, ')
          ..write('ingredients: $ingredients, ')
          ..write('isDeprecated: $isDeprecated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    photoKey,
    categoryId,
    subCategoryId,
    inMorning,
    inEvening,
    isDaily,
    maxTimesPerWeek,
    lastModifiedMs,
    commentJson,
    brand,
    ingredients,
    isDeprecated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomProductRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.photoKey == this.photoKey &&
          other.categoryId == this.categoryId &&
          other.subCategoryId == this.subCategoryId &&
          other.inMorning == this.inMorning &&
          other.inEvening == this.inEvening &&
          other.isDaily == this.isDaily &&
          other.maxTimesPerWeek == this.maxTimesPerWeek &&
          other.lastModifiedMs == this.lastModifiedMs &&
          other.commentJson == this.commentJson &&
          other.brand == this.brand &&
          other.ingredients == this.ingredients &&
          other.isDeprecated == this.isDeprecated);
}

class UserCustomProductsCompanion extends UpdateCompanion<CustomProductRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> photoKey;
  final Value<String> categoryId;
  final Value<String?> subCategoryId;
  final Value<bool> inMorning;
  final Value<bool> inEvening;
  final Value<bool> isDaily;
  final Value<int?> maxTimesPerWeek;
  final Value<int> lastModifiedMs;
  final Value<String?> commentJson;
  final Value<String?> brand;
  final Value<String?> ingredients;
  final Value<bool> isDeprecated;
  final Value<int> rowid;
  const UserCustomProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.photoKey = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.inMorning = const Value.absent(),
    this.inEvening = const Value.absent(),
    this.isDaily = const Value.absent(),
    this.maxTimesPerWeek = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.commentJson = const Value.absent(),
    this.brand = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.isDeprecated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserCustomProductsCompanion.insert({
    required String id,
    required String name,
    this.photoKey = const Value.absent(),
    required String categoryId,
    this.subCategoryId = const Value.absent(),
    required bool inMorning,
    required bool inEvening,
    required bool isDaily,
    this.maxTimesPerWeek = const Value.absent(),
    required int lastModifiedMs,
    this.commentJson = const Value.absent(),
    this.brand = const Value.absent(),
    this.ingredients = const Value.absent(),
    this.isDeprecated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       categoryId = Value(categoryId),
       inMorning = Value(inMorning),
       inEvening = Value(inEvening),
       isDaily = Value(isDaily),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<CustomProductRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? photoKey,
    Expression<String>? categoryId,
    Expression<String>? subCategoryId,
    Expression<bool>? inMorning,
    Expression<bool>? inEvening,
    Expression<bool>? isDaily,
    Expression<int>? maxTimesPerWeek,
    Expression<int>? lastModifiedMs,
    Expression<String>? commentJson,
    Expression<String>? brand,
    Expression<String>? ingredients,
    Expression<bool>? isDeprecated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (photoKey != null) 'photo_key': photoKey,
      if (categoryId != null) 'category_id': categoryId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (inMorning != null) 'in_morning': inMorning,
      if (inEvening != null) 'in_evening': inEvening,
      if (isDaily != null) 'is_daily': isDaily,
      if (maxTimesPerWeek != null) 'times_per_week': maxTimesPerWeek,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (commentJson != null) 'comment_json': commentJson,
      if (brand != null) 'brand': brand,
      if (ingredients != null) 'ingredients': ingredients,
      if (isDeprecated != null) 'is_deprecated': isDeprecated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserCustomProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? photoKey,
    Value<String>? categoryId,
    Value<String?>? subCategoryId,
    Value<bool>? inMorning,
    Value<bool>? inEvening,
    Value<bool>? isDaily,
    Value<int?>? maxTimesPerWeek,
    Value<int>? lastModifiedMs,
    Value<String?>? commentJson,
    Value<String?>? brand,
    Value<String?>? ingredients,
    Value<bool>? isDeprecated,
    Value<int>? rowid,
  }) {
    return UserCustomProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      photoKey: photoKey ?? this.photoKey,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      inMorning: inMorning ?? this.inMorning,
      inEvening: inEvening ?? this.inEvening,
      isDaily: isDaily ?? this.isDaily,
      maxTimesPerWeek: maxTimesPerWeek ?? this.maxTimesPerWeek,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      commentJson: commentJson ?? this.commentJson,
      brand: brand ?? this.brand,
      ingredients: ingredients ?? this.ingredients,
      isDeprecated: isDeprecated ?? this.isDeprecated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (photoKey.present) {
      map['photo_key'] = Variable<String>(photoKey.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (subCategoryId.present) {
      map['sub_category_id'] = Variable<String>(subCategoryId.value);
    }
    if (inMorning.present) {
      map['in_morning'] = Variable<bool>(inMorning.value);
    }
    if (inEvening.present) {
      map['in_evening'] = Variable<bool>(inEvening.value);
    }
    if (isDaily.present) {
      map['is_daily'] = Variable<bool>(isDaily.value);
    }
    if (maxTimesPerWeek.present) {
      map['times_per_week'] = Variable<int>(maxTimesPerWeek.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (commentJson.present) {
      map['comment_json'] = Variable<String>(commentJson.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (ingredients.present) {
      map['ingredients'] = Variable<String>(ingredients.value);
    }
    if (isDeprecated.present) {
      map['is_deprecated'] = Variable<bool>(isDeprecated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserCustomProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('photoKey: $photoKey, ')
          ..write('categoryId: $categoryId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('inMorning: $inMorning, ')
          ..write('inEvening: $inEvening, ')
          ..write('isDaily: $isDaily, ')
          ..write('maxTimesPerWeek: $maxTimesPerWeek, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('commentJson: $commentJson, ')
          ..write('brand: $brand, ')
          ..write('ingredients: $ingredients, ')
          ..write('isDeprecated: $isDeprecated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CollectionItemsTable extends CollectionItems
    with TableInfo<$CollectionItemsTable, CollectionItemRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CollectionItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _openedDateMsMeta = const VerificationMeta(
    'openedDateMs',
  );
  @override
  late final GeneratedColumn<int> openedDateMs = GeneratedColumn<int>(
    'opened_date_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paoMonthsMeta = const VerificationMeta(
    'paoMonths',
  );
  @override
  late final GeneratedColumn<int> paoMonths = GeneratedColumn<int>(
    'pao_months',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    status,
    openedDateMs,
    paoMonths,
    notificationsEnabled,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'collection_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CollectionItemRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('opened_date_ms')) {
      context.handle(
        _openedDateMsMeta,
        openedDateMs.isAcceptableOrUnknown(
          data['opened_date_ms']!,
          _openedDateMsMeta,
        ),
      );
    }
    if (data.containsKey('pao_months')) {
      context.handle(
        _paoMonthsMeta,
        paoMonths.isAcceptableOrUnknown(data['pao_months']!, _paoMonthsMeta),
      );
    } else if (isInserting) {
      context.missing(_paoMonthsMeta);
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CollectionItemRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CollectionItemRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      openedDateMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_date_ms'],
      ),
      paoMonths: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pao_months'],
      )!,
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $CollectionItemsTable createAlias(String alias) {
    return $CollectionItemsTable(attachedDatabase, alias);
  }
}

class CollectionItemRow extends DataClass
    implements Insertable<CollectionItemRow> {
  final String id;
  final String productId;
  final String status;
  final int? openedDateMs;
  final int paoMonths;
  final bool notificationsEnabled;
  final int lastModifiedMs;
  const CollectionItemRow({
    required this.id,
    required this.productId,
    required this.status,
    this.openedDateMs,
    required this.paoMonths,
    required this.notificationsEnabled,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || openedDateMs != null) {
      map['opened_date_ms'] = Variable<int>(openedDateMs);
    }
    map['pao_months'] = Variable<int>(paoMonths);
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  CollectionItemsCompanion toCompanion(bool nullToAbsent) {
    return CollectionItemsCompanion(
      id: Value(id),
      productId: Value(productId),
      status: Value(status),
      openedDateMs: openedDateMs == null && nullToAbsent
          ? const Value.absent()
          : Value(openedDateMs),
      paoMonths: Value(paoMonths),
      notificationsEnabled: Value(notificationsEnabled),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory CollectionItemRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CollectionItemRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      status: serializer.fromJson<String>(json['status']),
      openedDateMs: serializer.fromJson<int?>(json['openedDateMs']),
      paoMonths: serializer.fromJson<int>(json['paoMonths']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'status': serializer.toJson<String>(status),
      'openedDateMs': serializer.toJson<int?>(openedDateMs),
      'paoMonths': serializer.toJson<int>(paoMonths),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  CollectionItemRow copyWith({
    String? id,
    String? productId,
    String? status,
    Value<int?> openedDateMs = const Value.absent(),
    int? paoMonths,
    bool? notificationsEnabled,
    int? lastModifiedMs,
  }) => CollectionItemRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    status: status ?? this.status,
    openedDateMs: openedDateMs.present ? openedDateMs.value : this.openedDateMs,
    paoMonths: paoMonths ?? this.paoMonths,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  CollectionItemRow copyWithCompanion(CollectionItemsCompanion data) {
    return CollectionItemRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      status: data.status.present ? data.status.value : this.status,
      openedDateMs: data.openedDateMs.present
          ? data.openedDateMs.value
          : this.openedDateMs,
      paoMonths: data.paoMonths.present ? data.paoMonths.value : this.paoMonths,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('status: $status, ')
          ..write('openedDateMs: $openedDateMs, ')
          ..write('paoMonths: $paoMonths, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    productId,
    status,
    openedDateMs,
    paoMonths,
    notificationsEnabled,
    lastModifiedMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CollectionItemRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.status == this.status &&
          other.openedDateMs == this.openedDateMs &&
          other.paoMonths == this.paoMonths &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class CollectionItemsCompanion extends UpdateCompanion<CollectionItemRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> status;
  final Value<int?> openedDateMs;
  final Value<int> paoMonths;
  final Value<bool> notificationsEnabled;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const CollectionItemsCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.status = const Value.absent(),
    this.openedDateMs = const Value.absent(),
    this.paoMonths = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CollectionItemsCompanion.insert({
    required String id,
    required String productId,
    required String status,
    this.openedDateMs = const Value.absent(),
    required int paoMonths,
    this.notificationsEnabled = const Value.absent(),
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       status = Value(status),
       paoMonths = Value(paoMonths),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<CollectionItemRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? status,
    Expression<int>? openedDateMs,
    Expression<int>? paoMonths,
    Expression<bool>? notificationsEnabled,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (status != null) 'status': status,
      if (openedDateMs != null) 'opened_date_ms': openedDateMs,
      if (paoMonths != null) 'pao_months': paoMonths,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CollectionItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? status,
    Value<int?>? openedDateMs,
    Value<int>? paoMonths,
    Value<bool>? notificationsEnabled,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return CollectionItemsCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      status: status ?? this.status,
      openedDateMs: openedDateMs ?? this.openedDateMs,
      paoMonths: paoMonths ?? this.paoMonths,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (openedDateMs.present) {
      map['opened_date_ms'] = Variable<int>(openedDateMs.value);
    }
    if (paoMonths.present) {
      map['pao_months'] = Variable<int>(paoMonths.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CollectionItemsCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('status: $status, ')
          ..write('openedDateMs: $openedDateMs, ')
          ..write('paoMonths: $paoMonths, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoryOverridesTable extends CategoryOverrides
    with TableInfo<$CategoryOverridesTable, CategoryOverrideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoryOverridesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastModifiedMsMeta = const VerificationMeta(
    'lastModifiedMs',
  );
  @override
  late final GeneratedColumn<int> lastModifiedMs = GeneratedColumn<int>(
    'last_modified_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    categoryId,
    lastModifiedMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'category_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryOverrideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('last_modified_ms')) {
      context.handle(
        _lastModifiedMsMeta,
        lastModifiedMs.isAcceptableOrUnknown(
          data['last_modified_ms']!,
          _lastModifiedMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryOverrideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryOverrideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      lastModifiedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_modified_ms'],
      )!,
    );
  }

  @override
  $CategoryOverridesTable createAlias(String alias) {
    return $CategoryOverridesTable(attachedDatabase, alias);
  }
}

class CategoryOverrideRow extends DataClass
    implements Insertable<CategoryOverrideRow> {
  final String id;
  final String productId;
  final String categoryId;
  final int lastModifiedMs;
  const CategoryOverrideRow({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.lastModifiedMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['product_id'] = Variable<String>(productId);
    map['category_id'] = Variable<String>(categoryId);
    map['last_modified_ms'] = Variable<int>(lastModifiedMs);
    return map;
  }

  CategoryOverridesCompanion toCompanion(bool nullToAbsent) {
    return CategoryOverridesCompanion(
      id: Value(id),
      productId: Value(productId),
      categoryId: Value(categoryId),
      lastModifiedMs: Value(lastModifiedMs),
    );
  }

  factory CategoryOverrideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryOverrideRow(
      id: serializer.fromJson<String>(json['id']),
      productId: serializer.fromJson<String>(json['productId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      lastModifiedMs: serializer.fromJson<int>(json['lastModifiedMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'productId': serializer.toJson<String>(productId),
      'categoryId': serializer.toJson<String>(categoryId),
      'lastModifiedMs': serializer.toJson<int>(lastModifiedMs),
    };
  }

  CategoryOverrideRow copyWith({
    String? id,
    String? productId,
    String? categoryId,
    int? lastModifiedMs,
  }) => CategoryOverrideRow(
    id: id ?? this.id,
    productId: productId ?? this.productId,
    categoryId: categoryId ?? this.categoryId,
    lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
  );
  CategoryOverrideRow copyWithCompanion(CategoryOverridesCompanion data) {
    return CategoryOverrideRow(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      lastModifiedMs: data.lastModifiedMs.present
          ? data.lastModifiedMs.value
          : this.lastModifiedMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOverrideRow(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('categoryId: $categoryId, ')
          ..write('lastModifiedMs: $lastModifiedMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, categoryId, lastModifiedMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryOverrideRow &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.categoryId == this.categoryId &&
          other.lastModifiedMs == this.lastModifiedMs);
}

class CategoryOverridesCompanion extends UpdateCompanion<CategoryOverrideRow> {
  final Value<String> id;
  final Value<String> productId;
  final Value<String> categoryId;
  final Value<int> lastModifiedMs;
  final Value<int> rowid;
  const CategoryOverridesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.lastModifiedMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoryOverridesCompanion.insert({
    required String id,
    required String productId,
    required String categoryId,
    required int lastModifiedMs,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       productId = Value(productId),
       categoryId = Value(categoryId),
       lastModifiedMs = Value(lastModifiedMs);
  static Insertable<CategoryOverrideRow> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? categoryId,
    Expression<int>? lastModifiedMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (categoryId != null) 'category_id': categoryId,
      if (lastModifiedMs != null) 'last_modified_ms': lastModifiedMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoryOverridesCompanion copyWith({
    Value<String>? id,
    Value<String>? productId,
    Value<String>? categoryId,
    Value<int>? lastModifiedMs,
    Value<int>? rowid,
  }) {
    return CategoryOverridesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      categoryId: categoryId ?? this.categoryId,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (lastModifiedMs.present) {
      map['last_modified_ms'] = Variable<int>(lastModifiedMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoryOverridesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('categoryId: $categoryId, ')
          ..write('lastModifiedMs: $lastModifiedMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductUseTimestampsTable extends ProductUseTimestamps
    with TableInfo<$ProductUseTimestampsTable, ProductUseTimestampRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductUseTimestampsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstUsedAtMsMeta = const VerificationMeta(
    'firstUsedAtMs',
  );
  @override
  late final GeneratedColumn<int> firstUsedAtMs = GeneratedColumn<int>(
    'first_used_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastUsedAtMsMeta = const VerificationMeta(
    'lastUsedAtMs',
  );
  @override
  late final GeneratedColumn<int> lastUsedAtMs = GeneratedColumn<int>(
    'last_used_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    firstUsedAtMs,
    lastUsedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_use_timestamps';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductUseTimestampRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('first_used_at_ms')) {
      context.handle(
        _firstUsedAtMsMeta,
        firstUsedAtMs.isAcceptableOrUnknown(
          data['first_used_at_ms']!,
          _firstUsedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_firstUsedAtMsMeta);
    }
    if (data.containsKey('last_used_at_ms')) {
      context.handle(
        _lastUsedAtMsMeta,
        lastUsedAtMs.isAcceptableOrUnknown(
          data['last_used_at_ms']!,
          _lastUsedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastUsedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {productId};
  @override
  ProductUseTimestampRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductUseTimestampRow(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      firstUsedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_used_at_ms'],
      )!,
      lastUsedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_used_at_ms'],
      )!,
    );
  }

  @override
  $ProductUseTimestampsTable createAlias(String alias) {
    return $ProductUseTimestampsTable(attachedDatabase, alias);
  }
}

class ProductUseTimestampRow extends DataClass
    implements Insertable<ProductUseTimestampRow> {
  final String productId;
  final int firstUsedAtMs;
  final int lastUsedAtMs;
  const ProductUseTimestampRow({
    required this.productId,
    required this.firstUsedAtMs,
    required this.lastUsedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['product_id'] = Variable<String>(productId);
    map['first_used_at_ms'] = Variable<int>(firstUsedAtMs);
    map['last_used_at_ms'] = Variable<int>(lastUsedAtMs);
    return map;
  }

  ProductUseTimestampsCompanion toCompanion(bool nullToAbsent) {
    return ProductUseTimestampsCompanion(
      productId: Value(productId),
      firstUsedAtMs: Value(firstUsedAtMs),
      lastUsedAtMs: Value(lastUsedAtMs),
    );
  }

  factory ProductUseTimestampRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductUseTimestampRow(
      productId: serializer.fromJson<String>(json['productId']),
      firstUsedAtMs: serializer.fromJson<int>(json['firstUsedAtMs']),
      lastUsedAtMs: serializer.fromJson<int>(json['lastUsedAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'productId': serializer.toJson<String>(productId),
      'firstUsedAtMs': serializer.toJson<int>(firstUsedAtMs),
      'lastUsedAtMs': serializer.toJson<int>(lastUsedAtMs),
    };
  }

  ProductUseTimestampRow copyWith({
    String? productId,
    int? firstUsedAtMs,
    int? lastUsedAtMs,
  }) => ProductUseTimestampRow(
    productId: productId ?? this.productId,
    firstUsedAtMs: firstUsedAtMs ?? this.firstUsedAtMs,
    lastUsedAtMs: lastUsedAtMs ?? this.lastUsedAtMs,
  );
  ProductUseTimestampRow copyWithCompanion(ProductUseTimestampsCompanion data) {
    return ProductUseTimestampRow(
      productId: data.productId.present ? data.productId.value : this.productId,
      firstUsedAtMs: data.firstUsedAtMs.present
          ? data.firstUsedAtMs.value
          : this.firstUsedAtMs,
      lastUsedAtMs: data.lastUsedAtMs.present
          ? data.lastUsedAtMs.value
          : this.lastUsedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductUseTimestampRow(')
          ..write('productId: $productId, ')
          ..write('firstUsedAtMs: $firstUsedAtMs, ')
          ..write('lastUsedAtMs: $lastUsedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, firstUsedAtMs, lastUsedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductUseTimestampRow &&
          other.productId == this.productId &&
          other.firstUsedAtMs == this.firstUsedAtMs &&
          other.lastUsedAtMs == this.lastUsedAtMs);
}

class ProductUseTimestampsCompanion
    extends UpdateCompanion<ProductUseTimestampRow> {
  final Value<String> productId;
  final Value<int> firstUsedAtMs;
  final Value<int> lastUsedAtMs;
  final Value<int> rowid;
  const ProductUseTimestampsCompanion({
    this.productId = const Value.absent(),
    this.firstUsedAtMs = const Value.absent(),
    this.lastUsedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductUseTimestampsCompanion.insert({
    required String productId,
    required int firstUsedAtMs,
    required int lastUsedAtMs,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       firstUsedAtMs = Value(firstUsedAtMs),
       lastUsedAtMs = Value(lastUsedAtMs);
  static Insertable<ProductUseTimestampRow> custom({
    Expression<String>? productId,
    Expression<int>? firstUsedAtMs,
    Expression<int>? lastUsedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (productId != null) 'product_id': productId,
      if (firstUsedAtMs != null) 'first_used_at_ms': firstUsedAtMs,
      if (lastUsedAtMs != null) 'last_used_at_ms': lastUsedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductUseTimestampsCompanion copyWith({
    Value<String>? productId,
    Value<int>? firstUsedAtMs,
    Value<int>? lastUsedAtMs,
    Value<int>? rowid,
  }) {
    return ProductUseTimestampsCompanion(
      productId: productId ?? this.productId,
      firstUsedAtMs: firstUsedAtMs ?? this.firstUsedAtMs,
      lastUsedAtMs: lastUsedAtMs ?? this.lastUsedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (firstUsedAtMs.present) {
      map['first_used_at_ms'] = Variable<int>(firstUsedAtMs.value);
    }
    if (lastUsedAtMs.present) {
      map['last_used_at_ms'] = Variable<int>(lastUsedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductUseTimestampsCompanion(')
          ..write('productId: $productId, ')
          ..write('firstUsedAtMs: $firstUsedAtMs, ')
          ..write('lastUsedAtMs: $lastUsedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductSelectionsTable productSelections =
      $ProductSelectionsTable(this);
  late final $WeekdaySchedulesTable weekdaySchedules = $WeekdaySchedulesTable(
    this,
  );
  late final $OrderOverridesTable orderOverrides = $OrderOverridesTable(this);
  late final $DayRecordsTable dayRecords = $DayRecordsTable(this);
  late final $SkinLogEntriesTable skinLogEntries = $SkinLogEntriesTable(this);
  late final $MutedConflictsTable mutedConflicts = $MutedConflictsTable(this);
  late final $UserCustomProductsTable userCustomProducts =
      $UserCustomProductsTable(this);
  late final $CollectionItemsTable collectionItems = $CollectionItemsTable(
    this,
  );
  late final $CategoryOverridesTable categoryOverrides =
      $CategoryOverridesTable(this);
  late final $ProductUseTimestampsTable productUseTimestamps =
      $ProductUseTimestampsTable(this);
  late final SelectionsDao selectionsDao = SelectionsDao(this as AppDatabase);
  late final SchedulesDao schedulesDao = SchedulesDao(this as AppDatabase);
  late final OrderOverridesDao orderOverridesDao = OrderOverridesDao(
    this as AppDatabase,
  );
  late final DayRecordsDao dayRecordsDao = DayRecordsDao(this as AppDatabase);
  late final SkinLogDao skinLogDao = SkinLogDao(this as AppDatabase);
  late final MutedConflictsDao mutedConflictsDao = MutedConflictsDao(
    this as AppDatabase,
  );
  late final UserCustomProductsDao userCustomProductsDao =
      UserCustomProductsDao(this as AppDatabase);
  late final CollectionItemsDao collectionItemsDao = CollectionItemsDao(
    this as AppDatabase,
  );
  late final CategoryOverridesDao categoryOverridesDao = CategoryOverridesDao(
    this as AppDatabase,
  );
  late final ProductUseTimestampsDao productUseTimestampsDao =
      ProductUseTimestampsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productSelections,
    weekdaySchedules,
    orderOverrides,
    dayRecords,
    skinLogEntries,
    mutedConflicts,
    userCustomProducts,
    collectionItems,
    categoryOverrides,
    productUseTimestamps,
  ];
}

typedef $$ProductSelectionsTableCreateCompanionBuilder =
    ProductSelectionsCompanion Function({
      required String id,
      required String productId,
      required String slot,
      required bool isSelected,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$ProductSelectionsTableUpdateCompanionBuilder =
    ProductSelectionsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> slot,
      Value<bool> isSelected,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$ProductSelectionsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductSelectionsTable> {
  $$ProductSelectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductSelectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductSelectionsTable> {
  $$ProductSelectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductSelectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductSelectionsTable> {
  $$ProductSelectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<bool> get isSelected => $composableBuilder(
    column: $table.isSelected,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$ProductSelectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductSelectionsTable,
          SelectionRow,
          $$ProductSelectionsTableFilterComposer,
          $$ProductSelectionsTableOrderingComposer,
          $$ProductSelectionsTableAnnotationComposer,
          $$ProductSelectionsTableCreateCompanionBuilder,
          $$ProductSelectionsTableUpdateCompanionBuilder,
          (
            SelectionRow,
            BaseReferences<
              _$AppDatabase,
              $ProductSelectionsTable,
              SelectionRow
            >,
          ),
          SelectionRow,
          PrefetchHooks Function()
        > {
  $$ProductSelectionsTableTableManager(
    _$AppDatabase db,
    $ProductSelectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductSelectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductSelectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductSelectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<bool> isSelected = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductSelectionsCompanion(
                id: id,
                productId: productId,
                slot: slot,
                isSelected: isSelected,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String slot,
                required bool isSelected,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => ProductSelectionsCompanion.insert(
                id: id,
                productId: productId,
                slot: slot,
                isSelected: isSelected,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductSelectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductSelectionsTable,
      SelectionRow,
      $$ProductSelectionsTableFilterComposer,
      $$ProductSelectionsTableOrderingComposer,
      $$ProductSelectionsTableAnnotationComposer,
      $$ProductSelectionsTableCreateCompanionBuilder,
      $$ProductSelectionsTableUpdateCompanionBuilder,
      (
        SelectionRow,
        BaseReferences<_$AppDatabase, $ProductSelectionsTable, SelectionRow>,
      ),
      SelectionRow,
      PrefetchHooks Function()
    >;
typedef $$WeekdaySchedulesTableCreateCompanionBuilder =
    WeekdaySchedulesCompanion Function({
      required String id,
      required String productId,
      required String slot,
      required String weekdaysJson,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$WeekdaySchedulesTableUpdateCompanionBuilder =
    WeekdaySchedulesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> slot,
      Value<String> weekdaysJson,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$WeekdaySchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get weekdaysJson => $composableBuilder(
    column: $table.weekdaysJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WeekdaySchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get weekdaysJson => $composableBuilder(
    column: $table.weekdaysJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WeekdaySchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WeekdaySchedulesTable> {
  $$WeekdaySchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get weekdaysJson => $composableBuilder(
    column: $table.weekdaysJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$WeekdaySchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WeekdaySchedulesTable,
          ScheduleRow,
          $$WeekdaySchedulesTableFilterComposer,
          $$WeekdaySchedulesTableOrderingComposer,
          $$WeekdaySchedulesTableAnnotationComposer,
          $$WeekdaySchedulesTableCreateCompanionBuilder,
          $$WeekdaySchedulesTableUpdateCompanionBuilder,
          (
            ScheduleRow,
            BaseReferences<_$AppDatabase, $WeekdaySchedulesTable, ScheduleRow>,
          ),
          ScheduleRow,
          PrefetchHooks Function()
        > {
  $$WeekdaySchedulesTableTableManager(
    _$AppDatabase db,
    $WeekdaySchedulesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WeekdaySchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WeekdaySchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WeekdaySchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> weekdaysJson = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WeekdaySchedulesCompanion(
                id: id,
                productId: productId,
                slot: slot,
                weekdaysJson: weekdaysJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String slot,
                required String weekdaysJson,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => WeekdaySchedulesCompanion.insert(
                id: id,
                productId: productId,
                slot: slot,
                weekdaysJson: weekdaysJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WeekdaySchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WeekdaySchedulesTable,
      ScheduleRow,
      $$WeekdaySchedulesTableFilterComposer,
      $$WeekdaySchedulesTableOrderingComposer,
      $$WeekdaySchedulesTableAnnotationComposer,
      $$WeekdaySchedulesTableCreateCompanionBuilder,
      $$WeekdaySchedulesTableUpdateCompanionBuilder,
      (
        ScheduleRow,
        BaseReferences<_$AppDatabase, $WeekdaySchedulesTable, ScheduleRow>,
      ),
      ScheduleRow,
      PrefetchHooks Function()
    >;
typedef $$OrderOverridesTableCreateCompanionBuilder =
    OrderOverridesCompanion Function({
      required String id,
      required String slot,
      Value<int?> weekday,
      required String orderedProductIdsJson,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$OrderOverridesTableUpdateCompanionBuilder =
    OrderOverridesCompanion Function({
      Value<String> id,
      Value<String> slot,
      Value<int?> weekday,
      Value<String> orderedProductIdsJson,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$OrderOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $OrderOverridesTable> {
  $$OrderOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get orderedProductIdsJson => $composableBuilder(
    column: $table.orderedProductIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OrderOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $OrderOverridesTable> {
  $$OrderOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weekday => $composableBuilder(
    column: $table.weekday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get orderedProductIdsJson => $composableBuilder(
    column: $table.orderedProductIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OrderOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OrderOverridesTable> {
  $$OrderOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<int> get weekday =>
      $composableBuilder(column: $table.weekday, builder: (column) => column);

  GeneratedColumn<String> get orderedProductIdsJson => $composableBuilder(
    column: $table.orderedProductIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$OrderOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OrderOverridesTable,
          OrderOverrideRow,
          $$OrderOverridesTableFilterComposer,
          $$OrderOverridesTableOrderingComposer,
          $$OrderOverridesTableAnnotationComposer,
          $$OrderOverridesTableCreateCompanionBuilder,
          $$OrderOverridesTableUpdateCompanionBuilder,
          (
            OrderOverrideRow,
            BaseReferences<
              _$AppDatabase,
              $OrderOverridesTable,
              OrderOverrideRow
            >,
          ),
          OrderOverrideRow,
          PrefetchHooks Function()
        > {
  $$OrderOverridesTableTableManager(
    _$AppDatabase db,
    $OrderOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OrderOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OrderOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OrderOverridesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<int?> weekday = const Value.absent(),
                Value<String> orderedProductIdsJson = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderOverridesCompanion(
                id: id,
                slot: slot,
                weekday: weekday,
                orderedProductIdsJson: orderedProductIdsJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String slot,
                Value<int?> weekday = const Value.absent(),
                required String orderedProductIdsJson,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => OrderOverridesCompanion.insert(
                id: id,
                slot: slot,
                weekday: weekday,
                orderedProductIdsJson: orderedProductIdsJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OrderOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OrderOverridesTable,
      OrderOverrideRow,
      $$OrderOverridesTableFilterComposer,
      $$OrderOverridesTableOrderingComposer,
      $$OrderOverridesTableAnnotationComposer,
      $$OrderOverridesTableCreateCompanionBuilder,
      $$OrderOverridesTableUpdateCompanionBuilder,
      (
        OrderOverrideRow,
        BaseReferences<_$AppDatabase, $OrderOverridesTable, OrderOverrideRow>,
      ),
      OrderOverrideRow,
      PrefetchHooks Function()
    >;
typedef $$DayRecordsTableCreateCompanionBuilder =
    DayRecordsCompanion Function({
      required String id,
      required String date,
      required String slot,
      required String resolvedProductIdsJson,
      required String recordedProductIdsJson,
      required String resolvedAtMasterVersion,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$DayRecordsTableUpdateCompanionBuilder =
    DayRecordsCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String> slot,
      Value<String> resolvedProductIdsJson,
      Value<String> recordedProductIdsJson,
      Value<String> resolvedAtMasterVersion,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$DayRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedProductIdsJson => $composableBuilder(
    column: $table.resolvedProductIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordedProductIdsJson => $composableBuilder(
    column: $table.recordedProductIdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resolvedAtMasterVersion => $composableBuilder(
    column: $table.resolvedAtMasterVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slot => $composableBuilder(
    column: $table.slot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedProductIdsJson => $composableBuilder(
    column: $table.resolvedProductIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordedProductIdsJson => $composableBuilder(
    column: $table.recordedProductIdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resolvedAtMasterVersion => $composableBuilder(
    column: $table.resolvedAtMasterVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DayRecordsTable> {
  $$DayRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get slot =>
      $composableBuilder(column: $table.slot, builder: (column) => column);

  GeneratedColumn<String> get resolvedProductIdsJson => $composableBuilder(
    column: $table.resolvedProductIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordedProductIdsJson => $composableBuilder(
    column: $table.recordedProductIdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resolvedAtMasterVersion => $composableBuilder(
    column: $table.resolvedAtMasterVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$DayRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DayRecordsTable,
          DayRecordRow,
          $$DayRecordsTableFilterComposer,
          $$DayRecordsTableOrderingComposer,
          $$DayRecordsTableAnnotationComposer,
          $$DayRecordsTableCreateCompanionBuilder,
          $$DayRecordsTableUpdateCompanionBuilder,
          (
            DayRecordRow,
            BaseReferences<_$AppDatabase, $DayRecordsTable, DayRecordRow>,
          ),
          DayRecordRow,
          PrefetchHooks Function()
        > {
  $$DayRecordsTableTableManager(_$AppDatabase db, $DayRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> slot = const Value.absent(),
                Value<String> resolvedProductIdsJson = const Value.absent(),
                Value<String> recordedProductIdsJson = const Value.absent(),
                Value<String> resolvedAtMasterVersion = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayRecordsCompanion(
                id: id,
                date: date,
                slot: slot,
                resolvedProductIdsJson: resolvedProductIdsJson,
                recordedProductIdsJson: recordedProductIdsJson,
                resolvedAtMasterVersion: resolvedAtMasterVersion,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                required String slot,
                required String resolvedProductIdsJson,
                required String recordedProductIdsJson,
                required String resolvedAtMasterVersion,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => DayRecordsCompanion.insert(
                id: id,
                date: date,
                slot: slot,
                resolvedProductIdsJson: resolvedProductIdsJson,
                recordedProductIdsJson: recordedProductIdsJson,
                resolvedAtMasterVersion: resolvedAtMasterVersion,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DayRecordsTable,
      DayRecordRow,
      $$DayRecordsTableFilterComposer,
      $$DayRecordsTableOrderingComposer,
      $$DayRecordsTableAnnotationComposer,
      $$DayRecordsTableCreateCompanionBuilder,
      $$DayRecordsTableUpdateCompanionBuilder,
      (
        DayRecordRow,
        BaseReferences<_$AppDatabase, $DayRecordsTable, DayRecordRow>,
      ),
      DayRecordRow,
      PrefetchHooks Function()
    >;
typedef $$SkinLogEntriesTableCreateCompanionBuilder =
    SkinLogEntriesCompanion Function({
      required String id,
      required String date,
      Value<String?> notes,
      Value<String?> skinState,
      required String photoPathsJson,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$SkinLogEntriesTableUpdateCompanionBuilder =
    SkinLogEntriesCompanion Function({
      Value<String> id,
      Value<String> date,
      Value<String?> notes,
      Value<String?> skinState,
      Value<String> photoPathsJson,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$SkinLogEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SkinLogEntriesTable> {
  $$SkinLogEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skinState => $composableBuilder(
    column: $table.skinState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SkinLogEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SkinLogEntriesTable> {
  $$SkinLogEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skinState => $composableBuilder(
    column: $table.skinState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SkinLogEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SkinLogEntriesTable> {
  $$SkinLogEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get skinState =>
      $composableBuilder(column: $table.skinState, builder: (column) => column);

  GeneratedColumn<String> get photoPathsJson => $composableBuilder(
    column: $table.photoPathsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$SkinLogEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SkinLogEntriesTable,
          SkinLogRow,
          $$SkinLogEntriesTableFilterComposer,
          $$SkinLogEntriesTableOrderingComposer,
          $$SkinLogEntriesTableAnnotationComposer,
          $$SkinLogEntriesTableCreateCompanionBuilder,
          $$SkinLogEntriesTableUpdateCompanionBuilder,
          (
            SkinLogRow,
            BaseReferences<_$AppDatabase, $SkinLogEntriesTable, SkinLogRow>,
          ),
          SkinLogRow,
          PrefetchHooks Function()
        > {
  $$SkinLogEntriesTableTableManager(
    _$AppDatabase db,
    $SkinLogEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SkinLogEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SkinLogEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SkinLogEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> skinState = const Value.absent(),
                Value<String> photoPathsJson = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SkinLogEntriesCompanion(
                id: id,
                date: date,
                notes: notes,
                skinState: skinState,
                photoPathsJson: photoPathsJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String date,
                Value<String?> notes = const Value.absent(),
                Value<String?> skinState = const Value.absent(),
                required String photoPathsJson,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => SkinLogEntriesCompanion.insert(
                id: id,
                date: date,
                notes: notes,
                skinState: skinState,
                photoPathsJson: photoPathsJson,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SkinLogEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SkinLogEntriesTable,
      SkinLogRow,
      $$SkinLogEntriesTableFilterComposer,
      $$SkinLogEntriesTableOrderingComposer,
      $$SkinLogEntriesTableAnnotationComposer,
      $$SkinLogEntriesTableCreateCompanionBuilder,
      $$SkinLogEntriesTableUpdateCompanionBuilder,
      (
        SkinLogRow,
        BaseReferences<_$AppDatabase, $SkinLogEntriesTable, SkinLogRow>,
      ),
      SkinLogRow,
      PrefetchHooks Function()
    >;
typedef $$MutedConflictsTableCreateCompanionBuilder =
    MutedConflictsCompanion Function({
      required String id,
      required String ruleId,
      required int mutedAtMs,
      Value<int> rowid,
    });
typedef $$MutedConflictsTableUpdateCompanionBuilder =
    MutedConflictsCompanion Function({
      Value<String> id,
      Value<String> ruleId,
      Value<int> mutedAtMs,
      Value<int> rowid,
    });

class $$MutedConflictsTableFilterComposer
    extends Composer<_$AppDatabase, $MutedConflictsTable> {
  $$MutedConflictsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mutedAtMs => $composableBuilder(
    column: $table.mutedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MutedConflictsTableOrderingComposer
    extends Composer<_$AppDatabase, $MutedConflictsTable> {
  $$MutedConflictsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ruleId => $composableBuilder(
    column: $table.ruleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mutedAtMs => $composableBuilder(
    column: $table.mutedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MutedConflictsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MutedConflictsTable> {
  $$MutedConflictsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get ruleId =>
      $composableBuilder(column: $table.ruleId, builder: (column) => column);

  GeneratedColumn<int> get mutedAtMs =>
      $composableBuilder(column: $table.mutedAtMs, builder: (column) => column);
}

class $$MutedConflictsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MutedConflictsTable,
          MutedConflictRow,
          $$MutedConflictsTableFilterComposer,
          $$MutedConflictsTableOrderingComposer,
          $$MutedConflictsTableAnnotationComposer,
          $$MutedConflictsTableCreateCompanionBuilder,
          $$MutedConflictsTableUpdateCompanionBuilder,
          (
            MutedConflictRow,
            BaseReferences<
              _$AppDatabase,
              $MutedConflictsTable,
              MutedConflictRow
            >,
          ),
          MutedConflictRow,
          PrefetchHooks Function()
        > {
  $$MutedConflictsTableTableManager(
    _$AppDatabase db,
    $MutedConflictsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MutedConflictsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MutedConflictsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MutedConflictsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ruleId = const Value.absent(),
                Value<int> mutedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MutedConflictsCompanion(
                id: id,
                ruleId: ruleId,
                mutedAtMs: mutedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ruleId,
                required int mutedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => MutedConflictsCompanion.insert(
                id: id,
                ruleId: ruleId,
                mutedAtMs: mutedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MutedConflictsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MutedConflictsTable,
      MutedConflictRow,
      $$MutedConflictsTableFilterComposer,
      $$MutedConflictsTableOrderingComposer,
      $$MutedConflictsTableAnnotationComposer,
      $$MutedConflictsTableCreateCompanionBuilder,
      $$MutedConflictsTableUpdateCompanionBuilder,
      (
        MutedConflictRow,
        BaseReferences<_$AppDatabase, $MutedConflictsTable, MutedConflictRow>,
      ),
      MutedConflictRow,
      PrefetchHooks Function()
    >;
typedef $$UserCustomProductsTableCreateCompanionBuilder =
    UserCustomProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> photoKey,
      required String categoryId,
      Value<String?> subCategoryId,
      required bool inMorning,
      required bool inEvening,
      required bool isDaily,
      Value<int?> maxTimesPerWeek,
      required int lastModifiedMs,
      Value<String?> commentJson,
      Value<String?> brand,
      Value<String?> ingredients,
      Value<bool> isDeprecated,
      Value<int> rowid,
    });
typedef $$UserCustomProductsTableUpdateCompanionBuilder =
    UserCustomProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> photoKey,
      Value<String> categoryId,
      Value<String?> subCategoryId,
      Value<bool> inMorning,
      Value<bool> inEvening,
      Value<bool> isDaily,
      Value<int?> maxTimesPerWeek,
      Value<int> lastModifiedMs,
      Value<String?> commentJson,
      Value<String?> brand,
      Value<String?> ingredients,
      Value<bool> isDeprecated,
      Value<int> rowid,
    });

class $$UserCustomProductsTableFilterComposer
    extends Composer<_$AppDatabase, $UserCustomProductsTable> {
  $$UserCustomProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoKey => $composableBuilder(
    column: $table.photoKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inMorning => $composableBuilder(
    column: $table.inMorning,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get inEvening => $composableBuilder(
    column: $table.inEvening,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxTimesPerWeek => $composableBuilder(
    column: $table.maxTimesPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commentJson => $composableBuilder(
    column: $table.commentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeprecated => $composableBuilder(
    column: $table.isDeprecated,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UserCustomProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserCustomProductsTable> {
  $$UserCustomProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoKey => $composableBuilder(
    column: $table.photoKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inMorning => $composableBuilder(
    column: $table.inMorning,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get inEvening => $composableBuilder(
    column: $table.inEvening,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDaily => $composableBuilder(
    column: $table.isDaily,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxTimesPerWeek => $composableBuilder(
    column: $table.maxTimesPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commentJson => $composableBuilder(
    column: $table.commentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeprecated => $composableBuilder(
    column: $table.isDeprecated,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserCustomProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserCustomProductsTable> {
  $$UserCustomProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get photoKey =>
      $composableBuilder(column: $table.photoKey, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get inMorning =>
      $composableBuilder(column: $table.inMorning, builder: (column) => column);

  GeneratedColumn<bool> get inEvening =>
      $composableBuilder(column: $table.inEvening, builder: (column) => column);

  GeneratedColumn<bool> get isDaily =>
      $composableBuilder(column: $table.isDaily, builder: (column) => column);

  GeneratedColumn<int> get maxTimesPerWeek => $composableBuilder(
    column: $table.maxTimesPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commentJson => $composableBuilder(
    column: $table.commentJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get ingredients => $composableBuilder(
    column: $table.ingredients,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeprecated => $composableBuilder(
    column: $table.isDeprecated,
    builder: (column) => column,
  );
}

class $$UserCustomProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserCustomProductsTable,
          CustomProductRow,
          $$UserCustomProductsTableFilterComposer,
          $$UserCustomProductsTableOrderingComposer,
          $$UserCustomProductsTableAnnotationComposer,
          $$UserCustomProductsTableCreateCompanionBuilder,
          $$UserCustomProductsTableUpdateCompanionBuilder,
          (
            CustomProductRow,
            BaseReferences<
              _$AppDatabase,
              $UserCustomProductsTable,
              CustomProductRow
            >,
          ),
          CustomProductRow,
          PrefetchHooks Function()
        > {
  $$UserCustomProductsTableTableManager(
    _$AppDatabase db,
    $UserCustomProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserCustomProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserCustomProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserCustomProductsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> photoKey = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String?> subCategoryId = const Value.absent(),
                Value<bool> inMorning = const Value.absent(),
                Value<bool> inEvening = const Value.absent(),
                Value<bool> isDaily = const Value.absent(),
                Value<int?> maxTimesPerWeek = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<String?> commentJson = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> ingredients = const Value.absent(),
                Value<bool> isDeprecated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCustomProductsCompanion(
                id: id,
                name: name,
                photoKey: photoKey,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                inMorning: inMorning,
                inEvening: inEvening,
                isDaily: isDaily,
                maxTimesPerWeek: maxTimesPerWeek,
                lastModifiedMs: lastModifiedMs,
                commentJson: commentJson,
                brand: brand,
                ingredients: ingredients,
                isDeprecated: isDeprecated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> photoKey = const Value.absent(),
                required String categoryId,
                Value<String?> subCategoryId = const Value.absent(),
                required bool inMorning,
                required bool inEvening,
                required bool isDaily,
                Value<int?> maxTimesPerWeek = const Value.absent(),
                required int lastModifiedMs,
                Value<String?> commentJson = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> ingredients = const Value.absent(),
                Value<bool> isDeprecated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserCustomProductsCompanion.insert(
                id: id,
                name: name,
                photoKey: photoKey,
                categoryId: categoryId,
                subCategoryId: subCategoryId,
                inMorning: inMorning,
                inEvening: inEvening,
                isDaily: isDaily,
                maxTimesPerWeek: maxTimesPerWeek,
                lastModifiedMs: lastModifiedMs,
                commentJson: commentJson,
                brand: brand,
                ingredients: ingredients,
                isDeprecated: isDeprecated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UserCustomProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserCustomProductsTable,
      CustomProductRow,
      $$UserCustomProductsTableFilterComposer,
      $$UserCustomProductsTableOrderingComposer,
      $$UserCustomProductsTableAnnotationComposer,
      $$UserCustomProductsTableCreateCompanionBuilder,
      $$UserCustomProductsTableUpdateCompanionBuilder,
      (
        CustomProductRow,
        BaseReferences<
          _$AppDatabase,
          $UserCustomProductsTable,
          CustomProductRow
        >,
      ),
      CustomProductRow,
      PrefetchHooks Function()
    >;
typedef $$CollectionItemsTableCreateCompanionBuilder =
    CollectionItemsCompanion Function({
      required String id,
      required String productId,
      required String status,
      Value<int?> openedDateMs,
      required int paoMonths,
      Value<bool> notificationsEnabled,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$CollectionItemsTableUpdateCompanionBuilder =
    CollectionItemsCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> status,
      Value<int?> openedDateMs,
      Value<int> paoMonths,
      Value<bool> notificationsEnabled,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$CollectionItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedDateMs => $composableBuilder(
    column: $table.openedDateMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get paoMonths => $composableBuilder(
    column: $table.paoMonths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CollectionItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedDateMs => $composableBuilder(
    column: $table.openedDateMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get paoMonths => $composableBuilder(
    column: $table.paoMonths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CollectionItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CollectionItemsTable> {
  $$CollectionItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get openedDateMs => $composableBuilder(
    column: $table.openedDateMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get paoMonths =>
      $composableBuilder(column: $table.paoMonths, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$CollectionItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CollectionItemsTable,
          CollectionItemRow,
          $$CollectionItemsTableFilterComposer,
          $$CollectionItemsTableOrderingComposer,
          $$CollectionItemsTableAnnotationComposer,
          $$CollectionItemsTableCreateCompanionBuilder,
          $$CollectionItemsTableUpdateCompanionBuilder,
          (
            CollectionItemRow,
            BaseReferences<
              _$AppDatabase,
              $CollectionItemsTable,
              CollectionItemRow
            >,
          ),
          CollectionItemRow,
          PrefetchHooks Function()
        > {
  $$CollectionItemsTableTableManager(
    _$AppDatabase db,
    $CollectionItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CollectionItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CollectionItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CollectionItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> openedDateMs = const Value.absent(),
                Value<int> paoMonths = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion(
                id: id,
                productId: productId,
                status: status,
                openedDateMs: openedDateMs,
                paoMonths: paoMonths,
                notificationsEnabled: notificationsEnabled,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String status,
                Value<int?> openedDateMs = const Value.absent(),
                required int paoMonths,
                Value<bool> notificationsEnabled = const Value.absent(),
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => CollectionItemsCompanion.insert(
                id: id,
                productId: productId,
                status: status,
                openedDateMs: openedDateMs,
                paoMonths: paoMonths,
                notificationsEnabled: notificationsEnabled,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CollectionItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CollectionItemsTable,
      CollectionItemRow,
      $$CollectionItemsTableFilterComposer,
      $$CollectionItemsTableOrderingComposer,
      $$CollectionItemsTableAnnotationComposer,
      $$CollectionItemsTableCreateCompanionBuilder,
      $$CollectionItemsTableUpdateCompanionBuilder,
      (
        CollectionItemRow,
        BaseReferences<_$AppDatabase, $CollectionItemsTable, CollectionItemRow>,
      ),
      CollectionItemRow,
      PrefetchHooks Function()
    >;
typedef $$CategoryOverridesTableCreateCompanionBuilder =
    CategoryOverridesCompanion Function({
      required String id,
      required String productId,
      required String categoryId,
      required int lastModifiedMs,
      Value<int> rowid,
    });
typedef $$CategoryOverridesTableUpdateCompanionBuilder =
    CategoryOverridesCompanion Function({
      Value<String> id,
      Value<String> productId,
      Value<String> categoryId,
      Value<int> lastModifiedMs,
      Value<int> rowid,
    });

class $$CategoryOverridesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoryOverridesTable> {
  $$CategoryOverridesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoryOverridesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoryOverridesTable> {
  $$CategoryOverridesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoryOverridesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoryOverridesTable> {
  $$CategoryOverridesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastModifiedMs => $composableBuilder(
    column: $table.lastModifiedMs,
    builder: (column) => column,
  );
}

class $$CategoryOverridesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoryOverridesTable,
          CategoryOverrideRow,
          $$CategoryOverridesTableFilterComposer,
          $$CategoryOverridesTableOrderingComposer,
          $$CategoryOverridesTableAnnotationComposer,
          $$CategoryOverridesTableCreateCompanionBuilder,
          $$CategoryOverridesTableUpdateCompanionBuilder,
          (
            CategoryOverrideRow,
            BaseReferences<
              _$AppDatabase,
              $CategoryOverridesTable,
              CategoryOverrideRow
            >,
          ),
          CategoryOverrideRow,
          PrefetchHooks Function()
        > {
  $$CategoryOverridesTableTableManager(
    _$AppDatabase db,
    $CategoryOverridesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoryOverridesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoryOverridesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoryOverridesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<int> lastModifiedMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoryOverridesCompanion(
                id: id,
                productId: productId,
                categoryId: categoryId,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String productId,
                required String categoryId,
                required int lastModifiedMs,
                Value<int> rowid = const Value.absent(),
              }) => CategoryOverridesCompanion.insert(
                id: id,
                productId: productId,
                categoryId: categoryId,
                lastModifiedMs: lastModifiedMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoryOverridesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoryOverridesTable,
      CategoryOverrideRow,
      $$CategoryOverridesTableFilterComposer,
      $$CategoryOverridesTableOrderingComposer,
      $$CategoryOverridesTableAnnotationComposer,
      $$CategoryOverridesTableCreateCompanionBuilder,
      $$CategoryOverridesTableUpdateCompanionBuilder,
      (
        CategoryOverrideRow,
        BaseReferences<
          _$AppDatabase,
          $CategoryOverridesTable,
          CategoryOverrideRow
        >,
      ),
      CategoryOverrideRow,
      PrefetchHooks Function()
    >;
typedef $$ProductUseTimestampsTableCreateCompanionBuilder =
    ProductUseTimestampsCompanion Function({
      required String productId,
      required int firstUsedAtMs,
      required int lastUsedAtMs,
      Value<int> rowid,
    });
typedef $$ProductUseTimestampsTableUpdateCompanionBuilder =
    ProductUseTimestampsCompanion Function({
      Value<String> productId,
      Value<int> firstUsedAtMs,
      Value<int> lastUsedAtMs,
      Value<int> rowid,
    });

class $$ProductUseTimestampsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductUseTimestampsTable> {
  $$ProductUseTimestampsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstUsedAtMs => $composableBuilder(
    column: $table.firstUsedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductUseTimestampsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductUseTimestampsTable> {
  $$ProductUseTimestampsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstUsedAtMs => $composableBuilder(
    column: $table.firstUsedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductUseTimestampsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductUseTimestampsTable> {
  $$ProductUseTimestampsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<int> get firstUsedAtMs => $composableBuilder(
    column: $table.firstUsedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastUsedAtMs => $composableBuilder(
    column: $table.lastUsedAtMs,
    builder: (column) => column,
  );
}

class $$ProductUseTimestampsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductUseTimestampsTable,
          ProductUseTimestampRow,
          $$ProductUseTimestampsTableFilterComposer,
          $$ProductUseTimestampsTableOrderingComposer,
          $$ProductUseTimestampsTableAnnotationComposer,
          $$ProductUseTimestampsTableCreateCompanionBuilder,
          $$ProductUseTimestampsTableUpdateCompanionBuilder,
          (
            ProductUseTimestampRow,
            BaseReferences<
              _$AppDatabase,
              $ProductUseTimestampsTable,
              ProductUseTimestampRow
            >,
          ),
          ProductUseTimestampRow,
          PrefetchHooks Function()
        > {
  $$ProductUseTimestampsTableTableManager(
    _$AppDatabase db,
    $ProductUseTimestampsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductUseTimestampsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductUseTimestampsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ProductUseTimestampsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> productId = const Value.absent(),
                Value<int> firstUsedAtMs = const Value.absent(),
                Value<int> lastUsedAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductUseTimestampsCompanion(
                productId: productId,
                firstUsedAtMs: firstUsedAtMs,
                lastUsedAtMs: lastUsedAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String productId,
                required int firstUsedAtMs,
                required int lastUsedAtMs,
                Value<int> rowid = const Value.absent(),
              }) => ProductUseTimestampsCompanion.insert(
                productId: productId,
                firstUsedAtMs: firstUsedAtMs,
                lastUsedAtMs: lastUsedAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductUseTimestampsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductUseTimestampsTable,
      ProductUseTimestampRow,
      $$ProductUseTimestampsTableFilterComposer,
      $$ProductUseTimestampsTableOrderingComposer,
      $$ProductUseTimestampsTableAnnotationComposer,
      $$ProductUseTimestampsTableCreateCompanionBuilder,
      $$ProductUseTimestampsTableUpdateCompanionBuilder,
      (
        ProductUseTimestampRow,
        BaseReferences<
          _$AppDatabase,
          $ProductUseTimestampsTable,
          ProductUseTimestampRow
        >,
      ),
      ProductUseTimestampRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductSelectionsTableTableManager get productSelections =>
      $$ProductSelectionsTableTableManager(_db, _db.productSelections);
  $$WeekdaySchedulesTableTableManager get weekdaySchedules =>
      $$WeekdaySchedulesTableTableManager(_db, _db.weekdaySchedules);
  $$OrderOverridesTableTableManager get orderOverrides =>
      $$OrderOverridesTableTableManager(_db, _db.orderOverrides);
  $$DayRecordsTableTableManager get dayRecords =>
      $$DayRecordsTableTableManager(_db, _db.dayRecords);
  $$SkinLogEntriesTableTableManager get skinLogEntries =>
      $$SkinLogEntriesTableTableManager(_db, _db.skinLogEntries);
  $$MutedConflictsTableTableManager get mutedConflicts =>
      $$MutedConflictsTableTableManager(_db, _db.mutedConflicts);
  $$UserCustomProductsTableTableManager get userCustomProducts =>
      $$UserCustomProductsTableTableManager(_db, _db.userCustomProducts);
  $$CollectionItemsTableTableManager get collectionItems =>
      $$CollectionItemsTableTableManager(_db, _db.collectionItems);
  $$CategoryOverridesTableTableManager get categoryOverrides =>
      $$CategoryOverridesTableTableManager(_db, _db.categoryOverrides);
  $$ProductUseTimestampsTableTableManager get productUseTimestamps =>
      $$ProductUseTimestampsTableTableManager(_db, _db.productUseTimestamps);
}
