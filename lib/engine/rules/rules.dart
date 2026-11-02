import '../model/board.dart';
import '../model/cell_state.dart';
import '../model/clues.dart';
import '../model/solution.dart';
import '../solver/line_solver.dart';

/// True when the board shows the picture: every solution cell is filled and no
/// other cell is.
///
/// Crosses never matter. A player who never crosses can win, and a player who
/// crossed everything correctly but left a solution cell untouched has not won.
bool isSolved(Board board, Solution solution) {
  if (board.width != solution.width || board.height != solution.height) {
    throw ArgumentError('Board and solution sizes differ');
  }
  final cells = board.cells;
  final target = solution.cells;
  for (var i = 0; i < cells.length; i++) {
    if ((cells[i] == CellState.filled) != target[i]) return false;
  }
  return true;
}

/// Converts player marks to solver knowledge: filled -> filled,
/// crossed -> empty, untouched -> unknown.
List<Knowledge> knowledgeOf(List<CellState> cells) => [
      for (final c in cells)
        switch (c) {
          CellState.filled => Knowledge.filled,
          CellState.crossed => Knowledge.empty,
          CellState.empty => Knowledge.unknown,
        },
    ];

/// True when the filled runs in [line] are exactly [clue]. Crosses and
/// untouched cells both count as not filled.
bool lineMatchesClue(List<int> clue, List<CellState> line) {
  final runs = Clues.lineClue([for (final c in line) c == CellState.filled]);
  if (runs.length != clue.length) return false;
  for (var i = 0; i < runs.length; i++) {
    if (runs[i] != clue[i]) return false;
  }
  return true;
}

/// Indices of the clue numbers the player has visibly completed, so the UI can
/// strike them through.
///
/// - If the line's filled runs equal the clue exactly, every number is retired.
/// - Otherwise, numbers are retired from each end inward while the runs there
///   are closed off: preceded only by crosses or the edge, and ended by a
///   cross or the edge. Scanning stops at the first untouched cell, since
///   anything past it is uncertain.
Set<int> retiredClueIndices(List<int> clue, List<CellState> line) {
  final blocks = Clues.blocksOf(clue);
  if (blocks.isEmpty) {
    // `0`: retired once no cell is filled and nothing is left untouched.
    final done = line.every((c) => c == CellState.crossed);
    return done ? {0} : {};
  }
  if (lineMatchesClue(clue, line)) {
    return {for (var i = 0; i < blocks.length; i++) i};
  }

  final retired = <int>{};
  final fromLeft = _closedRuns(line);
  for (var j = 0; j < fromLeft.length && j < blocks.length; j++) {
    if (fromLeft[j] != blocks[j]) break;
    retired.add(j);
  }
  final fromRight = _closedRuns(line.reversed.toList());
  for (var j = 0; j < fromRight.length && j < blocks.length; j++) {
    final index = blocks.length - 1 - j;
    if (fromRight[j] != blocks[index]) break;
    retired.add(index);
  }
  return retired;
}

/// Lengths of runs at the start of [line] that are fully closed off, stopping
/// at the first untouched cell.
List<int> _closedRuns(List<CellState> line) {
  final runs = <int>[];
  var run = 0;
  for (final c in line) {
    switch (c) {
      case CellState.filled:
        run++;
      case CellState.crossed:
        if (run > 0) runs.add(run);
        run = 0;
      case CellState.empty:
        return runs; // A run touching an untouched cell is not closed.
    }
  }
  if (run > 0) runs.add(run);
  return runs;
}

/// Cells to cross automatically once a line's filled runs match its clue:
/// every untouched cell in the line. Returns line positions.
List<int> autoCrossPositions(List<int> clue, List<CellState> line) {
  if (!lineMatchesClue(clue, line)) return const [];
  return [
    for (var i = 0; i < line.length; i++)
      if (line[i] == CellState.empty) i,
  ];
}
