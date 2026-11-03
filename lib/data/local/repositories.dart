import 'package:drift/drift.dart';

import '../../engine/model/board.dart';
import '../../engine/model/cell_state.dart';
import 'app_database.dart';

/// Result of recording a solve.
class SolveOutcome {
  const SolveOutcome({
    required this.isFirstSolve,
    required this.isPersonalBest,
    required this.previousBestMs,
  });

  final bool isFirstSolve;

  /// True for a first solve too (there was no best to beat).
  final bool isPersonalBest;
  final int? previousBestMs;
}

class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, PuzzleProgressData>> watchAll() =>
      _db.select(_db.puzzleProgress).watch().map((rows) => {for (final r in rows) r.puzzleId: r});

  Future<Map<String, PuzzleProgressData>> all() async =>
      {for (final r in await _db.select(_db.puzzleProgress).get()) r.puzzleId: r};

  Future<void> markPlayed(String puzzleId, int setVersion, DateTime now) async {
    await _db.into(_db.puzzleProgress).insert(
          PuzzleProgressCompanion.insert(
            puzzleId: puzzleId,
            setVersion: setVersion,
            lastPlayedAt: Value(now),
            updatedAt: now,
          ),
          onConflict: DoUpdate((_) => PuzzleProgressCompanion(
                lastPlayedAt: Value(now),
                updatedAt: Value(now),
              )),
        );
  }

  /// Records a solve. Monotonic: solved stays solved, best time only drops.
  Future<SolveOutcome> recordSolve({
    required String puzzleId,
    required int setVersion,
    required int timeMs,
    required int hintsUsed,
    required DateTime now,
  }) {
    return _db.transaction(() async {
      final existing = await (_db.select(_db.puzzleProgress)
            ..where((t) => t.puzzleId.equals(puzzleId)))
          .getSingleOrNull();
      final previousBest = existing?.bestTimeMs;
      final isFirst = existing == null || !existing.isSolved;
      final isBest = previousBest == null || timeMs < previousBest;
      await _db.into(_db.puzzleProgress).insertOnConflictUpdate(PuzzleProgressCompanion(
        puzzleId: Value(puzzleId),
        setVersion: Value(setVersion),
        isSolved: const Value(true),
        bestTimeMs: Value(isBest ? timeMs : previousBest),
        solvedAt: Value(existing?.solvedAt ?? now),
        lastPlayedAt: Value(now),
        solveCount: Value((existing?.solveCount ?? 0) + 1),
        solvedWithoutHints: Value((existing?.solvedWithoutHints ?? false) || hintsUsed == 0),
        updatedAt: Value(now),
      ));
      return SolveOutcome(
        isFirstSolve: isFirst,
        isPersonalBest: isBest,
        previousBestMs: previousBest,
      );
    });
  }

  Future<void> clearAll() => _db.delete(_db.puzzleProgress).go();

  /// Merges progress pulled from the server (rows as the API sends them).
  /// Monotonic like [recordSolve]: solved stays solved, the best time is the
  /// lower one, the first solve date is the earlier one.
  Future<int> mergeRemote(List<Map<String, Object?>> rows, DateTime now) {
    DateTime? date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;
    DateTime? earlier(DateTime? a, DateTime? b) => a == null ? b : (b == null || a.isBefore(b) ? a : b);
    DateTime? later(DateTime? a, DateTime? b) => a == null ? b : (b == null || a.isAfter(b) ? a : b);

    return _db.transaction(() async {
      final local = await all();
      var changed = 0;
      for (final r in rows) {
        final id = r['puzzle_id'];
        if (id is! String) continue;
        final mine = local[id];
        final remoteSolved = r['is_solved'] == true;
        final remoteBest = (r['best_time_ms'] as num?)?.toInt();
        final solved = (mine?.isSolved ?? false) || remoteSolved;
        final best = [mine?.bestTimeMs, if (remoteSolved) remoteBest].whereType<int>().fold<int?>(
            null, (m, t) => m == null || t < m ? t : m);
        final solvedAt = solved ? earlier(mine?.solvedAt, remoteSolved ? date(r['solved_at']) : null) : null;
        final lastPlayed = later(mine?.lastPlayedAt, date(r['last_played_at']));
        if (mine != null &&
            mine.isSolved == solved &&
            mine.bestTimeMs == best &&
            mine.solvedAt == solvedAt &&
            mine.lastPlayedAt == lastPlayed) {
          continue;
        }
        await _db.into(_db.puzzleProgress).insertOnConflictUpdate(PuzzleProgressCompanion(
          puzzleId: Value(id),
          setVersion: Value(mine?.setVersion ?? (r['puzzle_set_version'] as num?)?.toInt() ?? 1),
          isSolved: Value(solved),
          bestTimeMs: Value(best),
          solvedAt: Value(solvedAt ?? (solved ? now : null)),
          lastPlayedAt: Value(lastPlayed),
          solveCount: Value(mine?.solveCount ?? (remoteSolved ? 1 : 0)),
          solvedWithoutHints: Value(mine?.solvedWithoutHints ?? false),
          updatedAt: Value(now),
        ));
        changed++;
      }
      return changed;
    });
  }
}

