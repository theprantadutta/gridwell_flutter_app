import '../model/board.dart';
import '../model/cell_state.dart';
import '../model/clues.dart';
import '../model/solution.dart';
import '../rules/rules.dart';
import '../solver/line_solver.dart';
import 'proven_mistake.dart';

/// The result of asking for a hint.
///
/// Only a [ResolvingHint] changes the board, so only a [ResolvingHint] can be
/// passed to the code that spends a hint or grants a rewarded-video reward.
/// A [NoHint] cannot be redeemed: that rule is enforced by the type.
sealed class HintResult {
  const HintResult();
}

/// A hint that resolves a cell. The only kind a reward can be granted for.
sealed class ResolvingHint extends HintResult {
  const ResolvingHint(this.row, this.col);

  final int row;
  final int col;
}

/// Line logic forces this cell. [value] is [CellState.filled] or
/// [CellState.crossed].
final class DeducedCellHint extends ResolvingHint {
  const DeducedCellHint({
    required int row,
    required int col,
    required this.value,
    required this.line,
    required this.clue,
    required this.lineBefore,
    required this.lineAfter,
  }) : super(row, col);

  final CellState value;

  /// The row or column whose clue forces the cell.
  final LineRef line;
  final List<int> clue;

  /// Line knowledge before and after solving it, for the explanation.
  final List<Knowledge> lineBefore;
  final List<Knowledge> lineAfter;

  int get position => line.axis == LineAxis.row ? col : row;
}

/// The board has a wrong mark. The hint points at it so it can be cleared
/// before any deduction is offered. [proof] is set when the clues rule the mark out.
final class WrongMarkHint extends ResolvingHint {
  const WrongMarkHint({required int row, required int col, this.proof})
      : super(row, col);

  final ProvenMistake? proof;
}

/// Nothing to hint: the puzzle is solved.
final class NoHint extends HintResult {
  const NoHint();
}

/// Finds the next hint for [board].
///
/// 1. If any mark is wrong, point at one (a proven one first).
/// 2. Otherwise find the line that forces a new cell, preferring a line that
///    forces a filled square (filling is what the player came for), then the
///    least reasoning: fewest unknown cells, then most cells forced. Within
///    it, a cell to fill comes before one to cross.
///
/// Deduction runs on the player's marks, and in step 2 all marks are correct,
/// so the hint follows from what is on the board.
HintResult findHint(Clues clues, Solution solution, Board board, {LineSolver? solver}) {
  final lineSolver = solver ?? LineSolver();

  // 1. Wrong marks.
  WrongMarkHint? firstWrong;
  for (var r = 0; r < board.height; r++) {
    for (var c = 0; c < board.width; c++) {
      final mark = board.at(r, c);
      if (mark == CellState.empty) continue;
      if ((mark == CellState.filled) == solution.at(r, c)) continue;
      final proof = provenMistakeAt(clues, solution, board, r, c, solver: lineSolver);
      if (proof != null) return WrongMarkHint(row: r, col: c, proof: proof);
      firstWrong ??= WrongMarkHint(row: r, col: c);
    }
  }
  if (firstWrong != null) return firstWrong;

  // 2. Deduction.
  _Candidate? best;
  void consider(LineRef ref, List<int> clue) {
    final before = knowledgeOf(board.line(ref));
    final unknown = before.where((k) => k == Knowledge.unknown).length;
    if (unknown == 0) return;
    // (No early exit on unknowns: a fill elsewhere beats a cross here.)
    final after = lineSolver.solve(clue, before);
    if (after == null) return; // Cannot happen with all-correct marks.
    var forced = 0;
    var fills = false;
    for (var i = 0; i < before.length; i++) {
      if (before[i] == Knowledge.unknown && after[i] != Knowledge.unknown) {
        forced++;
        if (after[i] == Knowledge.filled) fills = true;
      }
    }
    if (forced == 0) return;
    final current = best;
    // A line that forces a filled square beats one that only forces crosses;
    // then the least reasoning (fewest unknowns), then the most forced.
    if (current == null ||
        (fills && !current.fills) ||
        (fills == current.fills &&
            (unknown < current.unknown || (unknown == current.unknown && forced > current.forced)))) {
      best = _Candidate(ref, clue, before, after, unknown, forced, fills);
    }
  }

  for (var r = 0; r < board.height; r++) {
    consider(LineRef.row(r), clues.rows[r]);
  }
  for (var c = 0; c < board.width; c++) {
    consider(LineRef.column(c), clues.columns[c]);
  }

  final chosen = best;
  if (chosen == null) return const NoHint();

  var pos = -1;
  for (var i = 0; i < chosen.before.length && pos < 0; i++) {
    if (chosen.before[i] == Knowledge.unknown && chosen.after[i] == Knowledge.filled) pos = i;
  }
  for (var i = 0; i < chosen.before.length && pos < 0; i++) {
    if (chosen.before[i] == Knowledge.unknown && chosen.after[i] == Knowledge.empty) pos = i;
  }
  final isRow = chosen.ref.axis == LineAxis.row;
  return DeducedCellHint(
    row: isRow ? chosen.ref.index : pos,
    col: isRow ? pos : chosen.ref.index,
    value: chosen.after[pos] == Knowledge.filled ? CellState.filled : CellState.crossed,
    line: chosen.ref,
    clue: chosen.clue,
    lineBefore: List.unmodifiable(chosen.before),
    lineAfter: List.unmodifiable(chosen.after),
  );
}

class _Candidate {
  _Candidate(this.ref, this.clue, this.before, this.after, this.unknown, this.forced, this.fills);

  final LineRef ref;
  final List<int> clue;
  final List<Knowledge> before;
  final List<Knowledge> after;
  final int unknown;
  final int forced;
  final bool fills;
}
