import '../model/clues.dart';
import 'line_solver.dart';

/// Outcome of running line logic to a fixpoint.
enum SolveStatus {
  /// Every cell was deduced. The puzzle needs no guessing.
  solved,

  /// A full pass produced nothing new while cells were still unknown. The
  /// puzzle needs guessing or techniques beyond line logic.
  stalled,

  /// The clues (plus any starting knowledge) cannot all be satisfied.
  contradiction,
}

/// What happened during a fixpoint solve. Feeds difficulty scoring.
class SolveTrace {
  SolveTrace({
    required this.status,
    required this.width,
    required this.height,
    required List<Knowledge> grid,
    required List<int> newCellsPerPass,
    required this.maxAmbiguity,
    required this.lineSolves,
  })  : grid = List.unmodifiable(grid),
        newCellsPerPass = List.unmodifiable(newCellsPerPass);

  final SolveStatus status;
  final int width;
  final int height;

  /// Final knowledge, row-major.
  final List<Knowledge> grid;

  /// Cells newly determined in each productive pass. Its length is the number
  /// of passes needed; a pass is one sweep over every row, then every column.
  final List<int> newCellsPerPass;

  /// The most unknown cells a single line still had when it produced new
  /// information, counted from the second pass on. The first pass always
  /// starts from a blank grid, so counting it would only measure line length.
  final int maxAmbiguity;

  /// Line solves performed (including ones that found nothing).
  final int lineSolves;

  int get passes => newCellsPerPass.length;

  bool get isSolved => status == SolveStatus.solved;

  Knowledge at(int row, int col) => grid[row * width + col];
}

/// Runs the line solver over every row and column until nothing changes.
class LogicSolver {
  LogicSolver({LineSolver? lineSolver}) : lineSolver = lineSolver ?? LineSolver();

  final LineSolver lineSolver;

  /// Solves [clues] from a blank grid, or from [initial] knowledge if given
  /// (row-major, width x height).
  SolveTrace solve(Clues clues, {List<Knowledge>? initial}) {
    final w = clues.width;
    final h = clues.height;
    final grid = initial == null
        ? List<Knowledge>.filled(w * h, Knowledge.unknown)
        : List<Knowledge>.of(initial);
    if (grid.length != w * h) {
      throw ArgumentError('initial must have ${w * h} cells');
    }

    final rowDirty = List<bool>.filled(h, true);
    final colDirty = List<bool>.filled(w, true);
    var unknown = grid.where((k) => k == Knowledge.unknown).length;
    final perPass = <int>[];
    var maxAmbiguity = 0;
    var lineSolves = 0;
    var contradiction = false;

    while (unknown > 0) {
      final passIndex = perPass.length;
      var progress = 0;

      // One step over a line. Returns false on contradiction.
      bool step(List<int> clue, int length, int Function(int) cellIndex,
          void Function(int) markCrossDirty) {
        var unknownBefore = 0;
        final line = List<Knowledge>.generate(length, (i) {
          final value = grid[cellIndex(i)];
          if (value == Knowledge.unknown) unknownBefore++;
          return value;
        });
        if (unknownBefore == 0) return true;
        lineSolves++;
        final solved = lineSolver.solve(clue, line);
        if (solved == null) return false;
        var changed = 0;
        for (var i = 0; i < length; i++) {
          if (line[i] == Knowledge.unknown && solved[i] != Knowledge.unknown) {
            grid[cellIndex(i)] = solved[i];
            markCrossDirty(i);
            changed++;
          }
        }
        if (changed > 0) {
          progress += changed;
          unknown -= changed;
          if (passIndex > 0 && unknownBefore > maxAmbiguity) {
            maxAmbiguity = unknownBefore;
          }
        }
        return true;
      }

      for (var r = 0; r < h && !contradiction; r++) {
        if (!rowDirty[r]) continue;
        rowDirty[r] = false;
        contradiction = !step(clues.rows[r], w, (c) => r * w + c,
            (c) => colDirty[c] = true);
      }
      for (var c = 0; c < w && !contradiction; c++) {
        if (!colDirty[c]) continue;
        colDirty[c] = false;
        contradiction = !step(clues.columns[c], h, (r) => r * w + c,
            (r) => rowDirty[r] = true);
      }

      if (contradiction || progress == 0) break;
      perPass.add(progress);
    }

    // A fully known grid can still violate a clue (e.g. bad initial
    // knowledge). Verify every line once more when nothing is unknown.
    if (!contradiction && unknown == 0) {
      contradiction = !_allLinesConsistent(clues, grid);
    }

    return SolveTrace(
      status: contradiction
          ? SolveStatus.contradiction
          : (unknown == 0 ? SolveStatus.solved : SolveStatus.stalled),
      width: w,
      height: h,
      grid: grid,
      newCellsPerPass: perPass,
      maxAmbiguity: maxAmbiguity,
      lineSolves: lineSolves,
    );
  }

  bool _allLinesConsistent(Clues clues, List<Knowledge> grid) {
    final w = clues.width;
    final h = clues.height;
    for (var r = 0; r < h; r++) {
      final line = [for (var c = 0; c < w; c++) grid[r * w + c] == Knowledge.filled];
      if (!_sameClue(Clues.lineClue(line), clues.rows[r])) return false;
    }
    for (var c = 0; c < w; c++) {
      final line = [for (var r = 0; r < h; r++) grid[r * w + c] == Knowledge.filled];
      if (!_sameClue(Clues.lineClue(line), clues.columns[c])) return false;
    }
    return true;
  }

  static bool _sameClue(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
