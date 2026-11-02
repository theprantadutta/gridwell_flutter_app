import 'dart:convert';

import 'package:drift/drift.dart';

import '../../engine/model/clues.dart';
import '../../engine/model/puzzle.dart';
import '../../engine/model/solution.dart';
import 'app_database.dart';

/// Grid characters used by the daily pool export.
const _colors = {'.': 0, 'k': 1, 'r': 2, 'o': 3, 's': 4, 'i': 5};

/// Daily puzzles cached for offline play, and what happened on each day.
class DailyRepository {
  DailyRepository(this._db);

  final AppDatabase _db;

  /// Collection id used for daily puzzle records.
  static const collectionId = 'daily';

  /// Builds a playable record from the API's daily json.
  static PuzzleRecord recordFromJson(Map<String, Object?> j) {
    final rows = (j['rows'] as List).cast<String>();
    final colors = [
      for (final row in rows)
        for (final ch in row.split('')) _colors[ch] ?? 1,
    ];
    final solution = Solution(j['width'] as int, j['height'] as int, [for (final c in colors) c != 0]);
    return PuzzleRecord(
      id: j['puzzle_id'] as String,
      name: j['name'] as String,
      solution: solution,
      clues: Clues.fromSolution(solution),
      difficulty: (j['difficulty'] as num).toDouble(),
      collectionId: collectionId,
      plateNumber: 0,
      colorLayer: colors,
    );
  }

  Future<void> cache(List<Map<String, Object?>> dailies, DateTime now) async {
    await _db.batch((b) {
      for (final d in dailies) {
        b.insert(
          _db.dailyCache,
          DailyCacheCompanion.insert(date: d['date'] as String, puzzleJson: jsonEncode(d), fetchedAt: now),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Stream<Map<String, Map<String, Object?>>> watchCache() => _db.select(_db.dailyCache).watch().map(
        (rows) => {for (final r in rows) r.date: jsonDecode(r.puzzleJson) as Map<String, Object?>},
      );

  Future<Map<String, Object?>?> cached(String date) async {
    final row = await (_db.select(_db.dailyCache)..where((t) => t.date.equals(date))).getSingleOrNull();
    return row == null ? null : jsonDecode(row.puzzleJson) as Map<String, Object?>;
  }

  Stream<Map<String, DailyResult>> watchResults() =>
      _db.select(_db.dailyResults).watch().map((rows) => {for (final r in rows) r.date: r});

  Future<void> recordSolve({
    required String date,
    required String puzzleId,
    required int timeMs,
    required bool onDay,
  }) async {
    final existing = await (_db.select(_db.dailyResults)..where((t) => t.date.equals(date))).getSingleOrNull();
    final best = existing?.timeMs == null ? timeMs : (timeMs < existing!.timeMs! ? timeMs : existing.timeMs!);
    await _db.into(_db.dailyResults).insertOnConflictUpdate(DailyResultsCompanion.insert(
      date: date,
      puzzleId: puzzleId,
      solved: const Value(true),
      timeMs: Value(best),
      solvedOnDay: Value((existing?.solvedOnDay ?? false) || onDay),
      unlocked: Value(existing?.unlocked ?? false),
    ));
  }

  Future<void> unlock(String date, String puzzleId) =>
      _db.into(_db.dailyResults).insert(
            DailyResultsCompanion.insert(date: date, puzzleId: puzzleId, unlocked: const Value(true)),
            onConflict: DoUpdate((_) => const DailyResultsCompanion(unlocked: Value(true))),
          );
}
