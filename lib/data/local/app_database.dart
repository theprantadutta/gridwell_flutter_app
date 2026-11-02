import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Per-puzzle achievement record. `isSolved` and `bestTimeMs` only ever move
/// one way (solved stays solved, best time only drops), so merging with the
/// server is order-independent.
class PuzzleProgress extends Table {
  TextColumn get puzzleId => text()();
  IntColumn get setVersion => integer()();
  BoolColumn get isSolved => boolean().withDefault(const Constant(false))();
  IntColumn get bestTimeMs => integer().nullable()();
  DateTimeColumn get solvedAt => dateTime().nullable()();
  DateTimeColumn get lastPlayedAt => dateTime().nullable()();
  IntColumn get solveCount => integer().withDefault(const Constant(0))();

  /// True once a solve with zero hints happened (for achievements).
  BoolColumn get solvedWithoutHints => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {puzzleId};
}

/// A board in progress, saved on every move so closing the app loses nothing.
class BoardSaves extends Table {
  TextColumn get puzzleId => text()();
  IntColumn get setVersion => integer()();

  /// One char per cell, row-major: `.` untouched, `#` filled, `x` crossed.
  TextColumn get cells => text()();
  IntColumn get elapsedMs => integer()();
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get moves => integer().withDefault(const Constant(0))();
  DateTimeColumn get savedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {puzzleId};
}

/// Key-value settings with a client timestamp (last-write-wins on sync).
class SettingsEntries extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Changes waiting to be pushed to the server. Removed when acknowledged.
class Outbox extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()();
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

/// Daily puzzles fetched ahead of time so the daily works offline.
class DailyCache extends Table {
  /// Local date, `yyyy-MM-dd`.
  TextColumn get date => text()();
  TextColumn get puzzleJson => text()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {date};
}

/// What happened on each daily.
class DailyResults extends Table {
  TextColumn get date => text()();
  TextColumn get puzzleId => text()();
  BoolColumn get solved => boolean().withDefault(const Constant(false))();
  IntColumn get timeMs => integer().nullable()();

  /// Solved on its own local date (leaderboard-eligible).
  BoolColumn get solvedOnDay => boolean().withDefault(const Constant(false))();

  /// A missed day unlocked by a rewarded ad (or premium).
  BoolColumn get unlocked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {date};
}

@DriftDatabase(
  tables: [PuzzleProgress, BoardSaves, SettingsEntries, Outbox, DailyCache, DailyResults],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _open() => driftDatabase(name: 'gridwell');
}
