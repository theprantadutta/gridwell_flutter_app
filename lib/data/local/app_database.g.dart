// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PuzzleProgressTable extends PuzzleProgress
    with TableInfo<$PuzzleProgressTable, PuzzleProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PuzzleProgressTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setVersionMeta = const VerificationMeta(
    'setVersion',
  );
  @override
  late final GeneratedColumn<int> setVersion = GeneratedColumn<int>(
    'set_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isSolvedMeta = const VerificationMeta(
    'isSolved',
  );
  @override
  late final GeneratedColumn<bool> isSolved = GeneratedColumn<bool>(
    'is_solved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_solved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _bestTimeMsMeta = const VerificationMeta(
    'bestTimeMs',
  );
  @override
  late final GeneratedColumn<int> bestTimeMs = GeneratedColumn<int>(
    'best_time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solvedAtMeta = const VerificationMeta(
    'solvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> solvedAt = GeneratedColumn<DateTime>(
    'solved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPlayedAtMeta = const VerificationMeta(
    'lastPlayedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPlayedAt = GeneratedColumn<DateTime>(
    'last_played_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solveCountMeta = const VerificationMeta(
    'solveCount',
  );
  @override
  late final GeneratedColumn<int> solveCount = GeneratedColumn<int>(
    'solve_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _solvedWithoutHintsMeta =
      const VerificationMeta('solvedWithoutHints');
  @override
  late final GeneratedColumn<bool> solvedWithoutHints = GeneratedColumn<bool>(
    'solved_without_hints',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solved_without_hints" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    setVersion,
    isSolved,
    bestTimeMs,
    solvedAt,
    lastPlayedAt,
    solveCount,
    solvedWithoutHints,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'puzzle_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<PuzzleProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('set_version')) {
      context.handle(
        _setVersionMeta,
        setVersion.isAcceptableOrUnknown(data['set_version']!, _setVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_setVersionMeta);
    }
    if (data.containsKey('is_solved')) {
      context.handle(
        _isSolvedMeta,
        isSolved.isAcceptableOrUnknown(data['is_solved']!, _isSolvedMeta),
      );
    }
    if (data.containsKey('best_time_ms')) {
      context.handle(
        _bestTimeMsMeta,
        bestTimeMs.isAcceptableOrUnknown(
          data['best_time_ms']!,
          _bestTimeMsMeta,
        ),
      );
    }
    if (data.containsKey('solved_at')) {
      context.handle(
        _solvedAtMeta,
        solvedAt.isAcceptableOrUnknown(data['solved_at']!, _solvedAtMeta),
      );
    }
    if (data.containsKey('last_played_at')) {
      context.handle(
        _lastPlayedAtMeta,
        lastPlayedAt.isAcceptableOrUnknown(
          data['last_played_at']!,
          _lastPlayedAtMeta,
        ),
      );
    }
    if (data.containsKey('solve_count')) {
      context.handle(
        _solveCountMeta,
        solveCount.isAcceptableOrUnknown(data['solve_count']!, _solveCountMeta),
      );
    }
    if (data.containsKey('solved_without_hints')) {
      context.handle(
        _solvedWithoutHintsMeta,
        solvedWithoutHints.isAcceptableOrUnknown(
          data['solved_without_hints']!,
          _solvedWithoutHintsMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  PuzzleProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PuzzleProgressData(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      setVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_version'],
      )!,
      isSolved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_solved'],
      )!,
      bestTimeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}best_time_ms'],
      ),
      solvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}solved_at'],
      ),
      lastPlayedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_played_at'],
      ),
      solveCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}solve_count'],
      )!,
      solvedWithoutHints: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solved_without_hints'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $PuzzleProgressTable createAlias(String alias) {
    return $PuzzleProgressTable(attachedDatabase, alias);
  }
}

