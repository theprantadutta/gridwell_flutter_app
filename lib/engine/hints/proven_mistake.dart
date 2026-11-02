import '../model/board.dart';
import '../model/cell_state.dart';
import '../model/clues.dart';
import '../model/solution.dart';
import '../rules/rules.dart';
import '../solver/line_solver.dart';

/// A player mark that is wrong and that the clues can be shown to rule out.
class ProvenMistake {
  const ProvenMistake({
    required this.row,
    required this.col,
    required this.line,
    required this.clue,
    required this.lineBefore,
  });

  final int row;
  final int col;

  /// The row or column whose clue rules the mark out.
  final LineRef line;

  /// That line's clue (display form).
  final List<int> clue;

  /// The player's marks in that line, with the mistaken cell treated as
  /// untouched. This is the evidence the explanation is built from.
  final List<Knowledge> lineBefore;

  /// Position of the mistaken cell within [line].
  int get position => line.axis == LineAxis.row ? col : row;
}

/// Whether the mark at ([row], [col]) is a proven mistake.
///
/// Both conditions must hold:
/// 1. The mark contradicts the solution.
/// 2. The cell's own row or column, using only the player's other marks in
///    that line, forces the opposite value.
///
/// Requiring (1) means a correct cell is never flagged, even when an earlier
/// wrong mark makes it look impossible. Requiring (2) means every flag comes
/// with an explanation the player can check from the clues alone. Rows are
/// tried before columns.
ProvenMistake? provenMistakeAt(
  Clues clues,
  Solution solution,
  Board board,
  int row,
  int col, {
  LineSolver? solver,
}) {
  final mark = board.at(row, col);
  if (mark == CellState.empty) return null;
  final shouldFill = solution.at(row, col);
  final markIsFill = mark == CellState.filled;
  if (markIsFill == shouldFill) return null; // Correct mark.

  final lineSolver = solver ?? LineSolver();
  final forbidden = markIsFill ? Knowledge.empty : Knowledge.filled;

  for (final ref in [LineRef.row(row), LineRef.column(col)]) {
    final pos = ref.axis == LineAxis.row ? col : row;
    final clue = ref.axis == LineAxis.row ? clues.rows[row] : clues.columns[col];
    final before = knowledgeOf(board.line(ref));
    before[pos] = Knowledge.unknown;
    final solved = lineSolver.solve(clue, before);
    // A contradiction means the player's other marks in this line are already
    // inconsistent, so this line proves nothing about this cell specifically.
    if (solved != null && solved[pos] == forbidden) {
      return ProvenMistake(
        row: row,
        col: col,
        line: ref,
        clue: clue,
        lineBefore: List.unmodifiable(before),
      );
    }
  }
  return null;
}

/// Every proven mistake on the board, in row-major order.
List<ProvenMistake> provenMistakes(Clues clues, Solution solution, Board board) {
  final solver = LineSolver();
  final out = <ProvenMistake>[];
  for (var r = 0; r < board.height; r++) {
    for (var c = 0; c < board.width; c++) {
      final m = provenMistakeAt(clues, solution, board, r, c, solver: solver);
      if (m != null) out.add(m);
    }
  }
  return out;
}