/// A saved board in progress.
class SavedBoard {
  const SavedBoard({
    required this.board,
    required this.elapsedMs,
    required this.hintsUsed,
    required this.moves,
    required this.setVersion,
  });

  final Board board;
  final int elapsedMs;
  final int hintsUsed;
  final int moves;
  final int setVersion;
}

class BoardRepository {
  BoardRepository(this._db);

  final AppDatabase _db;

  static String encode(Board b) => b.cells
      .map((c) => switch (c) {
            CellState.empty => '.',
            CellState.filled => '#',
            CellState.crossed => 'x',
          })
      .join();

  static Board decode(String s, int width, int height) => Board(width, height, [
        for (final ch in s.split(''))
          switch (ch) {
            '#' => CellState.filled,
            'x' => CellState.crossed,
            _ => CellState.empty,
          },
      ]);

  Future<SavedBoard?> load(String puzzleId, int width, int height) async {
    final row = await (_db.select(_db.boardSaves)..where((t) => t.puzzleId.equals(puzzleId)))
        .getSingleOrNull();
    if (row == null || row.cells.length != width * height) return null;
    return SavedBoard(
      board: decode(row.cells, width, height),
      elapsedMs: row.elapsedMs,
      hintsUsed: row.hintsUsed,
      moves: row.moves,
      setVersion: row.setVersion,
    );
  }

  Future<void> save(String puzzleId, int setVersion, SavedBoard s, DateTime now) =>
      _db.into(_db.boardSaves).insertOnConflictUpdate(BoardSavesCompanion.insert(
            puzzleId: puzzleId,
            setVersion: setVersion,
            cells: encode(s.board),
            elapsedMs: s.elapsedMs,
            hintsUsed: Value(s.hintsUsed),
            moves: Value(s.moves),
            savedAt: now,
          ));

  Future<void> delete(String puzzleId) =>
      (_db.delete(_db.boardSaves)..where((t) => t.puzzleId.equals(puzzleId))).go();

  /// Puzzle ids with a board in progress, most recent first.
  /// Boards the player has actually worked on, most recent first. A board
  /// that was only opened is saved too (to keep its timer) but is not a
  /// bookmark until it has a move.
  Stream<List<BoardSave>> watchInProgress() => (_db.select(_db.boardSaves)
        ..where((t) => t.moves.isBiggerThanValue(0))
        ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
      .watch();

  Future<void> clearAll() => _db.delete(_db.boardSaves).go();
}

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  Future<Map<String, String>> all() async =>
      {for (final r in await _db.select(_db.settingsEntries).get()) r.key: r.value};

  Future<void> put(String key, String value, DateTime now) =>
      _db.into(_db.settingsEntries).insertOnConflictUpdate(
            SettingsEntriesCompanion.insert(key: key, value: value, updatedAt: now),
          );
}
