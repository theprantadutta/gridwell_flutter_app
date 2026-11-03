import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/repositories.dart';
import '../engine/hints/hint.dart';
import '../engine/hints/proven_mistake.dart';
import '../engine/model/board.dart';
import '../engine/model/cell_state.dart';
import '../engine/model/puzzle.dart';
import '../engine/rules/rules.dart';
import '../engine/solver/line_solver.dart';
import '../services/ads/ad_service.dart';
import '../services/analytics/analytics_service.dart';
import 'explain.dart';
import 'monetization.dart' show bonusHintsProvider;
import 'online.dart';
import 'providers.dart';
import 'services.dart';
import 'settings.dart';

enum InputMode { fill, cross }

/// What happened when the player asked for a hint.
enum HintOutcome { applied, nothingToHint, adNotWatched }

enum _StrokeAction { fill, erase, cross, uncross }

/// Free hints per puzzle before a rewarded video is needed.
const freeHintsPerPuzzle = 3;

/// A footnote sheet under the board: a hint or a proven mistake.
class BoardNote {
  const BoardNote({
    required this.kind,
    required this.row,
    required this.col,
    required this.title,
    required this.body,
    this.conclusion,
    this.lineAxisIsRow = true,
    this.lineIndex = 0,
  });

  final BoardNoteKind kind;
  final int row;
  final int col;

  /// e.g. "ROW 5".
  final String title;
  final String body;
  final String? conclusion;
  final bool lineAxisIsRow;
  final int lineIndex;
}

enum BoardNoteKind { hint, mistake }

/// Everything the board screen draws. Plain data only: the UI never touches
/// engine logic.
class BoardSession {
  const BoardSession({
    required this.puzzle,
    required this.board,
    required this.mode,
    required this.canUndo,
    required this.solved,
    required this.hintsUsed,
    required this.rowRetired,
    required this.colRetired,
    required this.mistakeCells,
    required this.moves,
    this.note,
    this.cursorRow,
    this.cursorCol,
    this.hintCell,
  });

  final PuzzleRecord puzzle;
  final Board board;
  final InputMode mode;
  final bool canUndo;
  final bool solved;
  final int hintsUsed;

  /// Struck-through clue numbers per row / column.
  final List<Set<int>> rowRetired;
  final List<Set<int>> colRetired;

  /// Cells flagged as proven mistakes (row-major indices).
  final Set<int> mistakeCells;
  final int moves;
  final BoardNote? note;
  final int? cursorRow;
  final int? cursorCol;

  /// The cell the last hint placed (for the "Undo hint" action), row-major.
  final int? hintCell;

  int get freeHintsLeft => (freeHintsPerPuzzle - hintsUsed).clamp(0, freeHintsPerPuzzle);

  BoardSession copyWith({
    Board? board,
    InputMode? mode,
    bool? canUndo,
    bool? solved,
    int? hintsUsed,
    List<Set<int>>? rowRetired,
    List<Set<int>>? colRetired,
    Set<int>? mistakeCells,
    int? moves,
    BoardNote? Function()? note,
    int? Function()? cursorRow,
    int? Function()? cursorCol,
    int? Function()? hintCell,
  }) =>
      BoardSession(
        puzzle: puzzle,
        board: board ?? this.board,
        mode: mode ?? this.mode,
        canUndo: canUndo ?? this.canUndo,
        solved: solved ?? this.solved,
        hintsUsed: hintsUsed ?? this.hintsUsed,
        rowRetired: rowRetired ?? this.rowRetired,
        colRetired: colRetired ?? this.colRetired,
        mistakeCells: mistakeCells ?? this.mistakeCells,
        moves: moves ?? this.moves,
        note: note == null ? this.note : note(),
        cursorRow: cursorRow == null ? this.cursorRow : cursorRow(),
        cursorCol: cursorCol == null ? this.cursorCol : cursorCol(),
        hintCell: hintCell == null ? this.hintCell : hintCell(),
      );
}

/// Data for the completion page.
class CompletionResult {
  const CompletionResult({
    required this.puzzle,
    required this.timeMs,
    required this.outcome,
    required this.hintsUsed,
    required this.sizeBestMs,
    required this.beatSizeBest,
    required this.collectionSolved,
    required this.collectionTotal,
    required this.completedCollection,
    this.dailyDate,
    this.dailyOnDay = false,
  });