class PuzzleProgressData extends DataClass
    implements Insertable<PuzzleProgressData> {
  final String puzzleId;
  final int setVersion;
  final bool isSolved;
  final int? bestTimeMs;
  final DateTime? solvedAt;
  final DateTime? lastPlayedAt;
  final int solveCount;

  /// True once a solve with zero hints happened (for achievements).
  final bool solvedWithoutHints;
  final DateTime updatedAt;
  const PuzzleProgressData({
    required this.puzzleId,
    required this.setVersion,
    required this.isSolved,
    this.bestTimeMs,
    this.solvedAt,
    this.lastPlayedAt,
    required this.solveCount,
    required this.solvedWithoutHints,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['set_version'] = Variable<int>(setVersion);
    map['is_solved'] = Variable<bool>(isSolved);
    if (!nullToAbsent || bestTimeMs != null) {
      map['best_time_ms'] = Variable<int>(bestTimeMs);
    }
    if (!nullToAbsent || solvedAt != null) {
      map['solved_at'] = Variable<DateTime>(solvedAt);
    }
    if (!nullToAbsent || lastPlayedAt != null) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt);
    }
    map['solve_count'] = Variable<int>(solveCount);
    map['solved_without_hints'] = Variable<bool>(solvedWithoutHints);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PuzzleProgressCompanion toCompanion(bool nullToAbsent) {
    return PuzzleProgressCompanion(
      puzzleId: Value(puzzleId),
      setVersion: Value(setVersion),
      isSolved: Value(isSolved),
      bestTimeMs: bestTimeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(bestTimeMs),
      solvedAt: solvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(solvedAt),
      lastPlayedAt: lastPlayedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPlayedAt),
      solveCount: Value(solveCount),
      solvedWithoutHints: Value(solvedWithoutHints),
      updatedAt: Value(updatedAt),
    );
  }

  factory PuzzleProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PuzzleProgressData(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      setVersion: serializer.fromJson<int>(json['setVersion']),
      isSolved: serializer.fromJson<bool>(json['isSolved']),
      bestTimeMs: serializer.fromJson<int?>(json['bestTimeMs']),
      solvedAt: serializer.fromJson<DateTime?>(json['solvedAt']),
      lastPlayedAt: serializer.fromJson<DateTime?>(json['lastPlayedAt']),
      solveCount: serializer.fromJson<int>(json['solveCount']),
      solvedWithoutHints: serializer.fromJson<bool>(json['solvedWithoutHints']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'setVersion': serializer.toJson<int>(setVersion),
      'isSolved': serializer.toJson<bool>(isSolved),
      'bestTimeMs': serializer.toJson<int?>(bestTimeMs),
      'solvedAt': serializer.toJson<DateTime?>(solvedAt),
      'lastPlayedAt': serializer.toJson<DateTime?>(lastPlayedAt),
      'solveCount': serializer.toJson<int>(solveCount),
      'solvedWithoutHints': serializer.toJson<bool>(solvedWithoutHints),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PuzzleProgressData copyWith({
    String? puzzleId,
    int? setVersion,
    bool? isSolved,
    Value<int?> bestTimeMs = const Value.absent(),
    Value<DateTime?> solvedAt = const Value.absent(),
    Value<DateTime?> lastPlayedAt = const Value.absent(),
    int? solveCount,
    bool? solvedWithoutHints,
    DateTime? updatedAt,
  }) => PuzzleProgressData(
    puzzleId: puzzleId ?? this.puzzleId,
    setVersion: setVersion ?? this.setVersion,
    isSolved: isSolved ?? this.isSolved,
    bestTimeMs: bestTimeMs.present ? bestTimeMs.value : this.bestTimeMs,
    solvedAt: solvedAt.present ? solvedAt.value : this.solvedAt,
    lastPlayedAt: lastPlayedAt.present ? lastPlayedAt.value : this.lastPlayedAt,
    solveCount: solveCount ?? this.solveCount,
    solvedWithoutHints: solvedWithoutHints ?? this.solvedWithoutHints,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  PuzzleProgressData copyWithCompanion(PuzzleProgressCompanion data) {
    return PuzzleProgressData(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      setVersion: data.setVersion.present
          ? data.setVersion.value
          : this.setVersion,
      isSolved: data.isSolved.present ? data.isSolved.value : this.isSolved,
      bestTimeMs: data.bestTimeMs.present
          ? data.bestTimeMs.value
          : this.bestTimeMs,
      solvedAt: data.solvedAt.present ? data.solvedAt.value : this.solvedAt,
      lastPlayedAt: data.lastPlayedAt.present
          ? data.lastPlayedAt.value
          : this.lastPlayedAt,
      solveCount: data.solveCount.present
          ? data.solveCount.value
          : this.solveCount,
      solvedWithoutHints: data.solvedWithoutHints.present
          ? data.solvedWithoutHints.value
          : this.solvedWithoutHints,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PuzzleProgressData(')
          ..write('puzzleId: $puzzleId, ')
          ..write('setVersion: $setVersion, ')
          ..write('isSolved: $isSolved, ')
          ..write('bestTimeMs: $bestTimeMs, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('solveCount: $solveCount, ')
          ..write('solvedWithoutHints: $solvedWithoutHints, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    setVersion,
    isSolved,
    bestTimeMs,
    solvedAt,
    lastPlayedAt,
    solveCount,
    solvedWithoutHints,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PuzzleProgressData &&
          other.puzzleId == this.puzzleId &&
          other.setVersion == this.setVersion &&
          other.isSolved == this.isSolved &&
          other.bestTimeMs == this.bestTimeMs &&
          other.solvedAt == this.solvedAt &&
          other.lastPlayedAt == this.lastPlayedAt &&
          other.solveCount == this.solveCount &&
          other.solvedWithoutHints == this.solvedWithoutHints &&
          other.updatedAt == this.updatedAt);
}

class PuzzleProgressCompanion extends UpdateCompanion<PuzzleProgressData> {
  final Value<String> puzzleId;
  final Value<int> setVersion;
  final Value<bool> isSolved;
  final Value<int?> bestTimeMs;
  final Value<DateTime?> solvedAt;
  final Value<DateTime?> lastPlayedAt;
  final Value<int> solveCount;
  final Value<bool> solvedWithoutHints;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PuzzleProgressCompanion({
    this.puzzleId = const Value.absent(),
    this.setVersion = const Value.absent(),
    this.isSolved = const Value.absent(),
    this.bestTimeMs = const Value.absent(),
    this.solvedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.solveCount = const Value.absent(),
    this.solvedWithoutHints = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PuzzleProgressCompanion.insert({
    required String puzzleId,
    required int setVersion,
    this.isSolved = const Value.absent(),
    this.bestTimeMs = const Value.absent(),
    this.solvedAt = const Value.absent(),
    this.lastPlayedAt = const Value.absent(),
    this.solveCount = const Value.absent(),
    this.solvedWithoutHints = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       setVersion = Value(setVersion),
       updatedAt = Value(updatedAt);
  static Insertable<PuzzleProgressData> custom({
    Expression<String>? puzzleId,
    Expression<int>? setVersion,
    Expression<bool>? isSolved,
    Expression<int>? bestTimeMs,
    Expression<DateTime>? solvedAt,
    Expression<DateTime>? lastPlayedAt,
    Expression<int>? solveCount,
    Expression<bool>? solvedWithoutHints,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (setVersion != null) 'set_version': setVersion,
      if (isSolved != null) 'is_solved': isSolved,
      if (bestTimeMs != null) 'best_time_ms': bestTimeMs,
      if (solvedAt != null) 'solved_at': solvedAt,
      if (lastPlayedAt != null) 'last_played_at': lastPlayedAt,
      if (solveCount != null) 'solve_count': solveCount,
      if (solvedWithoutHints != null)
        'solved_without_hints': solvedWithoutHints,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PuzzleProgressCompanion copyWith({
    Value<String>? puzzleId,
    Value<int>? setVersion,
    Value<bool>? isSolved,
    Value<int?>? bestTimeMs,
    Value<DateTime?>? solvedAt,
    Value<DateTime?>? lastPlayedAt,
    Value<int>? solveCount,
    Value<bool>? solvedWithoutHints,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return PuzzleProgressCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      setVersion: setVersion ?? this.setVersion,
      isSolved: isSolved ?? this.isSolved,
      bestTimeMs: bestTimeMs ?? this.bestTimeMs,
      solvedAt: solvedAt ?? this.solvedAt,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      solveCount: solveCount ?? this.solveCount,
      solvedWithoutHints: solvedWithoutHints ?? this.solvedWithoutHints,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (setVersion.present) {
      map['set_version'] = Variable<int>(setVersion.value);
    }
    if (isSolved.present) {
      map['is_solved'] = Variable<bool>(isSolved.value);
    }
    if (bestTimeMs.present) {
      map['best_time_ms'] = Variable<int>(bestTimeMs.value);
    }
    if (solvedAt.present) {
      map['solved_at'] = Variable<DateTime>(solvedAt.value);
    }
    if (lastPlayedAt.present) {
      map['last_played_at'] = Variable<DateTime>(lastPlayedAt.value);
    }
    if (solveCount.present) {
      map['solve_count'] = Variable<int>(solveCount.value);
    }
    if (solvedWithoutHints.present) {
      map['solved_without_hints'] = Variable<bool>(solvedWithoutHints.value);
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
    return (StringBuffer('PuzzleProgressCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('setVersion: $setVersion, ')
          ..write('isSolved: $isSolved, ')
          ..write('bestTimeMs: $bestTimeMs, ')
          ..write('solvedAt: $solvedAt, ')
          ..write('lastPlayedAt: $lastPlayedAt, ')
          ..write('solveCount: $solveCount, ')
          ..write('solvedWithoutHints: $solvedWithoutHints, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BoardSavesTable extends BoardSaves
    with TableInfo<$BoardSavesTable, BoardSave> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BoardSavesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setVersionMeta = const VerificationMeta(
    'setVersion',
  );
  @override
  late final GeneratedColumn<int> setVersion = GeneratedColumn<int>(
    'set_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cellsMeta = const VerificationMeta('cells');
  @override
  late final GeneratedColumn<String> cells = GeneratedColumn<String>(
    'cells',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _elapsedMsMeta = const VerificationMeta(
    'elapsedMs',
  );
  @override
  late final GeneratedColumn<int> elapsedMs = GeneratedColumn<int>(
    'elapsed_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hintsUsedMeta = const VerificationMeta(
    'hintsUsed',
  );
  @override
  late final GeneratedColumn<int> hintsUsed = GeneratedColumn<int>(
    'hints_used',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _movesMeta = const VerificationMeta('moves');
  @override
  late final GeneratedColumn<int> moves = GeneratedColumn<int>(
    'moves',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<DateTime> savedAt = GeneratedColumn<DateTime>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    puzzleId,
    setVersion,
    cells,
    elapsedMs,
    hintsUsed,
    moves,
    savedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'board_saves';
  @override
  VerificationContext validateIntegrity(
    Insertable<BoardSave> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('set_version')) {
      context.handle(
        _setVersionMeta,
        setVersion.isAcceptableOrUnknown(data['set_version']!, _setVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_setVersionMeta);
    }
    if (data.containsKey('cells')) {
      context.handle(
        _cellsMeta,
        cells.isAcceptableOrUnknown(data['cells']!, _cellsMeta),
      );
    } else if (isInserting) {
      context.missing(_cellsMeta);
    }
    if (data.containsKey('elapsed_ms')) {
      context.handle(
        _elapsedMsMeta,
        elapsedMs.isAcceptableOrUnknown(data['elapsed_ms']!, _elapsedMsMeta),
      );
    } else if (isInserting) {
      context.missing(_elapsedMsMeta);
    }
    if (data.containsKey('hints_used')) {
      context.handle(
        _hintsUsedMeta,
        hintsUsed.isAcceptableOrUnknown(data['hints_used']!, _hintsUsedMeta),
      );
    }
    if (data.containsKey('moves')) {
      context.handle(
        _movesMeta,
        moves.isAcceptableOrUnknown(data['moves']!, _movesMeta),
      );
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {puzzleId};
  @override
  BoardSave map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BoardSave(
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      setVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}set_version'],
      )!,
      cells: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cells'],
      )!,
      elapsedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}elapsed_ms'],
      )!,
      hintsUsed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hints_used'],
      )!,
      moves: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moves'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $BoardSavesTable createAlias(String alias) {
    return $BoardSavesTable(attachedDatabase, alias);
  }
}

class BoardSave extends DataClass implements Insertable<BoardSave> {
  final String puzzleId;
  final int setVersion;

  /// One char per cell, row-major: `.` untouched, `#` filled, `x` crossed.
  final String cells;
  final int elapsedMs;
  final int hintsUsed;
  final int moves;
  final DateTime savedAt;
  const BoardSave({
    required this.puzzleId,
    required this.setVersion,
    required this.cells,
    required this.elapsedMs,
    required this.hintsUsed,
    required this.moves,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['set_version'] = Variable<int>(setVersion);
    map['cells'] = Variable<String>(cells);
    map['elapsed_ms'] = Variable<int>(elapsedMs);
    map['hints_used'] = Variable<int>(hintsUsed);
    map['moves'] = Variable<int>(moves);
    map['saved_at'] = Variable<DateTime>(savedAt);
    return map;
  }

  BoardSavesCompanion toCompanion(bool nullToAbsent) {
    return BoardSavesCompanion(
      puzzleId: Value(puzzleId),
      setVersion: Value(setVersion),
      cells: Value(cells),
      elapsedMs: Value(elapsedMs),
      hintsUsed: Value(hintsUsed),
      moves: Value(moves),
      savedAt: Value(savedAt),
    );
  }

  factory BoardSave.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BoardSave(
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      setVersion: serializer.fromJson<int>(json['setVersion']),
      cells: serializer.fromJson<String>(json['cells']),
      elapsedMs: serializer.fromJson<int>(json['elapsedMs']),
      hintsUsed: serializer.fromJson<int>(json['hintsUsed']),
      moves: serializer.fromJson<int>(json['moves']),
      savedAt: serializer.fromJson<DateTime>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'puzzleId': serializer.toJson<String>(puzzleId),
      'setVersion': serializer.toJson<int>(setVersion),
      'cells': serializer.toJson<String>(cells),
      'elapsedMs': serializer.toJson<int>(elapsedMs),
      'hintsUsed': serializer.toJson<int>(hintsUsed),
      'moves': serializer.toJson<int>(moves),
      'savedAt': serializer.toJson<DateTime>(savedAt),
    };
  }

  BoardSave copyWith({
    String? puzzleId,
    int? setVersion,
    String? cells,
    int? elapsedMs,
    int? hintsUsed,
    int? moves,
    DateTime? savedAt,
  }) => BoardSave(
    puzzleId: puzzleId ?? this.puzzleId,
    setVersion: setVersion ?? this.setVersion,
    cells: cells ?? this.cells,
    elapsedMs: elapsedMs ?? this.elapsedMs,
    hintsUsed: hintsUsed ?? this.hintsUsed,
    moves: moves ?? this.moves,
    savedAt: savedAt ?? this.savedAt,
  );
  BoardSave copyWithCompanion(BoardSavesCompanion data) {
    return BoardSave(
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      setVersion: data.setVersion.present
          ? data.setVersion.value
          : this.setVersion,
      cells: data.cells.present ? data.cells.value : this.cells,
      elapsedMs: data.elapsedMs.present ? data.elapsedMs.value : this.elapsedMs,
      hintsUsed: data.hintsUsed.present ? data.hintsUsed.value : this.hintsUsed,
      moves: data.moves.present ? data.moves.value : this.moves,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BoardSave(')
          ..write('puzzleId: $puzzleId, ')
          ..write('setVersion: $setVersion, ')
          ..write('cells: $cells, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('moves: $moves, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    puzzleId,
    setVersion,
    cells,
    elapsedMs,
    hintsUsed,
    moves,
    savedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BoardSave &&
          other.puzzleId == this.puzzleId &&
          other.setVersion == this.setVersion &&
          other.cells == this.cells &&
          other.elapsedMs == this.elapsedMs &&
          other.hintsUsed == this.hintsUsed &&
          other.moves == this.moves &&
          other.savedAt == this.savedAt);
}

class BoardSavesCompanion extends UpdateCompanion<BoardSave> {
  final Value<String> puzzleId;
  final Value<int> setVersion;
  final Value<String> cells;
  final Value<int> elapsedMs;
  final Value<int> hintsUsed;
  final Value<int> moves;
  final Value<DateTime> savedAt;
  final Value<int> rowid;
  const BoardSavesCompanion({
    this.puzzleId = const Value.absent(),
    this.setVersion = const Value.absent(),
    this.cells = const Value.absent(),
    this.elapsedMs = const Value.absent(),
    this.hintsUsed = const Value.absent(),
    this.moves = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BoardSavesCompanion.insert({
    required String puzzleId,
    required int setVersion,
    required String cells,
    required int elapsedMs,
    this.hintsUsed = const Value.absent(),
    this.moves = const Value.absent(),
    required DateTime savedAt,
    this.rowid = const Value.absent(),
  }) : puzzleId = Value(puzzleId),
       setVersion = Value(setVersion),
       cells = Value(cells),
       elapsedMs = Value(elapsedMs),
       savedAt = Value(savedAt);
  static Insertable<BoardSave> custom({
    Expression<String>? puzzleId,
    Expression<int>? setVersion,
    Expression<String>? cells,
    Expression<int>? elapsedMs,
    Expression<int>? hintsUsed,
    Expression<int>? moves,
    Expression<DateTime>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (setVersion != null) 'set_version': setVersion,
      if (cells != null) 'cells': cells,
      if (elapsedMs != null) 'elapsed_ms': elapsedMs,
      if (hintsUsed != null) 'hints_used': hintsUsed,
      if (moves != null) 'moves': moves,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BoardSavesCompanion copyWith({
    Value<String>? puzzleId,
    Value<int>? setVersion,
    Value<String>? cells,
    Value<int>? elapsedMs,
    Value<int>? hintsUsed,
    Value<int>? moves,
    Value<DateTime>? savedAt,
    Value<int>? rowid,
  }) {
    return BoardSavesCompanion(
      puzzleId: puzzleId ?? this.puzzleId,
      setVersion: setVersion ?? this.setVersion,
      cells: cells ?? this.cells,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      moves: moves ?? this.moves,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (setVersion.present) {
      map['set_version'] = Variable<int>(setVersion.value);
    }
    if (cells.present) {
      map['cells'] = Variable<String>(cells.value);
    }
    if (elapsedMs.present) {
      map['elapsed_ms'] = Variable<int>(elapsedMs.value);
    }
    if (hintsUsed.present) {
      map['hints_used'] = Variable<int>(hintsUsed.value);
    }
    if (moves.present) {
      map['moves'] = Variable<int>(moves.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<DateTime>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BoardSavesCompanion(')
          ..write('puzzleId: $puzzleId, ')
          ..write('setVersion: $setVersion, ')
          ..write('cells: $cells, ')
          ..write('elapsedMs: $elapsedMs, ')
          ..write('hintsUsed: $hintsUsed, ')
          ..write('moves: $moves, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsEntriesTable extends SettingsEntries
    with TableInfo<$SettingsEntriesTable, SettingsEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingsEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsEntriesTable createAlias(String alias) {
    return $SettingsEntriesTable(attachedDatabase, alias);
  }
}

class SettingsEntry extends DataClass implements Insertable<SettingsEntry> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const SettingsEntry({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SettingsEntriesCompanion toCompanion(bool nullToAbsent) {
    return SettingsEntriesCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  SettingsEntry copyWith({String? key, String? value, DateTime? updatedAt}) =>
      SettingsEntry(
        key: key ?? this.key,
        value: value ?? this.value,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  SettingsEntry copyWithCompanion(SettingsEntriesCompanion data) {
    return SettingsEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsEntry(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsEntry &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class SettingsEntriesCompanion extends UpdateCompanion<SettingsEntry> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SettingsEntriesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsEntriesCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsEntry> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsEntriesCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SettingsEntriesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
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
    return (StringBuffer('SettingsEntriesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxTable extends Outbox with TableInfo<$OutboxTable, OutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    payload,
    createdAt,
    attempts,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $OutboxTable createAlias(String alias) {
    return $OutboxTable(attachedDatabase, alias);
  }
}

class OutboxData extends DataClass implements Insertable<OutboxData> {
  final int id;
  final String kind;
  final String payload;
  final DateTime createdAt;
  final int attempts;
  const OutboxData({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<String>(kind);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  OutboxCompanion toCompanion(bool nullToAbsent) {
    return OutboxCompanion(
      id: Value(id),
      kind: Value(kind),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory OutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxData(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<String>(kind),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  OutboxData copyWith({
    int? id,
    String? kind,
    String? payload,
    DateTime? createdAt,
    int? attempts,
  }) => OutboxData(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
  );
  OutboxData copyWithCompanion(OutboxCompanion data) {
    return OutboxData(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxData(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, kind, payload, createdAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxData &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class OutboxCompanion extends UpdateCompanion<OutboxData> {
  final Value<int> id;
  final Value<String> kind;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  const OutboxCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  OutboxCompanion.insert({
    this.id = const Value.absent(),
    required String kind,
    required String payload,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
  }) : kind = Value(kind),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<OutboxData> custom({
    Expression<int>? id,
    Expression<String>? kind,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  OutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? kind,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
  }) {
    return OutboxCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

class $DailyCacheTable extends DailyCache
    with TableInfo<$DailyCacheTable, DailyCacheData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _puzzleJsonMeta = const VerificationMeta(
    'puzzleJson',
  );
  @override
  late final GeneratedColumn<String> puzzleJson = GeneratedColumn<String>(
    'puzzle_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [date, puzzleJson, fetchedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyCacheData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('puzzle_json')) {
      context.handle(
        _puzzleJsonMeta,
        puzzleJson.isAcceptableOrUnknown(data['puzzle_json']!, _puzzleJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleJsonMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyCacheData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyCacheData(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      puzzleJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_json'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $DailyCacheTable createAlias(String alias) {
    return $DailyCacheTable(attachedDatabase, alias);
  }
}

class DailyCacheData extends DataClass implements Insertable<DailyCacheData> {
  /// Local date, `yyyy-MM-dd`.
  final String date;
  final String puzzleJson;
  final DateTime fetchedAt;
  const DailyCacheData({
    required this.date,
    required this.puzzleJson,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['puzzle_json'] = Variable<String>(puzzleJson);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  DailyCacheCompanion toCompanion(bool nullToAbsent) {
    return DailyCacheCompanion(
      date: Value(date),
      puzzleJson: Value(puzzleJson),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory DailyCacheData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyCacheData(
      date: serializer.fromJson<String>(json['date']),
      puzzleJson: serializer.fromJson<String>(json['puzzleJson']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'puzzleJson': serializer.toJson<String>(puzzleJson),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  DailyCacheData copyWith({
    String? date,
    String? puzzleJson,
    DateTime? fetchedAt,
  }) => DailyCacheData(
    date: date ?? this.date,
    puzzleJson: puzzleJson ?? this.puzzleJson,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  DailyCacheData copyWithCompanion(DailyCacheCompanion data) {
    return DailyCacheData(
      date: data.date.present ? data.date.value : this.date,
      puzzleJson: data.puzzleJson.present
          ? data.puzzleJson.value
          : this.puzzleJson,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyCacheData(')
          ..write('date: $date, ')
          ..write('puzzleJson: $puzzleJson, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(date, puzzleJson, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyCacheData &&
          other.date == this.date &&
          other.puzzleJson == this.puzzleJson &&
          other.fetchedAt == this.fetchedAt);
}

class DailyCacheCompanion extends UpdateCompanion<DailyCacheData> {
  final Value<String> date;
  final Value<String> puzzleJson;
  final Value<DateTime> fetchedAt;
  final Value<int> rowid;
  const DailyCacheCompanion({
    this.date = const Value.absent(),
    this.puzzleJson = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyCacheCompanion.insert({
    required String date,
    required String puzzleJson,
    required DateTime fetchedAt,
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       puzzleJson = Value(puzzleJson),
       fetchedAt = Value(fetchedAt);
  static Insertable<DailyCacheData> custom({
    Expression<String>? date,
    Expression<String>? puzzleJson,
    Expression<DateTime>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (puzzleJson != null) 'puzzle_json': puzzleJson,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyCacheCompanion copyWith({
    Value<String>? date,
    Value<String>? puzzleJson,
    Value<DateTime>? fetchedAt,
    Value<int>? rowid,
  }) {
    return DailyCacheCompanion(
      date: date ?? this.date,
      puzzleJson: puzzleJson ?? this.puzzleJson,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (puzzleJson.present) {
      map['puzzle_json'] = Variable<String>(puzzleJson.value);
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
    return (StringBuffer('DailyCacheCompanion(')
          ..write('date: $date, ')
          ..write('puzzleJson: $puzzleJson, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyResultsTable extends DailyResults
    with TableInfo<$DailyResultsTable, DailyResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _puzzleIdMeta = const VerificationMeta(
    'puzzleId',
  );
  @override
  late final GeneratedColumn<String> puzzleId = GeneratedColumn<String>(
    'puzzle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solvedMeta = const VerificationMeta('solved');
  @override
  late final GeneratedColumn<bool> solved = GeneratedColumn<bool>(
    'solved',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solved" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _timeMsMeta = const VerificationMeta('timeMs');
  @override
  late final GeneratedColumn<int> timeMs = GeneratedColumn<int>(
    'time_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _solvedOnDayMeta = const VerificationMeta(
    'solvedOnDay',
  );
  @override
  late final GeneratedColumn<bool> solvedOnDay = GeneratedColumn<bool>(
    'solved_on_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solved_on_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockedMeta = const VerificationMeta(
    'unlocked',
  );
  @override
  late final GeneratedColumn<bool> unlocked = GeneratedColumn<bool>(
    'unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    puzzleId,
    solved,
    timeMs,
    solvedOnDay,
    unlocked,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('puzzle_id')) {
      context.handle(
        _puzzleIdMeta,
        puzzleId.isAcceptableOrUnknown(data['puzzle_id']!, _puzzleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_puzzleIdMeta);
    }
    if (data.containsKey('solved')) {
      context.handle(
        _solvedMeta,
        solved.isAcceptableOrUnknown(data['solved']!, _solvedMeta),
      );
    }
    if (data.containsKey('time_ms')) {
      context.handle(
        _timeMsMeta,
        timeMs.isAcceptableOrUnknown(data['time_ms']!, _timeMsMeta),
      );
    }
    if (data.containsKey('solved_on_day')) {
      context.handle(
        _solvedOnDayMeta,
        solvedOnDay.isAcceptableOrUnknown(
          data['solved_on_day']!,
          _solvedOnDayMeta,
        ),
      );
    }
    if (data.containsKey('unlocked')) {
      context.handle(
        _unlockedMeta,
        unlocked.isAcceptableOrUnknown(data['unlocked']!, _unlockedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date};
  @override
  DailyResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyResult(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      puzzleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}puzzle_id'],
      )!,
      solved: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solved'],
      )!,
      timeMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}time_ms'],
      ),
      solvedOnDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solved_on_day'],
      )!,
      unlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}unlocked'],
      )!,
    );
  }

  @override
  $DailyResultsTable createAlias(String alias) {
    return $DailyResultsTable(attachedDatabase, alias);
  }
}

class DailyResult extends DataClass implements Insertable<DailyResult> {
  final String date;
  final String puzzleId;
  final bool solved;
  final int? timeMs;

  /// Solved on its own local date (leaderboard-eligible).
  final bool solvedOnDay;

  /// A missed day unlocked by a rewarded ad (or premium).
  final bool unlocked;
  const DailyResult({
    required this.date,
    required this.puzzleId,
    required this.solved,
    this.timeMs,
    required this.solvedOnDay,
    required this.unlocked,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['puzzle_id'] = Variable<String>(puzzleId);
    map['solved'] = Variable<bool>(solved);
    if (!nullToAbsent || timeMs != null) {
      map['time_ms'] = Variable<int>(timeMs);
    }
    map['solved_on_day'] = Variable<bool>(solvedOnDay);
    map['unlocked'] = Variable<bool>(unlocked);
    return map;
  }

  DailyResultsCompanion toCompanion(bool nullToAbsent) {
    return DailyResultsCompanion(
      date: Value(date),
      puzzleId: Value(puzzleId),
      solved: Value(solved),
      timeMs: timeMs == null && nullToAbsent
          ? const Value.absent()
          : Value(timeMs),
      solvedOnDay: Value(solvedOnDay),
      unlocked: Value(unlocked),
    );
  }

  factory DailyResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyResult(
      date: serializer.fromJson<String>(json['date']),
      puzzleId: serializer.fromJson<String>(json['puzzleId']),
      solved: serializer.fromJson<bool>(json['solved']),
      timeMs: serializer.fromJson<int?>(json['timeMs']),
      solvedOnDay: serializer.fromJson<bool>(json['solvedOnDay']),
      unlocked: serializer.fromJson<bool>(json['unlocked']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'puzzleId': serializer.toJson<String>(puzzleId),
      'solved': serializer.toJson<bool>(solved),
      'timeMs': serializer.toJson<int?>(timeMs),
      'solvedOnDay': serializer.toJson<bool>(solvedOnDay),
      'unlocked': serializer.toJson<bool>(unlocked),
    };
  }

  DailyResult copyWith({
    String? date,
    String? puzzleId,
    bool? solved,
    Value<int?> timeMs = const Value.absent(),
    bool? solvedOnDay,
    bool? unlocked,
  }) => DailyResult(
    date: date ?? this.date,
    puzzleId: puzzleId ?? this.puzzleId,
    solved: solved ?? this.solved,
    timeMs: timeMs.present ? timeMs.value : this.timeMs,
    solvedOnDay: solvedOnDay ?? this.solvedOnDay,
    unlocked: unlocked ?? this.unlocked,
  );
  DailyResult copyWithCompanion(DailyResultsCompanion data) {
    return DailyResult(
      date: data.date.present ? data.date.value : this.date,
      puzzleId: data.puzzleId.present ? data.puzzleId.value : this.puzzleId,
      solved: data.solved.present ? data.solved.value : this.solved,
      timeMs: data.timeMs.present ? data.timeMs.value : this.timeMs,
      solvedOnDay: data.solvedOnDay.present
          ? data.solvedOnDay.value
          : this.solvedOnDay,
      unlocked: data.unlocked.present ? data.unlocked.value : this.unlocked,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyResult(')
          ..write('date: $date, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('solved: $solved, ')
          ..write('timeMs: $timeMs, ')
          ..write('solvedOnDay: $solvedOnDay, ')
          ..write('unlocked: $unlocked')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, puzzleId, solved, timeMs, solvedOnDay, unlocked);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyResult &&
          other.date == this.date &&
          other.puzzleId == this.puzzleId &&
          other.solved == this.solved &&
          other.timeMs == this.timeMs &&
          other.solvedOnDay == this.solvedOnDay &&
          other.unlocked == this.unlocked);
}

class DailyResultsCompanion extends UpdateCompanion<DailyResult> {
  final Value<String> date;
  final Value<String> puzzleId;
  final Value<bool> solved;
  final Value<int?> timeMs;
  final Value<bool> solvedOnDay;
  final Value<bool> unlocked;
  final Value<int> rowid;
  const DailyResultsCompanion({
    this.date = const Value.absent(),
    this.puzzleId = const Value.absent(),
    this.solved = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.solvedOnDay = const Value.absent(),
    this.unlocked = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyResultsCompanion.insert({
    required String date,
    required String puzzleId,
    this.solved = const Value.absent(),
    this.timeMs = const Value.absent(),
    this.solvedOnDay = const Value.absent(),
    this.unlocked = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       puzzleId = Value(puzzleId);
  static Insertable<DailyResult> custom({
    Expression<String>? date,
    Expression<String>? puzzleId,
    Expression<bool>? solved,
    Expression<int>? timeMs,
    Expression<bool>? solvedOnDay,
    Expression<bool>? unlocked,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (puzzleId != null) 'puzzle_id': puzzleId,
      if (solved != null) 'solved': solved,
      if (timeMs != null) 'time_ms': timeMs,
      if (solvedOnDay != null) 'solved_on_day': solvedOnDay,
      if (unlocked != null) 'unlocked': unlocked,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyResultsCompanion copyWith({
    Value<String>? date,
    Value<String>? puzzleId,
    Value<bool>? solved,
    Value<int?>? timeMs,
    Value<bool>? solvedOnDay,
    Value<bool>? unlocked,
    Value<int>? rowid,
  }) {
    return DailyResultsCompanion(
      date: date ?? this.date,
      puzzleId: puzzleId ?? this.puzzleId,
      solved: solved ?? this.solved,
      timeMs: timeMs ?? this.timeMs,
      solvedOnDay: solvedOnDay ?? this.solvedOnDay,
      unlocked: unlocked ?? this.unlocked,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (puzzleId.present) {
      map['puzzle_id'] = Variable<String>(puzzleId.value);
    }
    if (solved.present) {
      map['solved'] = Variable<bool>(solved.value);
    }
    if (timeMs.present) {
      map['time_ms'] = Variable<int>(timeMs.value);
    }
    if (solvedOnDay.present) {
      map['solved_on_day'] = Variable<bool>(solvedOnDay.value);
    }
    if (unlocked.present) {
      map['unlocked'] = Variable<bool>(unlocked.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyResultsCompanion(')
          ..write('date: $date, ')
          ..write('puzzleId: $puzzleId, ')
          ..write('solved: $solved, ')
          ..write('timeMs: $timeMs, ')
          ..write('solvedOnDay: $solvedOnDay, ')
          ..write('unlocked: $unlocked, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PuzzleProgressTable puzzleProgress = $PuzzleProgressTable(this);
  late final $BoardSavesTable boardSaves = $BoardSavesTable(this);
  late final $SettingsEntriesTable settingsEntries = $SettingsEntriesTable(
    this,
  );
  late final $OutboxTable outbox = $OutboxTable(this);
  late final $DailyCacheTable dailyCache = $DailyCacheTable(this);
  late final $DailyResultsTable dailyResults = $DailyResultsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    puzzleProgress,
    boardSaves,
    settingsEntries,
    outbox,
    dailyCache,
    dailyResults,
  ];
}

typedef $$PuzzleProgressTableCreateCompanionBuilder =
    PuzzleProgressCompanion Function({
      required String puzzleId,
      required int setVersion,
      Value<bool> isSolved,
      Value<int?> bestTimeMs,
      Value<DateTime?> solvedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> solveCount,
      Value<bool> solvedWithoutHints,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$PuzzleProgressTableUpdateCompanionBuilder =
    PuzzleProgressCompanion Function({
      Value<String> puzzleId,
      Value<int> setVersion,
      Value<bool> isSolved,
      Value<int?> bestTimeMs,
      Value<DateTime?> solvedAt,
      Value<DateTime?> lastPlayedAt,
      Value<int> solveCount,
      Value<bool> solvedWithoutHints,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$PuzzleProgressTableFilterComposer
    extends Composer<_$AppDatabase, $PuzzleProgressTable> {
  $$PuzzleProgressTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSolved => $composableBuilder(
    column: $table.isSolved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bestTimeMs => $composableBuilder(
    column: $table.bestTimeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get solveCount => $composableBuilder(
    column: $table.solveCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get solvedWithoutHints => $composableBuilder(
    column: $table.solvedWithoutHints,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PuzzleProgressTableOrderingComposer
    extends Composer<_$AppDatabase, $PuzzleProgressTable> {
  $$PuzzleProgressTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSolved => $composableBuilder(
    column: $table.isSolved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bestTimeMs => $composableBuilder(
    column: $table.bestTimeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get solvedAt => $composableBuilder(
    column: $table.solvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get solveCount => $composableBuilder(
    column: $table.solveCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get solvedWithoutHints => $composableBuilder(
    column: $table.solvedWithoutHints,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PuzzleProgressTableAnnotationComposer
    extends Composer<_$AppDatabase, $PuzzleProgressTable> {
  $$PuzzleProgressTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSolved =>
      $composableBuilder(column: $table.isSolved, builder: (column) => column);

  GeneratedColumn<int> get bestTimeMs => $composableBuilder(
    column: $table.bestTimeMs,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get solvedAt =>
      $composableBuilder(column: $table.solvedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPlayedAt => $composableBuilder(
    column: $table.lastPlayedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get solveCount => $composableBuilder(
    column: $table.solveCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get solvedWithoutHints => $composableBuilder(
    column: $table.solvedWithoutHints,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PuzzleProgressTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PuzzleProgressTable,
          PuzzleProgressData,
          $$PuzzleProgressTableFilterComposer,
          $$PuzzleProgressTableOrderingComposer,
          $$PuzzleProgressTableAnnotationComposer,
          $$PuzzleProgressTableCreateCompanionBuilder,
          $$PuzzleProgressTableUpdateCompanionBuilder,
          (
            PuzzleProgressData,
            BaseReferences<
              _$AppDatabase,
              $PuzzleProgressTable,
              PuzzleProgressData
            >,
          ),
          PuzzleProgressData,
          PrefetchHooks Function()
        > {
  $$PuzzleProgressTableTableManager(
    _$AppDatabase db,
    $PuzzleProgressTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PuzzleProgressTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PuzzleProgressTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PuzzleProgressTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<int> setVersion = const Value.absent(),
                Value<bool> isSolved = const Value.absent(),
                Value<int?> bestTimeMs = const Value.absent(),
                Value<DateTime?> solvedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> solveCount = const Value.absent(),
                Value<bool> solvedWithoutHints = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PuzzleProgressCompanion(
                puzzleId: puzzleId,
                setVersion: setVersion,
                isSolved: isSolved,
                bestTimeMs: bestTimeMs,
                solvedAt: solvedAt,
                lastPlayedAt: lastPlayedAt,
                solveCount: solveCount,
                solvedWithoutHints: solvedWithoutHints,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required int setVersion,
                Value<bool> isSolved = const Value.absent(),
                Value<int?> bestTimeMs = const Value.absent(),
                Value<DateTime?> solvedAt = const Value.absent(),
                Value<DateTime?> lastPlayedAt = const Value.absent(),
                Value<int> solveCount = const Value.absent(),
                Value<bool> solvedWithoutHints = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => PuzzleProgressCompanion.insert(
                puzzleId: puzzleId,
                setVersion: setVersion,
                isSolved: isSolved,
                bestTimeMs: bestTimeMs,
                solvedAt: solvedAt,
                lastPlayedAt: lastPlayedAt,
                solveCount: solveCount,
                solvedWithoutHints: solvedWithoutHints,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PuzzleProgressTable, PuzzleProgressData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PuzzleProgressTable,
                    PuzzleProgressData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PuzzleProgressTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PuzzleProgressTable,
      PuzzleProgressData,
      $$PuzzleProgressTableFilterComposer,
      $$PuzzleProgressTableOrderingComposer,
      $$PuzzleProgressTableAnnotationComposer,
      $$PuzzleProgressTableCreateCompanionBuilder,
      $$PuzzleProgressTableUpdateCompanionBuilder,
      (
        PuzzleProgressData,
        BaseReferences<_$AppDatabase, $PuzzleProgressTable, PuzzleProgressData>,
      ),
      PuzzleProgressData,
      PrefetchHooks Function()
    >;
typedef $$BoardSavesTableCreateCompanionBuilder = BoardSavesCompanion Function({
  required String puzzleId,
  required int setVersion,
  required String cells,
  required int elapsedMs,
  Value<int> hintsUsed,
  Value<int> moves,
  required DateTime savedAt,
  Value<int> rowid,
});
typedef $$BoardSavesTableUpdateCompanionBuilder = BoardSavesCompanion Function({
  Value<String> puzzleId,
  Value<int> setVersion,
  Value<String> cells,
  Value<int> elapsedMs,
  Value<int> hintsUsed,
  Value<int> moves,
  Value<DateTime> savedAt,
  Value<int> rowid,
});

class $$BoardSavesTableFilterComposer
    extends Composer<_$AppDatabase, $BoardSavesTable> {
  $$BoardSavesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cells => $composableBuilder(
    column: $table.cells,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BoardSavesTableOrderingComposer
    extends Composer<_$AppDatabase, $BoardSavesTable> {
  $$BoardSavesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cells => $composableBuilder(
    column: $table.cells,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get elapsedMs => $composableBuilder(
    column: $table.elapsedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hintsUsed => $composableBuilder(
    column: $table.hintsUsed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get moves => $composableBuilder(
    column: $table.moves,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BoardSavesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BoardSavesTable> {
  $$BoardSavesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<int> get setVersion => $composableBuilder(
    column: $table.setVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get cells =>
      $composableBuilder(column: $table.cells, builder: (column) => column);

  GeneratedColumn<int> get elapsedMs =>
      $composableBuilder(column: $table.elapsedMs, builder: (column) => column);

  GeneratedColumn<int> get hintsUsed =>
      $composableBuilder(column: $table.hintsUsed, builder: (column) => column);

  GeneratedColumn<int> get moves =>
      $composableBuilder(column: $table.moves, builder: (column) => column);

  GeneratedColumn<DateTime> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$BoardSavesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BoardSavesTable,
          BoardSave,
          $$BoardSavesTableFilterComposer,
          $$BoardSavesTableOrderingComposer,
          $$BoardSavesTableAnnotationComposer,
          $$BoardSavesTableCreateCompanionBuilder,
          $$BoardSavesTableUpdateCompanionBuilder,
          (
            BoardSave,
            BaseReferences<_$AppDatabase, $BoardSavesTable, BoardSave>,
          ),
          BoardSave,
          PrefetchHooks Function()
        > {
  $$BoardSavesTableTableManager(_$AppDatabase db, $BoardSavesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BoardSavesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BoardSavesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BoardSavesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> puzzleId = const Value.absent(),
                Value<int> setVersion = const Value.absent(),
                Value<String> cells = const Value.absent(),
                Value<int> elapsedMs = const Value.absent(),
                Value<int> hintsUsed = const Value.absent(),
                Value<int> moves = const Value.absent(),
                Value<DateTime> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BoardSavesCompanion(
                puzzleId: puzzleId,
                setVersion: setVersion,
                cells: cells,
                elapsedMs: elapsedMs,
                hintsUsed: hintsUsed,
                moves: moves,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String puzzleId,
                required int setVersion,
                required String cells,
                required int elapsedMs,
                Value<int> hintsUsed = const Value.absent(),
                Value<int> moves = const Value.absent(),
                required DateTime savedAt,
                Value<int> rowid = const Value.absent(),
              }) => BoardSavesCompanion.insert(
                puzzleId: puzzleId,
                setVersion: setVersion,
                cells: cells,
                elapsedMs: elapsedMs,
                hintsUsed: hintsUsed,
                moves: moves,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BoardSavesTable, BoardSave>(table),
                  BaseReferences<_$AppDatabase, $BoardSavesTable, BoardSave>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BoardSavesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BoardSavesTable,
      BoardSave,
      $$BoardSavesTableFilterComposer,
      $$BoardSavesTableOrderingComposer,
      $$BoardSavesTableAnnotationComposer,
      $$BoardSavesTableCreateCompanionBuilder,
      $$BoardSavesTableUpdateCompanionBuilder,
      (BoardSave, BaseReferences<_$AppDatabase, $BoardSavesTable, BoardSave>),
      BoardSave,
      PrefetchHooks Function()
    >;
typedef $$SettingsEntriesTableCreateCompanionBuilder =
    SettingsEntriesCompanion Function({
      required String key,
      required String value,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$SettingsEntriesTableUpdateCompanionBuilder =
    SettingsEntriesCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$SettingsEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsEntriesTable> {
  $$SettingsEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsEntriesTable,
          SettingsEntry,
          $$SettingsEntriesTableFilterComposer,
          $$SettingsEntriesTableOrderingComposer,
          $$SettingsEntriesTableAnnotationComposer,
          $$SettingsEntriesTableCreateCompanionBuilder,
          $$SettingsEntriesTableUpdateCompanionBuilder,
          (
            SettingsEntry,
            BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
          ),
          SettingsEntry,
          PrefetchHooks Function()
        > {
  $$SettingsEntriesTableTableManager(
    _$AppDatabase db,
    $SettingsEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SettingsEntriesCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsEntriesTable, SettingsEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SettingsEntriesTable,
                    SettingsEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsEntriesTable,
      SettingsEntry,
      $$SettingsEntriesTableFilterComposer,
      $$SettingsEntriesTableOrderingComposer,
      $$SettingsEntriesTableAnnotationComposer,
      $$SettingsEntriesTableCreateCompanionBuilder,
      $$SettingsEntriesTableUpdateCompanionBuilder,
      (
        SettingsEntry,
        BaseReferences<_$AppDatabase, $SettingsEntriesTable, SettingsEntry>,
      ),
      SettingsEntry,
      PrefetchHooks Function()
    >;
typedef $$OutboxTableCreateCompanionBuilder = OutboxCompanion Function({
  Value<int> id,
  required String kind,
  required String payload,
  required DateTime createdAt,
  Value<int> attempts,
});
typedef $$OutboxTableUpdateCompanionBuilder = OutboxCompanion Function({
  Value<int> id,
  Value<String> kind,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> attempts,
});

class $$OutboxTableFilterComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $OutboxTable> {
  $$OutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$OutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OutboxTable,
          OutboxData,
          $$OutboxTableFilterComposer,
          $$OutboxTableOrderingComposer,
          $$OutboxTableAnnotationComposer,
          $$OutboxTableCreateCompanionBuilder,
          $$OutboxTableUpdateCompanionBuilder,
          (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
          OutboxData,
          PrefetchHooks Function()
        > {
  $$OutboxTableTableManager(_$AppDatabase db, $OutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion(
                id: id,
                kind: kind,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String kind,
                required String payload,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
              }) => OutboxCompanion.insert(
                id: id,
                kind: kind,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxTable, OutboxData>(table),
                  BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OutboxTable,
      OutboxData,
      $$OutboxTableFilterComposer,
      $$OutboxTableOrderingComposer,
      $$OutboxTableAnnotationComposer,
      $$OutboxTableCreateCompanionBuilder,
      $$OutboxTableUpdateCompanionBuilder,
      (OutboxData, BaseReferences<_$AppDatabase, $OutboxTable, OutboxData>),
      OutboxData,
      PrefetchHooks Function()
    >;
typedef $$DailyCacheTableCreateCompanionBuilder = DailyCacheCompanion Function({
  required String date,
  required String puzzleJson,
  required DateTime fetchedAt,
  Value<int> rowid,
});
typedef $$DailyCacheTableUpdateCompanionBuilder = DailyCacheCompanion Function({
  Value<String> date,
  Value<String> puzzleJson,
  Value<DateTime> fetchedAt,
  Value<int> rowid,
});

class $$DailyCacheTableFilterComposer
    extends Composer<_$AppDatabase, $DailyCacheTable> {
  $$DailyCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleJson => $composableBuilder(
    column: $table.puzzleJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyCacheTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyCacheTable> {
  $$DailyCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleJson => $composableBuilder(
    column: $table.puzzleJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyCacheTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyCacheTable> {
  $$DailyCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get puzzleJson => $composableBuilder(
    column: $table.puzzleJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$DailyCacheTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyCacheTable,
          DailyCacheData,
          $$DailyCacheTableFilterComposer,
          $$DailyCacheTableOrderingComposer,
          $$DailyCacheTableAnnotationComposer,
          $$DailyCacheTableCreateCompanionBuilder,
          $$DailyCacheTableUpdateCompanionBuilder,
          (
            DailyCacheData,
            BaseReferences<_$AppDatabase, $DailyCacheTable, DailyCacheData>,
          ),
          DailyCacheData,
          PrefetchHooks Function()
        > {
  $$DailyCacheTableTableManager(_$AppDatabase db, $DailyCacheTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> puzzleJson = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyCacheCompanion(
                date: date,
                puzzleJson: puzzleJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String puzzleJson,
                required DateTime fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => DailyCacheCompanion.insert(
                date: date,
                puzzleJson: puzzleJson,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyCacheTable, DailyCacheData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyCacheTable,
                    DailyCacheData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyCacheTable,
      DailyCacheData,
      $$DailyCacheTableFilterComposer,
      $$DailyCacheTableOrderingComposer,
      $$DailyCacheTableAnnotationComposer,
      $$DailyCacheTableCreateCompanionBuilder,
      $$DailyCacheTableUpdateCompanionBuilder,
      (
        DailyCacheData,
        BaseReferences<_$AppDatabase, $DailyCacheTable, DailyCacheData>,
      ),
      DailyCacheData,
      PrefetchHooks Function()
    >;
typedef $$DailyResultsTableCreateCompanionBuilder =
    DailyResultsCompanion Function({
      required String date,
      required String puzzleId,
      Value<bool> solved,
      Value<int?> timeMs,
      Value<bool> solvedOnDay,
      Value<bool> unlocked,
      Value<int> rowid,
    });
typedef $$DailyResultsTableUpdateCompanionBuilder =
    DailyResultsCompanion Function({
      Value<String> date,
      Value<String> puzzleId,
      Value<bool> solved,
      Value<int?> timeMs,
      Value<bool> solvedOnDay,
      Value<bool> unlocked,
      Value<int> rowid,
    });

class $$DailyResultsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyResultsTable> {
  $$DailyResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get solved => $composableBuilder(
    column: $table.solved,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get solvedOnDay => $composableBuilder(
    column: $table.solvedOnDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get unlocked => $composableBuilder(
    column: $table.unlocked,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DailyResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyResultsTable> {
  $$DailyResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get puzzleId => $composableBuilder(
    column: $table.puzzleId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get solved => $composableBuilder(
    column: $table.solved,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timeMs => $composableBuilder(
    column: $table.timeMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get solvedOnDay => $composableBuilder(
    column: $table.solvedOnDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get unlocked => $composableBuilder(
    column: $table.unlocked,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyResultsTable> {
  $$DailyResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get puzzleId =>
      $composableBuilder(column: $table.puzzleId, builder: (column) => column);

  GeneratedColumn<bool> get solved =>
      $composableBuilder(column: $table.solved, builder: (column) => column);

  GeneratedColumn<int> get timeMs =>
      $composableBuilder(column: $table.timeMs, builder: (column) => column);

  GeneratedColumn<bool> get solvedOnDay => $composableBuilder(
    column: $table.solvedOnDay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get unlocked =>
      $composableBuilder(column: $table.unlocked, builder: (column) => column);
}

class $$DailyResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyResultsTable,
          DailyResult,
          $$DailyResultsTableFilterComposer,
          $$DailyResultsTableOrderingComposer,
          $$DailyResultsTableAnnotationComposer,
          $$DailyResultsTableCreateCompanionBuilder,
          $$DailyResultsTableUpdateCompanionBuilder,
          (
            DailyResult,
            BaseReferences<_$AppDatabase, $DailyResultsTable, DailyResult>,
          ),
          DailyResult,
          PrefetchHooks Function()
        > {
  $$DailyResultsTableTableManager(_$AppDatabase db, $DailyResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> date = const Value.absent(),
                Value<String> puzzleId = const Value.absent(),
                Value<bool> solved = const Value.absent(),
                Value<int?> timeMs = const Value.absent(),
                Value<bool> solvedOnDay = const Value.absent(),
                Value<bool> unlocked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyResultsCompanion(
                date: date,
                puzzleId: puzzleId,
                solved: solved,
                timeMs: timeMs,
                solvedOnDay: solvedOnDay,
                unlocked: unlocked,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String date,
                required String puzzleId,
                Value<bool> solved = const Value.absent(),
                Value<int?> timeMs = const Value.absent(),
                Value<bool> solvedOnDay = const Value.absent(),
                Value<bool> unlocked = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyResultsCompanion.insert(
                date: date,
                puzzleId: puzzleId,
                solved: solved,
                timeMs: timeMs,
                solvedOnDay: solvedOnDay,
                unlocked: unlocked,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DailyResultsTable, DailyResult>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $DailyResultsTable,
                    DailyResult
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyResultsTable,
      DailyResult,
      $$DailyResultsTableFilterComposer,
      $$DailyResultsTableOrderingComposer,
      $$DailyResultsTableAnnotationComposer,
      $$DailyResultsTableCreateCompanionBuilder,
      $$DailyResultsTableUpdateCompanionBuilder,
      (
        DailyResult,
        BaseReferences<_$AppDatabase, $DailyResultsTable, DailyResult>,
      ),
      DailyResult,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PuzzleProgressTableTableManager get puzzleProgress =>
      $$PuzzleProgressTableTableManager(_db, _db.puzzleProgress);
  $$BoardSavesTableTableManager get boardSaves =>
      $$BoardSavesTableTableManager(_db, _db.boardSaves);
  $$SettingsEntriesTableTableManager get settingsEntries =>
      $$SettingsEntriesTableTableManager(_db, _db.settingsEntries);
  $$OutboxTableTableManager get outbox =>
      $$OutboxTableTableManager(_db, _db.outbox);
  $$DailyCacheTableTableManager get dailyCache =>
      $$DailyCacheTableTableManager(_db, _db.dailyCache);
  $$DailyResultsTableTableManager get dailyResults =>
      $$DailyResultsTableTableManager(_db, _db.dailyResults);
}
