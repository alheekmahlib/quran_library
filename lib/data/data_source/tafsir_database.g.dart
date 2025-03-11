// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../quran.dart';

// ignore_for_file: type=lint
class $TafsirTableTable extends TafsirTable
    with drift.TableInfo<$TafsirTableTable, TafsirTableData> {
  @override
  final drift.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TafsirTableTable(this.attachedDatabase, [this._alias]);
  static const drift.VerificationMeta _idMeta =
      const drift.VerificationMeta('id');
  @override
  late final drift.GeneratedColumn<int> id = drift.GeneratedColumn<int>(
      'index', aliasedName, false,
      hasAutoIncrement: true,
      type: drift.DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: drift.GeneratedColumn.constraintIsAlways(
          'PRIMARY KEY AUTOINCREMENT'));
  static const drift.VerificationMeta _surahNumMeta =
      const drift.VerificationMeta('surahNum');
  @override
  late final drift.GeneratedColumn<int> surahNum = drift.GeneratedColumn<int>(
      'sura', aliasedName, false,
      type: drift.DriftSqlType.int, requiredDuringInsert: true);
  static const drift.VerificationMeta _ayahNumMeta =
      const drift.VerificationMeta('ayahNum');
  @override
  late final drift.GeneratedColumn<int> ayahNum = drift.GeneratedColumn<int>(
      'aya', aliasedName, false,
      type: drift.DriftSqlType.int, requiredDuringInsert: true);
  static const drift.VerificationMeta _tafsirTextMeta =
      const drift.VerificationMeta('tafsirText');
  @override
  late final drift.GeneratedColumn<String> tafsirText =
      drift.GeneratedColumn<String>('Text', aliasedName, false,
          type: drift.DriftSqlType.string, requiredDuringInsert: true);
  static const drift.VerificationMeta _pageNumMeta =
      const drift.VerificationMeta('pageNum');
  @override
  late final drift.GeneratedColumn<int> pageNum = drift.GeneratedColumn<int>(
      'PageNum', aliasedName, false,
      type: drift.DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<drift.GeneratedColumn> get $columns =>
      [id, surahNum, ayahNum, tafsirText, pageNum];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tafsir_table';
  @override
  drift.VerificationContext validateIntegrity(
      drift.Insertable<TafsirTableData> instance,
      {bool isInserting = false}) {
    final context = drift.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('index')) {
      context.handle(
          _idMeta, id.isAcceptableOrUnknown(data['index']!, _idMeta));
    }
    if (data.containsKey('sura')) {
      context.handle(_surahNumMeta,
          surahNum.isAcceptableOrUnknown(data['sura']!, _surahNumMeta));
    } else if (isInserting) {
      context.missing(_surahNumMeta);
    }
    if (data.containsKey('aya')) {
      context.handle(_ayahNumMeta,
          ayahNum.isAcceptableOrUnknown(data['aya']!, _ayahNumMeta));
    } else if (isInserting) {
      context.missing(_ayahNumMeta);
    }
    if (data.containsKey('Text')) {
      context.handle(_tafsirTextMeta,
          tafsirText.isAcceptableOrUnknown(data['Text']!, _tafsirTextMeta));
    } else if (isInserting) {
      context.missing(_tafsirTextMeta);
    }
    if (data.containsKey('PageNum')) {
      context.handle(_pageNumMeta,
          pageNum.isAcceptableOrUnknown(data['PageNum']!, _pageNumMeta));
    } else if (isInserting) {
      context.missing(_pageNumMeta);
    }
    return context;
  }

  @override
  Set<drift.GeneratedColumn> get $primaryKey => {id};
  @override
  TafsirTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TafsirTableData(
      id: attachedDatabase.typeMapping
          .read(drift.DriftSqlType.int, data['${effectivePrefix}index'])!,
      surahNum: attachedDatabase.typeMapping
          .read(drift.DriftSqlType.int, data['${effectivePrefix}sura'])!,
      ayahNum: attachedDatabase.typeMapping
          .read(drift.DriftSqlType.int, data['${effectivePrefix}aya'])!,
      tafsirText: attachedDatabase.typeMapping
          .read(drift.DriftSqlType.string, data['${effectivePrefix}Text'])!,
      pageNum: attachedDatabase.typeMapping
          .read(drift.DriftSqlType.int, data['${effectivePrefix}PageNum'])!,
    );
  }

  @override
  $TafsirTableTable createAlias(String alias) {
    return $TafsirTableTable(attachedDatabase, alias);
  }
}

