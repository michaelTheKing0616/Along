// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'along_database.dart';

// ignore_for_file: type=lint
class $KvStoreTable extends KvStore with TableInfo<$KvStoreTable, KvStoreData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KvStoreTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
      'key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'kv_store';
  @override
  VerificationContext validateIntegrity(Insertable<KvStoreData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
          _keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KvStoreData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KvStoreData(
      key: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value'])!,
    );
  }

  @override
  $KvStoreTable createAlias(String alias) {
    return $KvStoreTable(attachedDatabase, alias);
  }
}

class KvStoreData extends DataClass implements Insertable<KvStoreData> {
  final String key;
  final String value;
  const KvStoreData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  KvStoreCompanion toCompanion(bool nullToAbsent) {
    return KvStoreCompanion(
      key: Value(key),
      value: Value(value),
    );
  }

  factory KvStoreData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KvStoreData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  KvStoreData copyWith({String? key, String? value}) => KvStoreData(
        key: key ?? this.key,
        value: value ?? this.value,
      );
  KvStoreData copyWithCompanion(KvStoreCompanion data) {
    return KvStoreData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KvStoreData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KvStoreData &&
          other.key == this.key &&
          other.value == this.value);
}

class KvStoreCompanion extends UpdateCompanion<KvStoreData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const KvStoreCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KvStoreCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  })  : key = Value(key),
        value = Value(value);
  static Insertable<KvStoreData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KvStoreCompanion copyWith(
      {Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return KvStoreCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KvStoreCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GraphCacheTable extends GraphCache
    with TableInfo<$GraphCacheTable, GraphCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GraphCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cityIdMeta = const VerificationMeta('cityId');
  @override
  late final GeneratedColumn<String> cityId = GeneratedColumn<String>(
      'city_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _graphVersionMeta =
      const VerificationMeta('graphVersion');
  @override
  late final GeneratedColumn<String> graphVersion = GeneratedColumn<String>(
      'graph_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fetchedAtMeta =
      const VerificationMeta('fetchedAt');
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
      'fetched_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [cityId, graphVersion, payloadJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'graph_cache';
  @override
  VerificationContext validateIntegrity(Insertable<GraphCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('city_id')) {
      context.handle(_cityIdMeta,
          cityId.isAcceptableOrUnknown(data['city_id']!, _cityIdMeta));
    } else if (isInserting) {
      context.missing(_cityIdMeta);
    }
    if (data.containsKey('graph_version')) {
      context.handle(
          _graphVersionMeta,
          graphVersion.isAcceptableOrUnknown(
              data['graph_version']!, _graphVersionMeta));
    } else if (isInserting) {
      context.missing(_graphVersionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(_fetchedAtMeta,
          fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta));
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cityId};
  @override
  GraphCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GraphCacheData(
      cityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city_id'])!,
      graphVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}graph_version'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      fetchedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}fetched_at'])!,
    );
  }

  @override
  $GraphCacheTable createAlias(String alias) {
    return $GraphCacheTable(attachedDatabase, alias);
  }
}