  final PuzzleRecord puzzle;

  /// Set for daily puzzles: the day it belongs to, and whether it was solved
  /// on that day (leaderboard-eligible).
  final String? dailyDate;
  final bool dailyOnDay;
  final int timeMs;
  final SolveOutcome outcome;
  final int hintsUsed;

  /// Best time for this size before this solve (null if none).
  final int? sizeBestMs;
  final bool beatSizeBest;
  final int collectionSolved;
  final int collectionTotal;
  final bool completedCollection;
}

/// The most recent completion, read by the completion page.
class LastCompletion extends Notifier<CompletionResult?> {
  @override
  CompletionResult? build() => null;

  void set(CompletionResult? value) => state = value;
}

final lastCompletionProvider =
    NotifierProvider<LastCompletion, CompletionResult?>(LastCompletion.new);

/// Saved board for a puzzle, loaded before the controller starts.
final savedBoardProvider = FutureProvider.family<SavedBoard?, String>((ref, id) async {
  if (id.startsWith('daily@')) await ref.watch(dailyCacheProvider.future);
  final p = resolvePuzzle(ref, id);
  if (p == null) return null;
  return ref.watch(boardRepositoryProvider).load(id, p.width, p.height);
});

final boardControllerProvider =
    NotifierProvider.family<BoardController, BoardSession, String>(BoardController.new);

class BoardController extends Notifier<BoardSession> {
  BoardController(this.puzzleId);

  final String puzzleId;

  final _undo = <(Board, int?)>[]; // board before a step, and hint cell then
  final _solver = LineSolver();
  final _clock = Stopwatch();
  var _baseElapsedMs = 0;
  var _shownMistakes = <int>{};
  var _abandonLogged = false;

  // Current stroke.
  _StrokeAction? _action;
  int? _startRow, _startCol;
  bool? _lockRow; // true: stroke runs along the start row
  Board? _strokeBefore;
  final _strokeCells = <int>{};

  late PuzzleRecord _puzzle;
  late int _setVersion;

  /// Local date when this is a daily puzzle.
  String? _dailyDate;