class TafsirTableData extends drift.DataClass
    implements drift.Insertable<TafsirTableData> {
  final int id;
  final int surahNum;
  final int ayahNum;
  final String tafsirText;
  final int pageNum;
  const TafsirTableData(
      {required this.id,
      required this.surahNum,
      required this.ayahNum,
      required this.tafsirText,
      required this.pageNum});
  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    map['index'] = drift.Variable<int>(id);
    map['sura'] = drift.Variable<int>(surahNum);
    map['aya'] = drift.Variable<int>(ayahNum);
    map['Text'] = drift.Variable<String>(tafsirText);
    map['PageNum'] = drift.Variable<int>(pageNum);
    return map;
  }

  TafsirTableCompanion toCompanion(bool nullToAbsent) {
    return TafsirTableCompanion(
      id: drift.Value(id),
      surahNum: drift.Value(surahNum),
      ayahNum: drift.Value(ayahNum),
      tafsirText: drift.Value(tafsirText),
      pageNum: drift.Value(pageNum),
    );
  }

  factory TafsirTableData.fromJson(Map<String, dynamic> json,
      {drift.ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return TafsirTableData(
      id: serializer.fromJson<int>(json['id']),
      surahNum: serializer.fromJson<int>(json['surahNum']),
      ayahNum: serializer.fromJson<int>(json['ayahNum']),
      tafsirText: serializer.fromJson<String>(json['tafsirText']),
      pageNum: serializer.fromJson<int>(json['pageNum']),
    );
  }
  @override
  Map<String, dynamic> toJson({drift.ValueSerializer? serializer}) {
    serializer ??= drift.driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'surahNum': serializer.toJson<int>(surahNum),
      'ayahNum': serializer.toJson<int>(ayahNum),
      'tafsirText': serializer.toJson<String>(tafsirText),
      'pageNum': serializer.toJson<int>(pageNum),
    };
  }

  TafsirTableData copyWith(
          {int? id,
          int? surahNum,
          int? ayahNum,
          String? tafsirText,
          int? pageNum}) =>
      TafsirTableData(
        id: id ?? this.id,
        surahNum: surahNum ?? this.surahNum,
        ayahNum: ayahNum ?? this.ayahNum,
        tafsirText: tafsirText ?? this.tafsirText,
        pageNum: pageNum ?? this.pageNum,
      );
  TafsirTableData copyWithCompanion(TafsirTableCompanion data) {
    return TafsirTableData(
      id: data.id.present ? data.id.value : this.id,
      surahNum: data.surahNum.present ? data.surahNum.value : this.surahNum,
      ayahNum: data.ayahNum.present ? data.ayahNum.value : this.ayahNum,
      tafsirText:
          data.tafsirText.present ? data.tafsirText.value : this.tafsirText,
      pageNum: data.pageNum.present ? data.pageNum.value : this.pageNum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TafsirTableData(')
          ..write('id: $id, ')
          ..write('surahNum: $surahNum, ')
          ..write('ayahNum: $ayahNum, ')
          ..write('tafsirText: $tafsirText, ')
          ..write('pageNum: $pageNum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surahNum, ayahNum, tafsirText, pageNum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TafsirTableData &&
          other.id == this.id &&
          other.surahNum == this.surahNum &&
          other.ayahNum == this.ayahNum &&
          other.tafsirText == this.tafsirText &&
          other.pageNum == this.pageNum);
}

class TafsirTableCompanion extends drift.UpdateCompanion<TafsirTableData> {
  final drift.Value<int> id;
  final drift.Value<int> surahNum;
  final drift.Value<int> ayahNum;
  final drift.Value<String> tafsirText;
  final drift.Value<int> pageNum;
  const TafsirTableCompanion({
    this.id = const drift.Value.absent(),
    this.surahNum = const drift.Value.absent(),
    this.ayahNum = const drift.Value.absent(),
    this.tafsirText = const drift.Value.absent(),
    this.pageNum = const drift.Value.absent(),
  });
  TafsirTableCompanion.insert({
    this.id = const drift.Value.absent(),
    required int surahNum,
    required int ayahNum,
    required String tafsirText,
    required int pageNum,
  })  : surahNum = drift.Value(surahNum),
        ayahNum = drift.Value(ayahNum),
        tafsirText = drift.Value(tafsirText),
        pageNum = drift.Value(pageNum);
  static drift.Insertable<TafsirTableData> custom({
    drift.Expression<int>? id,
    drift.Expression<int>? surahNum,
    drift.Expression<int>? ayahNum,
    drift.Expression<String>? tafsirText,
    drift.Expression<int>? pageNum,
  }) {
    return drift.RawValuesInsertable({
      if (id != null) 'index': id,
      if (surahNum != null) 'sura': surahNum,
      if (ayahNum != null) 'aya': ayahNum,
      if (tafsirText != null) 'Text': tafsirText,
      if (pageNum != null) 'PageNum': pageNum,
    });
  }

  TafsirTableCompanion copyWith(
      {drift.Value<int>? id,
      drift.Value<int>? surahNum,
      drift.Value<int>? ayahNum,
      drift.Value<String>? tafsirText,
      drift.Value<int>? pageNum}) {
    return TafsirTableCompanion(
      id: id ?? this.id,
      surahNum: surahNum ?? this.surahNum,
      ayahNum: ayahNum ?? this.ayahNum,
      tafsirText: tafsirText ?? this.tafsirText,
      pageNum: pageNum ?? this.pageNum,
    );
  }

  @override
  Map<String, drift.Expression> toColumns(bool nullToAbsent) {
    final map = <String, drift.Expression>{};
    if (id.present) {
      map['index'] = drift.Variable<int>(id.value);
    }
    if (surahNum.present) {
      map['sura'] = drift.Variable<int>(surahNum.value);
    }
    if (ayahNum.present) {
      map['aya'] = drift.Variable<int>(ayahNum.value);
    }
    if (tafsirText.present) {
      map['Text'] = drift.Variable<String>(tafsirText.value);
    }
    if (pageNum.present) {
      map['PageNum'] = drift.Variable<int>(pageNum.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TafsirTableCompanion(')
          ..write('id: $id, ')
          ..write('surahNum: $surahNum, ')
          ..write('ayahNum: $ayahNum, ')
          ..write('tafsirText: $tafsirText, ')
          ..write('pageNum: $pageNum')
          ..write(')'))
        .toString();
  }
}

abstract class _$TafsirDatabase extends drift.GeneratedDatabase {
  _$TafsirDatabase(drift.QueryExecutor e) : super(e);
  $TafsirDatabaseManager get managers => $TafsirDatabaseManager(this);
  late final $TafsirTableTable tafsirTable = $TafsirTableTable(this);
  @override
  Iterable<drift.TableInfo<drift.Table, Object?>> get allTables =>
      allSchemaEntities.whereType<drift.TableInfo<drift.Table, Object?>>();
  @override
  List<drift.DatabaseSchemaEntity> get allSchemaEntities => [tafsirTable];
}

typedef $$TafsirTableTableCreateCompanionBuilder = TafsirTableCompanion
    Function({
  drift.Value<int> id,
  required int surahNum,
  required int ayahNum,
  required String tafsirText,
  required int pageNum,
});
typedef $$TafsirTableTableUpdateCompanionBuilder = TafsirTableCompanion
    Function({
  drift.Value<int> id,
  drift.Value<int> surahNum,
  drift.Value<int> ayahNum,
  drift.Value<String> tafsirText,
  drift.Value<int> pageNum,
});

class $$TafsirTableTableFilterComposer
    extends drift.Composer<_$TafsirDatabase, $TafsirTableTable> {
  $$TafsirTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => drift.ColumnFilters(column));

  drift.ColumnFilters<int> get surahNum => $composableBuilder(
      column: $table.surahNum,
      builder: (column) => drift.ColumnFilters(column));

  drift.ColumnFilters<int> get ayahNum => $composableBuilder(
      column: $table.ayahNum, builder: (column) => drift.ColumnFilters(column));

  drift.ColumnFilters<String> get tafsirText => $composableBuilder(
      column: $table.tafsirText,
      builder: (column) => drift.ColumnFilters(column));

  drift.ColumnFilters<int> get pageNum => $composableBuilder(
      column: $table.pageNum, builder: (column) => drift.ColumnFilters(column));
}

class $$TafsirTableTableOrderingComposer
    extends drift.Composer<_$TafsirDatabase, $TafsirTableTable> {
  $$TafsirTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => drift.ColumnOrderings(column));

  drift.ColumnOrderings<int> get surahNum => $composableBuilder(
      column: $table.surahNum,
      builder: (column) => drift.ColumnOrderings(column));

  drift.ColumnOrderings<int> get ayahNum => $composableBuilder(
      column: $table.ayahNum,
      builder: (column) => drift.ColumnOrderings(column));

  drift.ColumnOrderings<String> get tafsirText => $composableBuilder(
      column: $table.tafsirText,
      builder: (column) => drift.ColumnOrderings(column));

  drift.ColumnOrderings<int> get pageNum => $composableBuilder(
      column: $table.pageNum,
      builder: (column) => drift.ColumnOrderings(column));
}

class $$TafsirTableTableAnnotationComposer
    extends drift.Composer<_$TafsirDatabase, $TafsirTableTable> {
  $$TafsirTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  drift.GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  drift.GeneratedColumn<int> get surahNum =>
      $composableBuilder(column: $table.surahNum, builder: (column) => column);

  drift.GeneratedColumn<int> get ayahNum =>
      $composableBuilder(column: $table.ayahNum, builder: (column) => column);

  drift.GeneratedColumn<String> get tafsirText => $composableBuilder(
      column: $table.tafsirText, builder: (column) => column);

  drift.GeneratedColumn<int> get pageNum =>
      $composableBuilder(column: $table.pageNum, builder: (column) => column);
}

class $$TafsirTableTableTableManager extends drift.RootTableManager<
    _$TafsirDatabase,
    $TafsirTableTable,
    TafsirTableData,
    $$TafsirTableTableFilterComposer,
    $$TafsirTableTableOrderingComposer,
    $$TafsirTableTableAnnotationComposer,
    $$TafsirTableTableCreateCompanionBuilder,
    $$TafsirTableTableUpdateCompanionBuilder,
    (
      TafsirTableData,
      drift.BaseReferences<_$TafsirDatabase, $TafsirTableTable, TafsirTableData>
    ),
    TafsirTableData,
    drift.PrefetchHooks Function()> {
  $$TafsirTableTableTableManager(_$TafsirDatabase db, $TafsirTableTable table)
      : super(drift.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TafsirTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TafsirTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TafsirTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            drift.Value<int> id = const drift.Value.absent(),
            drift.Value<int> surahNum = const drift.Value.absent(),
            drift.Value<int> ayahNum = const drift.Value.absent(),
            drift.Value<String> tafsirText = const drift.Value.absent(),
            drift.Value<int> pageNum = const drift.Value.absent(),
          }) =>
              TafsirTableCompanion(
            id: id,
            surahNum: surahNum,
            ayahNum: ayahNum,
            tafsirText: tafsirText,
            pageNum: pageNum,
          ),
          createCompanionCallback: ({
            drift.Value<int> id = const drift.Value.absent(),
            required int surahNum,
            required int ayahNum,
            required String tafsirText,
            required int pageNum,
          }) =>
              TafsirTableCompanion.insert(
            id: id,
            surahNum: surahNum,
            ayahNum: ayahNum,
            tafsirText: tafsirText,
            pageNum: pageNum,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), drift.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TafsirTableTableProcessedTableManager = drift.ProcessedTableManager<
    _$TafsirDatabase,
    $TafsirTableTable,
    TafsirTableData,
    $$TafsirTableTableFilterComposer,
    $$TafsirTableTableOrderingComposer,
    $$TafsirTableTableAnnotationComposer,
    $$TafsirTableTableCreateCompanionBuilder,
    $$TafsirTableTableUpdateCompanionBuilder,
    (
      TafsirTableData,
      drift.BaseReferences<_$TafsirDatabase, $TafsirTableTable, TafsirTableData>
    ),
    TafsirTableData,
    drift.PrefetchHooks Function()>;

class $TafsirDatabaseManager {
  final _$TafsirDatabase _db;
  $TafsirDatabaseManager(this._db);
  $$TafsirTableTableTableManager get tafsirTable =>
      $$TafsirTableTableTableManager(_db, _db.tafsirTable);
}