class GraphCacheData extends DataClass implements Insertable<GraphCacheData> {
  final String cityId;
  final String graphVersion;
  final String payloadJson;
  final DateTime fetchedAt;
  const GraphCacheData(
      {required this.cityId,
      required this.graphVersion,
      required this.payloadJson,
      required this.fetchedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['city_id'] = Variable<String>(cityId);
    map['graph_version'] = Variable<String>(graphVersion);
    map['payload_json'] = Variable<String>(payloadJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  GraphCacheCompanion toCompanion(bool nullToAbsent) {
    return GraphCacheCompanion(
      cityId: Value(cityId),
      graphVersion: Value(graphVersion),
      payloadJson: Value(payloadJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory GraphCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GraphCacheData(
      cityId: serializer.fromJson<String>(json['cityId']),
      graphVersion: serializer.fromJson<String>(json['graphVersion']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cityId': serializer.toJson<String>(cityId),
      'graphVersion': serializer.toJson<String>(graphVersion),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  GraphCacheData copyWith(
          {String? cityId,
          String? graphVersion,
          String? payloadJson,
          DateTime? fetchedAt}) =>
      GraphCacheData(
        cityId: cityId ?? this.cityId,
        graphVersion: graphVersion ?? this.graphVersion,
        payloadJson: payloadJson ?? this.payloadJson,
        fetchedAt: fetchedAt ?? this.fetchedAt,
      );
  GraphCacheData copyWithCompanion(GraphCacheCompanion data) {
    return GraphCacheData(
      cityId: data.cityId.present ? data.cityId.value : this.cityId,
      graphVersion: data.graphVersion.present
          ? data.graphVersion.value
          : this.graphVersion,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GraphCacheData(')
          ..write('cityId: $cityId, ')
          ..write('graphVersion: $graphVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cityId, graphVersion, payloadJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GraphCacheData &&
          other.cityId == this.cityId &&
          other.graphVersion == this.graphVersion &&
          other.payloadJson == this.payloadJson &&
          other.fetchedAt == this.fetchedAt);
}

class GraphCacheCompanion extends UpdateCompanion<GraphCacheData> {
  final Value<String> cityId;
  final Value<String> graphVersion;
  final Value<String> payloadJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const GraphCacheCompanion({
    this.cityId = const Value.absent(),
    this.graphVersion = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GraphCacheCompanion.insert({
    required String cityId,
    required String graphVersion,
    required String payloadJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  })  : cityId = Value(cityId),
        graphVersion = Value(graphVersion),
        payloadJson = Value(payloadJson),
        fetchedAt = Value(fetchedAt);
  static Insertable<GraphCacheData> custom({
    Expression<String>? cityId,
    Expression<String>? graphVersion,
    Expression<String>? payloadJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cityId != null) 'city_id': cityId,
      if (graphVersion != null) 'graph_version': graphVersion,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GraphCacheCompanion copyWith(
      {Value<String>? cityId,
      Value<String>? graphVersion,
      Value<String>? payloadJson,
      Value<DateTime>? fetchedAt,
      Value<int>? rowid}) {
    return GraphCacheCompanion(
      cityId: cityId ?? this.cityId,
      graphVersion: graphVersion ?? this.graphVersion,
      payloadJson: payloadJson ?? this.payloadJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cityId.present) {
      map['city_id'] = Variable<String>(cityId.value);
    }
    if (graphVersion.present) {
      map['graph_version'] = Variable<String>(graphVersion.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GraphCacheCompanion(')
          ..write('cityId: $cityId, ')
          ..write('graphVersion: $graphVersion, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanCacheTable extends PlanCache
    with TableInfo<$PlanCacheTable, PlanCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _cacheKeyMeta =
      const VerificationMeta('cacheKey');
  @override
  late final GeneratedColumn<String> cacheKey = GeneratedColumn<String>(
      'cache_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [cacheKey, payloadJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_cache';
  @override
  VerificationContext validateIntegrity(Insertable<PlanCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('cache_key')) {
      context.handle(_cacheKeyMeta,
          cacheKey.isAcceptableOrUnknown(data['cache_key']!, _cacheKeyMeta));
    } else if (isInserting) {
      context.missing(_cacheKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {cacheKey};
  @override
  PlanCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanCacheData(
      cacheKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}cache_key'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $PlanCacheTable createAlias(String alias) {
    return $PlanCacheTable(attachedDatabase, alias);
  }
}

class PlanCacheData extends DataClass implements Insertable<PlanCacheData> {
  final String cacheKey;
  final String payloadJson;
  final DateTime cachedAt;
  const PlanCacheData(
      {required this.cacheKey,
      required this.payloadJson,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['cache_key'] = Variable<String>(cacheKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  PlanCacheCompanion toCompanion(bool nullToAbsent) {
    return PlanCacheCompanion(
      cacheKey: Value(cacheKey),
      payloadJson: Value(payloadJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory PlanCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanCacheData(
      cacheKey: serializer.fromJson<String>(json['cacheKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'cacheKey': serializer.toJson<String>(cacheKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  PlanCacheData copyWith(
          {String? cacheKey, String? payloadJson, DateTime? cachedAt}) =>
      PlanCacheData(
        cacheKey: cacheKey ?? this.cacheKey,
        payloadJson: payloadJson ?? this.payloadJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  PlanCacheData copyWithCompanion(PlanCacheCompanion data) {
    return PlanCacheData(
      cacheKey: data.cacheKey.present ? data.cacheKey.value : this.cacheKey,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanCacheData(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(cacheKey, payloadJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanCacheData &&
          other.cacheKey == this.cacheKey &&
          other.payloadJson == this.payloadJson &&
          other.cachedAt == this.cachedAt);
}

class PlanCacheCompanion extends UpdateCompanion<PlanCacheData> {
  final Value<String> cacheKey;
  final Value<String> payloadJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const PlanCacheCompanion({
    this.cacheKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanCacheCompanion.insert({
    required String cacheKey,
    required String payloadJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : cacheKey = Value(cacheKey),
        payloadJson = Value(payloadJson),
        cachedAt = Value(cachedAt);
  static Insertable<PlanCacheData> custom({
    Expression<String>? cacheKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (cacheKey != null) 'cache_key': cacheKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanCacheCompanion copyWith(
      {Value<String>? cacheKey,
      Value<String>? payloadJson,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return PlanCacheCompanion(
      cacheKey: cacheKey ?? this.cacheKey,
      payloadJson: payloadJson ?? this.payloadJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (cacheKey.present) {
      map['cache_key'] = Variable<String>(cacheKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanCacheCompanion(')
          ..write('cacheKey: $cacheKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TripCacheTable extends TripCache
    with TableInfo<$TripCacheTable, TripCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TripCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [tripId, payloadJson, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_cache';
  @override
  VerificationContext validateIntegrity(Insertable<TripCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  TripCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripCacheData(
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $TripCacheTable createAlias(String alias) {
    return $TripCacheTable(attachedDatabase, alias);
  }
}

class TripCacheData extends DataClass implements Insertable<TripCacheData> {
  final String tripId;
  final String payloadJson;
  final DateTime updatedAt;
  const TripCacheData(
      {required this.tripId,
      required this.payloadJson,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TripCacheCompanion toCompanion(bool nullToAbsent) {
    return TripCacheCompanion(
      tripId: Value(tripId),
      payloadJson: Value(payloadJson),
      updatedAt: Value(updatedAt),
    );
  }

  factory TripCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripCacheData(
      tripId: serializer.fromJson<String>(json['tripId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  TripCacheData copyWith(
          {String? tripId, String? payloadJson, DateTime? updatedAt}) =>
      TripCacheData(
        tripId: tripId ?? this.tripId,
        payloadJson: payloadJson ?? this.payloadJson,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  TripCacheData copyWithCompanion(TripCacheCompanion data) {
    return TripCacheData(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripCacheData(')
          ..write('tripId: $tripId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, payloadJson, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripCacheData &&
          other.tripId == this.tripId &&
          other.payloadJson == this.payloadJson &&
          other.updatedAt == this.updatedAt);
}

class TripCacheCompanion extends UpdateCompanion<TripCacheData> {
  final Value<String> tripId;
  final Value<String> payloadJson;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TripCacheCompanion({
    this.tripId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripCacheCompanion.insert({
    required String tripId,
    required String payloadJson,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  })  : tripId = Value(tripId),
        payloadJson = Value(payloadJson),
        updatedAt = Value(updatedAt);
  static Insertable<TripCacheData> custom({
    Expression<String>? tripId,
    Expression<String>? payloadJson,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripCacheCompanion copyWith(
      {Value<String>? tripId,
      Value<String>? payloadJson,
      Value<DateTime>? updatedAt,
      Value<int>? rowid}) {
    return TripCacheCompanion(
      tripId: tripId ?? this.tripId,
      payloadJson: payloadJson ?? this.payloadJson,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripCacheCompanion(')
          ..write('tripId: $tripId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StepsCacheTable extends StepsCache
    with TableInfo<$StepsCacheTable, StepsCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StepsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
      'trip_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [tripId, payloadJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'steps_cache';
  @override
  VerificationContext validateIntegrity(Insertable<StepsCacheData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta,
          tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  StepsCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StepsCacheData(
      tripId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}trip_id'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $StepsCacheTable createAlias(String alias) {
    return $StepsCacheTable(attachedDatabase, alias);
  }
}

class StepsCacheData extends DataClass implements Insertable<StepsCacheData> {
  final String tripId;
  final String payloadJson;
  final DateTime cachedAt;
  const StepsCacheData(
      {required this.tripId,
      required this.payloadJson,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['payload_json'] = Variable<String>(payloadJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  StepsCacheCompanion toCompanion(bool nullToAbsent) {
    return StepsCacheCompanion(
      tripId: Value(tripId),
      payloadJson: Value(payloadJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory StepsCacheData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StepsCacheData(
      tripId: serializer.fromJson<String>(json['tripId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  StepsCacheData copyWith(
          {String? tripId, String? payloadJson, DateTime? cachedAt}) =>
      StepsCacheData(
        tripId: tripId ?? this.tripId,
        payloadJson: payloadJson ?? this.payloadJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  StepsCacheData copyWithCompanion(StepsCacheCompanion data) {
    return StepsCacheData(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StepsCacheData(')
          ..write('tripId: $tripId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, payloadJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StepsCacheData &&
          other.tripId == this.tripId &&
          other.payloadJson == this.payloadJson &&
          other.cachedAt == this.cachedAt);
}

class StepsCacheCompanion extends UpdateCompanion<StepsCacheData> {
  final Value<String> tripId;
  final Value<String> payloadJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const StepsCacheCompanion({
    this.tripId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StepsCacheCompanion.insert({
    required String tripId,
    required String payloadJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : tripId = Value(tripId),
        payloadJson = Value(payloadJson),
        cachedAt = Value(cachedAt);
  static Insertable<StepsCacheData> custom({
    Expression<String>? tripId,
    Expression<String>? payloadJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StepsCacheCompanion copyWith(
      {Value<String>? tripId,
      Value<String>? payloadJson,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return StepsCacheCompanion(
      tripId: tripId ?? this.tripId,
      payloadJson: payloadJson ?? this.payloadJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StepsCacheCompanion(')
          ..write('tripId: $tripId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingActionsTable extends PendingActions
    with TableInfo<$PendingActionsTable, PendingAction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _lastAttemptAtMeta =
      const VerificationMeta('lastAttemptAt');
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>('last_attempt_at', aliasedName, true,
          type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, type, payloadJson, createdAt, attempts, lastAttemptAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_actions';
  @override
  VerificationContext validateIntegrity(Insertable<PendingAction> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
          _lastAttemptAtMeta,
          lastAttemptAt.isAcceptableOrUnknown(
              data['last_attempt_at']!, _lastAttemptAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingAction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingAction(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}last_attempt_at']),
    );
  }

  @override
  $PendingActionsTable createAlias(String alias) {
    return $PendingActionsTable(attachedDatabase, alias);
  }
}

class PendingAction extends DataClass implements Insertable<PendingAction> {
  final String id;
  final String type;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastAttemptAt;
  const PendingAction(
      {required this.id,
      required this.type,
      required this.payloadJson,
      required this.createdAt,
      required this.attempts,
      this.lastAttemptAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['type'] = Variable<String>(type);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  PendingActionsCompanion toCompanion(bool nullToAbsent) {
    return PendingActionsCompanion(
      id: Value(id),
      type: Value(type),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory PendingAction.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingAction(
      id: serializer.fromJson<String>(json['id']),
      type: serializer.fromJson<String>(json['type']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'type': serializer.toJson<String>(type),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  PendingAction copyWith(
          {String? id,
          String? type,
          String? payloadJson,
          DateTime? createdAt,
          int? attempts,
          Value<DateTime?> lastAttemptAt = const Value.absent()}) =>
      PendingAction(
        id: id ?? this.id,
        type: type ?? this.type,
        payloadJson: payloadJson ?? this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
        lastAttemptAt:
            lastAttemptAt.present ? lastAttemptAt.value : this.lastAttemptAt,
      );
  PendingAction copyWithCompanion(PendingActionsCompanion data) {
    return PendingAction(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingAction(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, payloadJson, createdAt, attempts, lastAttemptAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAction &&
          other.id == this.id &&
          other.type == this.type &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class PendingActionsCompanion extends UpdateCompanion<PendingAction> {
  final Value<String> id;
  final Value<String> type;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const PendingActionsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PendingActionsCompanion.insert({
    required String id,
    required String type,
    required String payloadJson,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        type = Value(type),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<PendingAction> custom({
    Expression<String>? id,
    Expression<String>? type,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PendingActionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? type,
      Value<String>? payloadJson,
      Value<DateTime>? createdAt,
      Value<int>? attempts,
      Value<DateTime?>? lastAttemptAt,
      Value<int>? rowid}) {
    return PendingActionsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingActionsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AlongDatabase extends GeneratedDatabase {
  _$AlongDatabase(QueryExecutor e) : super(e);
  $AlongDatabaseManager get managers => $AlongDatabaseManager(this);
  late final $KvStoreTable kvStore = $KvStoreTable(this);
  late final $GraphCacheTable graphCache = $GraphCacheTable(this);
  late final $PlanCacheTable planCache = $PlanCacheTable(this);
  late final $TripCacheTable tripCache = $TripCacheTable(this);
  late final $StepsCacheTable stepsCache = $StepsCacheTable(this);
  late final $PendingActionsTable pendingActions = $PendingActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [kvStore, graphCache, planCache, tripCache, stepsCache, pendingActions];
}

typedef $$KvStoreTableCreateCompanionBuilder = KvStoreCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$KvStoreTableUpdateCompanionBuilder = KvStoreCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$KvStoreTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $KvStoreTable> {
  $$KvStoreTableFilterComposer(super.$state);
  ColumnFilters<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$KvStoreTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $KvStoreTable> {
  $$KvStoreTableOrderingComposer(super.$state);
  ColumnOrderings<String> get key => $state.composableBuilder(
      column: $state.table.key,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get value => $state.composableBuilder(
      column: $state.table.value,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$KvStoreTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $KvStoreTable,
    KvStoreData,
    $$KvStoreTableFilterComposer,
    $$KvStoreTableOrderingComposer,
    $$KvStoreTableCreateCompanionBuilder,
    $$KvStoreTableUpdateCompanionBuilder,
    (KvStoreData, BaseReferences<_$AlongDatabase, $KvStoreTable, KvStoreData>),
    KvStoreData,
    PrefetchHooks Function()> {
  $$KvStoreTableTableManager(_$AlongDatabase db, $KvStoreTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$KvStoreTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$KvStoreTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              KvStoreCompanion(
            key: key,
            value: value,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) =>
              KvStoreCompanion.insert(
            key: key,
            value: value,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$KvStoreTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $KvStoreTable,
    KvStoreData,
    $$KvStoreTableFilterComposer,
    $$KvStoreTableOrderingComposer,
    $$KvStoreTableCreateCompanionBuilder,
    $$KvStoreTableUpdateCompanionBuilder,
    (KvStoreData, BaseReferences<_$AlongDatabase, $KvStoreTable, KvStoreData>),
    KvStoreData,
    PrefetchHooks Function()>;
typedef $$GraphCacheTableCreateCompanionBuilder = GraphCacheCompanion Function({
  required String cityId,
  required String graphVersion,
  required String payloadJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$GraphCacheTableUpdateCompanionBuilder = GraphCacheCompanion Function({
  Value<String> cityId,
  Value<String> graphVersion,
  Value<String> payloadJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$GraphCacheTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $GraphCacheTable> {
  $$GraphCacheTableFilterComposer(super.$state);
  ColumnFilters<String> get cityId => $state.composableBuilder(
      column: $state.table.cityId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get graphVersion => $state.composableBuilder(
      column: $state.table.graphVersion,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$GraphCacheTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $GraphCacheTable> {
  $$GraphCacheTableOrderingComposer(super.$state);
  ColumnOrderings<String> get cityId => $state.composableBuilder(
      column: $state.table.cityId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get graphVersion => $state.composableBuilder(
      column: $state.table.graphVersion,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get fetchedAt => $state.composableBuilder(
      column: $state.table.fetchedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$GraphCacheTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $GraphCacheTable,
    GraphCacheData,
    $$GraphCacheTableFilterComposer,
    $$GraphCacheTableOrderingComposer,
    $$GraphCacheTableCreateCompanionBuilder,
    $$GraphCacheTableUpdateCompanionBuilder,
    (
      GraphCacheData,
      BaseReferences<_$AlongDatabase, $GraphCacheTable, GraphCacheData>
    ),
    GraphCacheData,
    PrefetchHooks Function()> {
  $$GraphCacheTableTableManager(_$AlongDatabase db, $GraphCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$GraphCacheTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$GraphCacheTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> cityId = const Value.absent(),
            Value<String> graphVersion = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> fetchedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphCacheCompanion(
            cityId: cityId,
            graphVersion: graphVersion,
            payloadJson: payloadJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cityId,
            required String graphVersion,
            required String payloadJson,
            required DateTime fetchedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              GraphCacheCompanion.insert(
            cityId: cityId,
            graphVersion: graphVersion,
            payloadJson: payloadJson,
            fetchedAt: fetchedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GraphCacheTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $GraphCacheTable,
    GraphCacheData,
    $$GraphCacheTableFilterComposer,
    $$GraphCacheTableOrderingComposer,
    $$GraphCacheTableCreateCompanionBuilder,
    $$GraphCacheTableUpdateCompanionBuilder,
    (
      GraphCacheData,
      BaseReferences<_$AlongDatabase, $GraphCacheTable, GraphCacheData>
    ),
    GraphCacheData,
    PrefetchHooks Function()>;
typedef $$PlanCacheTableCreateCompanionBuilder = PlanCacheCompanion Function({
  required String cacheKey,
  required String payloadJson,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$PlanCacheTableUpdateCompanionBuilder = PlanCacheCompanion Function({
  Value<String> cacheKey,
  Value<String> payloadJson,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$PlanCacheTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $PlanCacheTable> {
  $$PlanCacheTableFilterComposer(super.$state);
  ColumnFilters<String> get cacheKey => $state.composableBuilder(
      column: $state.table.cacheKey,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PlanCacheTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $PlanCacheTable> {
  $$PlanCacheTableOrderingComposer(super.$state);
  ColumnOrderings<String> get cacheKey => $state.composableBuilder(
      column: $state.table.cacheKey,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$PlanCacheTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $PlanCacheTable,
    PlanCacheData,
    $$PlanCacheTableFilterComposer,
    $$PlanCacheTableOrderingComposer,
    $$PlanCacheTableCreateCompanionBuilder,
    $$PlanCacheTableUpdateCompanionBuilder,
    (
      PlanCacheData,
      BaseReferences<_$AlongDatabase, $PlanCacheTable, PlanCacheData>
    ),
    PlanCacheData,
    PrefetchHooks Function()> {
  $$PlanCacheTableTableManager(_$AlongDatabase db, $PlanCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PlanCacheTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PlanCacheTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> cacheKey = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanCacheCompanion(
            cacheKey: cacheKey,
            payloadJson: payloadJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String cacheKey,
            required String payloadJson,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              PlanCacheCompanion.insert(
            cacheKey: cacheKey,
            payloadJson: payloadJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PlanCacheTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $PlanCacheTable,
    PlanCacheData,
    $$PlanCacheTableFilterComposer,
    $$PlanCacheTableOrderingComposer,
    $$PlanCacheTableCreateCompanionBuilder,
    $$PlanCacheTableUpdateCompanionBuilder,
    (
      PlanCacheData,
      BaseReferences<_$AlongDatabase, $PlanCacheTable, PlanCacheData>
    ),
    PlanCacheData,
    PrefetchHooks Function()>;
typedef $$TripCacheTableCreateCompanionBuilder = TripCacheCompanion Function({
  required String tripId,
  required String payloadJson,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$TripCacheTableUpdateCompanionBuilder = TripCacheCompanion Function({
  Value<String> tripId,
  Value<String> payloadJson,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$TripCacheTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $TripCacheTable> {
  $$TripCacheTableFilterComposer(super.$state);
  ColumnFilters<String> get tripId => $state.composableBuilder(
      column: $state.table.tripId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$TripCacheTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $TripCacheTable> {
  $$TripCacheTableOrderingComposer(super.$state);
  ColumnOrderings<String> get tripId => $state.composableBuilder(
      column: $state.table.tripId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get updatedAt => $state.composableBuilder(
      column: $state.table.updatedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$TripCacheTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $TripCacheTable,
    TripCacheData,
    $$TripCacheTableFilterComposer,
    $$TripCacheTableOrderingComposer,
    $$TripCacheTableCreateCompanionBuilder,
    $$TripCacheTableUpdateCompanionBuilder,
    (
      TripCacheData,
      BaseReferences<_$AlongDatabase, $TripCacheTable, TripCacheData>
    ),
    TripCacheData,
    PrefetchHooks Function()> {
  $$TripCacheTableTableManager(_$AlongDatabase db, $TripCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$TripCacheTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$TripCacheTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> tripId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              TripCacheCompanion(
            tripId: tripId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String tripId,
            required String payloadJson,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              TripCacheCompanion.insert(
            tripId: tripId,
            payloadJson: payloadJson,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TripCacheTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $TripCacheTable,
    TripCacheData,
    $$TripCacheTableFilterComposer,
    $$TripCacheTableOrderingComposer,
    $$TripCacheTableCreateCompanionBuilder,
    $$TripCacheTableUpdateCompanionBuilder,
    (
      TripCacheData,
      BaseReferences<_$AlongDatabase, $TripCacheTable, TripCacheData>
    ),
    TripCacheData,
    PrefetchHooks Function()>;
typedef $$StepsCacheTableCreateCompanionBuilder = StepsCacheCompanion Function({
  required String tripId,
  required String payloadJson,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$StepsCacheTableUpdateCompanionBuilder = StepsCacheCompanion Function({
  Value<String> tripId,
  Value<String> payloadJson,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$StepsCacheTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $StepsCacheTable> {
  $$StepsCacheTableFilterComposer(super.$state);
  ColumnFilters<String> get tripId => $state.composableBuilder(
      column: $state.table.tripId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$StepsCacheTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $StepsCacheTable> {
  $$StepsCacheTableOrderingComposer(super.$state);
  ColumnOrderings<String> get tripId => $state.composableBuilder(
      column: $state.table.tripId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get cachedAt => $state.composableBuilder(
      column: $state.table.cachedAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$StepsCacheTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $StepsCacheTable,
    StepsCacheData,
    $$StepsCacheTableFilterComposer,
    $$StepsCacheTableOrderingComposer,
    $$StepsCacheTableCreateCompanionBuilder,
    $$StepsCacheTableUpdateCompanionBuilder,
    (
      StepsCacheData,
      BaseReferences<_$AlongDatabase, $StepsCacheTable, StepsCacheData>
    ),
    StepsCacheData,
    PrefetchHooks Function()> {
  $$StepsCacheTableTableManager(_$AlongDatabase db, $StepsCacheTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$StepsCacheTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$StepsCacheTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> tripId = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              StepsCacheCompanion(
            tripId: tripId,
            payloadJson: payloadJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String tripId,
            required String payloadJson,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              StepsCacheCompanion.insert(
            tripId: tripId,
            payloadJson: payloadJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$StepsCacheTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $StepsCacheTable,
    StepsCacheData,
    $$StepsCacheTableFilterComposer,
    $$StepsCacheTableOrderingComposer,
    $$StepsCacheTableCreateCompanionBuilder,
    $$StepsCacheTableUpdateCompanionBuilder,
    (
      StepsCacheData,
      BaseReferences<_$AlongDatabase, $StepsCacheTable, StepsCacheData>
    ),
    StepsCacheData,
    PrefetchHooks Function()>;
typedef $$PendingActionsTableCreateCompanionBuilder = PendingActionsCompanion
    Function({
  required String id,
  required String type,
  required String payloadJson,
  required DateTime createdAt,
  Value<int> attempts,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});
typedef $$PendingActionsTableUpdateCompanionBuilder = PendingActionsCompanion
    Function({
  Value<String> id,
  Value<String> type,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<int> attempts,
  Value<DateTime?> lastAttemptAt,
  Value<int> rowid,
});

class $$PendingActionsTableFilterComposer
    extends FilterComposer<_$AlongDatabase, $PendingActionsTable> {
  $$PendingActionsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$PendingActionsTableOrderingComposer
    extends OrderingComposer<_$AlongDatabase, $PendingActionsTable> {
  $$PendingActionsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get type => $state.composableBuilder(
      column: $state.table.type,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get payloadJson => $state.composableBuilder(
      column: $state.table.payloadJson,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get attempts => $state.composableBuilder(
      column: $state.table.attempts,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastAttemptAt => $state.composableBuilder(
      column: $state.table.lastAttemptAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$PendingActionsTableTableManager extends RootTableManager<
    _$AlongDatabase,
    $PendingActionsTable,
    PendingAction,
    $$PendingActionsTableFilterComposer,
    $$PendingActionsTableOrderingComposer,
    $$PendingActionsTableCreateCompanionBuilder,
    $$PendingActionsTableUpdateCompanionBuilder,
    (
      PendingAction,
      BaseReferences<_$AlongDatabase, $PendingActionsTable, PendingAction>
    ),
    PendingAction,
    PrefetchHooks Function()> {
  $$PendingActionsTableTableManager(
      _$AlongDatabase db, $PendingActionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$PendingActionsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$PendingActionsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingActionsCompanion(
            id: id,
            type: type,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attempts: attempts,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String type,
            required String payloadJson,
            required DateTime createdAt,
            Value<int> attempts = const Value.absent(),
            Value<DateTime?> lastAttemptAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PendingActionsCompanion.insert(
            id: id,
            type: type,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attempts: attempts,
            lastAttemptAt: lastAttemptAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingActionsTableProcessedTableManager = ProcessedTableManager<
    _$AlongDatabase,
    $PendingActionsTable,
    PendingAction,
    $$PendingActionsTableFilterComposer,
    $$PendingActionsTableOrderingComposer,
    $$PendingActionsTableCreateCompanionBuilder,
    $$PendingActionsTableUpdateCompanionBuilder,
    (
      PendingAction,
      BaseReferences<_$AlongDatabase, $PendingActionsTable, PendingAction>
    ),
    PendingAction,
    PrefetchHooks Function()>;

class $AlongDatabaseManager {
  final _$AlongDatabase _db;
  $AlongDatabaseManager(this._db);
  $$KvStoreTableTableManager get kvStore =>
      $$KvStoreTableTableManager(_db, _db.kvStore);
  $$GraphCacheTableTableManager get graphCache =>
      $$GraphCacheTableTableManager(_db, _db.graphCache);
  $$PlanCacheTableTableManager get planCache =>
      $$PlanCacheTableTableManager(_db, _db.planCache);
  $$TripCacheTableTableManager get tripCache =>
      $$TripCacheTableTableManager(_db, _db.tripCache);
  $$StepsCacheTableTableManager get stepsCache =>
      $$StepsCacheTableTableManager(_db, _db.stepsCache);
  $$PendingActionsTableTableManager get pendingActions =>
      $$PendingActionsTableTableManager(_db, _db.pendingActions);
}