  @override
  BoardSession build() {
    final set = ref.read(puzzleSetProvider);
    _puzzle = resolvePuzzle(ref, puzzleId)!;
    _setVersion = set.puzzleSetVersion;
    _dailyDate = dailyDateOfKey(puzzleId);
    if (_dailyDate != null) {
      unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.dailyStarted, {'date': _dailyDate!}));
    }
    final saved = ref.read(savedBoardProvider(puzzleId)).value;
    final usable = saved != null && saved.setVersion == _setVersion;
    final board = usable ? saved.board : Board.empty(_puzzle.width, _puzzle.height);
    _baseElapsedMs = usable ? saved.elapsedMs : 0;

    final progress = ref.read(progressProvider).value?[puzzleId];
    unawaited(ref.read(progressRepositoryProvider).markPlayed(puzzleId, _setVersion, DateTime.now()));
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.puzzleStart, {
      'puzzle_id': puzzleId,
      'size': '${_puzzle.width}x${_puzzle.height}',
      'difficulty': _puzzle.difficulty.round(),
      'is_retry': (progress?.isSolved ?? false) ? 1 : 0,
    }));
    ref.onDispose(_clock.stop);

    final session = BoardSession(
      puzzle: _puzzle,
      board: board,
      mode: InputMode.fill,
      canUndo: false,
      solved: false,
      hintsUsed: usable ? saved.hintsUsed : 0,
      rowRetired: const [],
      colRetired: const [],
      mistakeCells: const {},
      moves: usable ? saved.moves : 0,
    );
    return _derive(session, board);
  }

  // ---- Timer -------------------------------------------------------------

  int get elapsedMs => _baseElapsedMs + _clock.elapsedMilliseconds;

  void resume() {
    if (!state.solved) _clock.start();
  }

  void pause() {
    _clock.stop();
    unawaited(_save());
  }

  // ---- Modes and cursor ---------------------------------------------------

  void setMode(InputMode mode) {
    if (mode == state.mode) return;
    ref.read(feedbackProvider).tap();
    state = state.copyWith(mode: mode);
  }

  void toggleMode() => setMode(state.mode == InputMode.fill ? InputMode.cross : InputMode.fill);

  void dismissNote() => state = state.copyWith(note: () => null);

  // ---- Strokes ------------------------------------------------------------

  void strokeStart(int row, int col) {
    if (state.solved) return;
    resume();
    final cell = state.board.at(row, col);
    _action = switch ((state.mode, cell)) {
      (InputMode.fill, CellState.filled) => _StrokeAction.erase,
      (InputMode.fill, _) => _StrokeAction.fill,
      (InputMode.cross, CellState.crossed) => _StrokeAction.uncross,
      (InputMode.cross, _) => _StrokeAction.cross,
    };
    _startRow = row;
    _startCol = col;
    _lockRow = null;
    _strokeBefore = state.board;
    _strokeCells.clear();
    state = state.copyWith(cursorRow: () => row, cursorCol: () => col, note: () => null);
    _paint([(row, col)]);
  }

  void strokeMove(int row, int col) {
    final action = _action;
    if (action == null) return;
    final sr = _startRow!, sc = _startCol!;
    if (_lockRow == null) {
      if (row == sr && col == sc) return;
      // Lock to whichever axis the finger left along first.
      _lockRow = (row - sr).abs() <= (col - sc).abs();
    }
    final cells = <(int, int)>[];
    if (_lockRow!) {
      final step = col >= sc ? 1 : -1;
      for (var c = sc; c != col + step; c += step) {
        cells.add((sr, c));
      }
      state = state.copyWith(cursorRow: () => sr, cursorCol: () => col);
    } else {
      final step = row >= sr ? 1 : -1;
      for (var r = sr; r != row + step; r += step) {
        cells.add((r, sc));
      }
      state = state.copyWith(cursorRow: () => row, cursorCol: () => sc);
    }
    _paint(cells);
  }

  void strokeEnd() {
    final before = _strokeBefore;
    _action = null;
    _strokeBefore = null;
    if (before == null || identical(before, state.board) || before == state.board) return;

    var board = state.board;
    // Auto-cross lines the stroke completed.
    final completedLines = <LineRef>[];
    final rows = {for (final i in _strokeCells) i ~/ board.width};
    final cols = {for (final i in _strokeCells) i % board.width};
    final edits = <int, CellState>{};
    for (final r in rows) {
      final line = board.row(r);
      if (lineMatchesClue(_puzzle.clues.rows[r], line)) {
        completedLines.add(LineRef.row(r));
        if (ref.read(settingsProvider).autoCross) {
          for (final c in autoCrossPositions(_puzzle.clues.rows[r], line)) {
            edits[r * board.width + c] = CellState.crossed;
          }
        }
      }
    }
    for (final c in cols) {
      final line = board.column(c);
      if (lineMatchesClue(_puzzle.clues.columns[c], line)) {
        completedLines.add(LineRef.column(c));
        if (ref.read(settingsProvider).autoCross) {
          for (final r in autoCrossPositions(_puzzle.clues.columns[c], line)) {
            edits[r * board.width + c] = CellState.crossed;
          }
        }
      }
    }
    board = board.withCells(edits);

    _undo.add((before, state.hintCell));
    if (completedLines.isNotEmpty) ref.read(feedbackProvider).lineCompleted();
    _commit(board, moves: state.moves + 1);
  }

  /// Abandons the stroke in progress (a second finger arrived to zoom).
  void strokeCancel() {
    final before = _strokeBefore;
    _action = null;
    _strokeBefore = null;
    if (before != null) state = _derive(state, before, recomputeMistakes: false);
  }

  void _paint(List<(int, int)> cells) {
    final action = _action!;
    final before = _strokeBefore!;
    final edits = <int, CellState>{};
    for (final (r, c) in cells) {
      final i = r * state.board.width + c;
      if (_strokeCells.contains(i)) continue;
      final original = before.at(r, c);
      final next = switch (action) {
        _StrokeAction.fill => original == CellState.empty ? CellState.filled : null,
        _StrokeAction.erase => original == CellState.filled ? CellState.empty : null,
        _StrokeAction.cross => original == CellState.empty ? CellState.crossed : null,
        _StrokeAction.uncross => original == CellState.crossed ? CellState.empty : null,
      };
      if (next == null) continue;
      edits[i] = next;
      _strokeCells.add(i);
      ref.read(feedbackProvider).cellPlaced(
            filled: next == CellState.filled,
            index: _strokeCells.length - 1,
          );
    }
    if (edits.isEmpty) return;
    final board = state.board.withCells(edits);
    state = _derive(state, board, recomputeMistakes: false);
  }

  // ---- Undo ---------------------------------------------------------------

  void undo() {
    if (_undo.isEmpty || state.solved) return;
    final (board, hintCell) = _undo.removeLast();
    ref.read(feedbackProvider).tap();
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.undoUsed));
    state = state.copyWith(hintCell: () => hintCell, note: () => null);
    _commit(board, moves: state.moves);
  }

  // ---- Hints --------------------------------------------------------------

  /// Works out the next hint without applying it. Show a rewarded video only
  /// if this returns a [ResolvingHint]; then call [applyHint] with it.
  HintResult peekHint() => findHint(_puzzle.clues, _puzzle.solution, state.board, solver: _solver);

  /// True if a hint can be taken without a rewarded video.
  bool get hintIsFree =>
      state.freeHintsLeft > 0 || ref.read(entitlementsProvider).premium;

  /// The Hint button: free hints first, then a rewarded video. The video is
  /// only offered when a hint would actually resolve a cell.
  Future<HintOutcome> requestHint() async {
    final hint = peekHint();
    if (hint is! ResolvingHint) return HintOutcome.nothingToHint;
    // After the free allowance: a banked bonus hint first, then a video.
    if (!hintIsFree && ref.read(bonusHintsProvider.notifier).spend()) {
      final fresh = peekHint();
      if (fresh is! ResolvingHint) {
        ref.read(bonusHintsProvider.notifier).add(1); // nothing to hint: give it back
        return HintOutcome.nothingToHint;
      }
      applyHint(fresh);
      return HintOutcome.applied;
    }
    if (!hintIsFree) {
      // Time spent watching a video is not time spent solving.
      final wasRunning = _clock.isRunning;
      _clock.stop();
      final rewarded = await ref.read(adServiceProvider).showRewarded(AdPlacement.hint);
      if (wasRunning && !state.solved) _clock.start();
      if (!rewarded) return HintOutcome.adNotWatched;
    }
    // Recompute in case the board changed while the video played.
    final fresh = peekHint();
    if (fresh is! ResolvingHint) return HintOutcome.nothingToHint;
    applyHint(fresh);
    return HintOutcome.applied;
  }

  /// Applies a hint. Only a [ResolvingHint] can be applied, so a rewarded
  /// video is never granted for a hint that changes nothing.
  void applyHint(ResolvingHint hint) {
    final before = state.board;
    final i = hint.row * before.width + hint.col;
    final (board, note) = switch (hint) {
      DeducedCellHint h => (
          before.withCell(h.row, h.col, h.value),
          BoardNote(
            kind: BoardNoteKind.hint,
            row: h.row,
            col: h.col,
            title: Explain.hintTitle(h),
            body: Explain.hintBody(h),
            conclusion: Explain.hintConclusion(h),
            lineAxisIsRow: h.line.axis == LineAxis.row,
            lineIndex: h.line.index,
          ),
        ),
      WrongMarkHint h => (
          before.withCell(h.row, h.col, CellState.empty),
          BoardNote(
            kind: BoardNoteKind.mistake,
            row: h.row,
            col: h.col,
            title: h.proof == null ? 'THIS SQUARE' : Explain.mistakeTitle(h.proof!),
            body: h.proof == null
                ? 'This square does not belong to the picture, so it has been cleared.'
                : Explain.mistakeBody(h.proof!,
                    filled: before.at(h.row, h.col) == CellState.filled),
            lineAxisIsRow: h.proof?.line.axis != LineAxis.column,
            lineIndex: h.proof?.line.index ?? h.row,
          ),
        ),
    };
    _undo.add((before, state.hintCell));
    final used = state.hintsUsed + 1;
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.hintUsed, {
      'puzzle_id': puzzleId,
      'hints_this_puzzle': used,
    }));
    state = state.copyWith(
      hintsUsed: used,
      hintCell: () => i,
      note: () => note,
      cursorRow: () => hint.row,
      cursorCol: () => hint.col,
    );
    _commit(board, moves: state.moves + 1);
  }

  /// "Undo hint": removes the hinted cell. The hint stays spent.
  void undoHint() {
    final i = state.hintCell;
    if (i == null) return;
    final b = state.board;
    _undo.add((b, i));
    state = state.copyWith(hintCell: () => null, note: () => null);
    _commit(b.withCell(i ~/ b.width, i % b.width, CellState.empty), moves: state.moves);
  }

  // ---- Mistakes -----------------------------------------------------------

  /// "Clear the square" on a proven-mistake note.
  void clearSquare(int row, int col) {
    final b = state.board;
    _undo.add((b, state.hintCell));
    state = state.copyWith(note: () => null);
    _commit(b.withCell(row, col, CellState.empty), moves: state.moves + 1);
  }

  /// "Undo to here": rewinds until the mistaken mark at (row, col) is gone.
  void undoToBeforeMark(int row, int col) {
    final mark = state.board.at(row, col);
    if (mark == CellState.empty) return;
    Board? target;
    int? hint;
    while (_undo.isNotEmpty) {
      final (b, h) = _undo.removeLast();
      target = b;
      hint = h;
      if (b.at(row, col) != mark) break;
    }
    if (target == null) return;
    ref.read(feedbackProvider).tap();
    state = state.copyWith(hintCell: () => hint, note: () => null);
    _commit(target, moves: state.moves);
  }

  // ---- Commit -------------------------------------------------------------

  void _commit(Board board, {required int moves}) {
    var next = _derive(state.copyWith(moves: moves, canUndo: _undo.isNotEmpty), board);

    // Surface a newly proven mistake (never one already shown).
    if (ref.read(settingsProvider).showProvenMistakes && next.note == null) {
      final fresh = next.mistakeCells.difference(_shownMistakes);
      if (fresh.isNotEmpty) {
        final i = fresh.first;
        final proof = provenMistakeAt(
            _puzzle.clues, _puzzle.solution, board, i ~/ board.width, i % board.width,
            solver: _solver);
        if (proof != null) {
          ref.read(feedbackProvider).mistake();
          unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.mistakeMade, {'puzzle_id': puzzleId}));
          next = next.copyWith(
            note: () => BoardNote(
              kind: BoardNoteKind.mistake,
              row: proof.row,
              col: proof.col,
              title: Explain.mistakeTitle(proof),
              body: Explain.mistakeBody(proof, filled: board.at(proof.row, proof.col) == CellState.filled),
              conclusion: 'Only squares the clues rule out are flagged. You can turn this off in Settings.',
              lineAxisIsRow: proof.line.axis == LineAxis.row,
              lineIndex: proof.line.index,
            ),
          );
        }
      }
    }
    _shownMistakes = {..._shownMistakes.intersection(next.mistakeCells), ...next.mistakeCells};

    if (isSolved(board, _puzzle.solution)) {
      next = next.copyWith(solved: true, note: () => null, cursorRow: () => null, cursorCol: () => null);
      state = next;
      unawaited(_complete());
      return;
    }
    state = next;
    unawaited(_save());
  }

  BoardSession _derive(BoardSession s, Board board, {bool recomputeMistakes = true}) {
    final clues = _puzzle.clues;
    final mistakes = recomputeMistakes && ref.read(settingsProvider).showProvenMistakes
        ? {
            for (final m in provenMistakes(clues, _puzzle.solution, board))
              m.row * board.width + m.col,
          }
        : (recomputeMistakes ? <int>{} : s.mistakeCells);
    return s.copyWith(
      board: board,
      canUndo: _undo.isNotEmpty,
      rowRetired: [
        for (var r = 0; r < board.height; r++) retiredClueIndices(clues.rows[r], board.row(r)),
      ],
      colRetired: [
        for (var c = 0; c < board.width; c++) retiredClueIndices(clues.columns[c], board.column(c)),
      ],
      mistakeCells: mistakes,
    );
  }

  Future<void> _save() async {
    if (state.solved) return;
    await ref.read(boardRepositoryProvider).save(
          puzzleId,
          _setVersion,
          SavedBoard(
            board: state.board,
            elapsedMs: elapsedMs,
            hintsUsed: state.hintsUsed,
            moves: state.moves,
            setVersion: _setVersion,
          ),
          DateTime.now(),
        );
  }

  Future<void> _complete() async {
    _clock.stop();
    final timeMs = elapsedMs;
    ref.read(feedbackProvider).puzzleCompleted();
    final set = ref.read(puzzleSetProvider);
    final progressBefore = ref.read(progressProvider).value ?? const {};

    // Best time for this size before this solve.
    int? sizeBest;
    for (final p in set.puzzles) {
      if (p.width != _puzzle.width || p.height != _puzzle.height) continue;
      final t = progressBefore[p.id]?.bestTimeMs;
      if (t != null && (sizeBest == null || t < sizeBest)) sizeBest = t;
    }

    final outcome = await ref.read(progressRepositoryProvider).recordSolve(
          puzzleId: puzzleId,
          setVersion: _setVersion,
          timeMs: timeMs,
          hintsUsed: state.hintsUsed,
          now: DateTime.now(),
        );
    await ref.read(boardRepositoryProvider).delete(puzzleId);

    final online = ref.read(onlineSessionProvider);
    final now = DateTime.now();
    if (_dailyDate == null) {
      unawaited(online.enqueue('progress', {
      'puzzle_id': puzzleId,
      'puzzle_set_version': _setVersion,
      'is_solved': true,
      'best_time_ms': outcome.isPersonalBest ? timeMs : outcome.previousBestMs,
      'solved_at': now.toUtc().toIso8601String(),
      'last_played_at': now.toUtc().toIso8601String(),
      'client_updated_at': now.toUtc().toIso8601String(),
      }));
    }
    final daily = _dailyDate;
    final onDay = daily != null && daily == localDateString(now);
    if (daily != null) {
      await ref.read(dailyRepositoryProvider).recordSolve(
            date: daily, puzzleId: puzzleId, timeMs: timeMs, onDay: onDay);
      unawaited(online.enqueue('daily_complete', {
        'date': daily,
        'time_ms': timeMs,
        'client_local_date': localDateString(now),
      }));
      unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.dailyCompleted, {
        'date': daily,
        'duration_seconds': timeMs ~/ 1000,
        'on_day': onDay ? 1 : 0,
      }));
    }

    final inCollection = set.inCollection(_puzzle.collectionId);
    final solvedBefore = inCollection.where((p) => progressBefore[p.id]?.isSolved ?? false).length;
    final solvedNow = solvedBefore + (outcome.isFirstSolve ? 1 : 0);
    final completedCollection = outcome.isFirstSolve && solvedNow == inCollection.length;

    final analytics = ref.read(analyticsProvider);
    unawaited(analytics.log(AnalyticsEvents.puzzleComplete, {
      'puzzle_id': puzzleId,
      'size': '${_puzzle.width}x${_puzzle.height}',
      'duration_seconds': timeMs ~/ 1000,
      'used_hints': state.hintsUsed,
      'is_personal_best': outcome.isPersonalBest ? 1 : 0,
    }));
    if (completedCollection) {
      unawaited(analytics.log(AnalyticsEvents.collectionComplete, {'collection_id': _puzzle.collectionId}));
    }

    ref.read(lastCompletionProvider.notifier).set(CompletionResult(
      puzzle: _puzzle,
      timeMs: timeMs,
      outcome: outcome,
      hintsUsed: state.hintsUsed,
      sizeBestMs: sizeBest,
      beatSizeBest: sizeBest == null || timeMs < sizeBest,
      collectionSolved: solvedNow,
      collectionTotal: inCollection.length,
      completedCollection: completedCollection,
      dailyDate: daily,
      dailyOnDay: onDay,
    ));
  }

  /// Logs an abandon (or an open with no move) once per session. Called when
  /// the app goes to the background or the player leaves the board.
  void logAbandon(String reason) {
    if (state.solved || _abandonLogged) return;
    _abandonLogged = true;
    final analytics = ref.read(analyticsProvider);
    if (state.moves == 0) {
      unawaited(analytics.log(AnalyticsEvents.puzzleOpenNoMove, {'puzzle_id': puzzleId}));
    } else {
      unawaited(analytics.log(AnalyticsEvents.puzzleAbandon, {
        'puzzle_id': puzzleId,
        'moves_made': state.moves,
        'duration_seconds': elapsedMs ~/ 1000,
        'reason': reason,
      }));
    }
  }

  /// A new session after returning from the background can be logged again.
  void resetAbandon() => _abandonLogged = false;
}
