// Suggests the fewest single-pixel changes that make a picture line-solvable
// and unique. Suggestions only: the author applies them by hand.

import 'dart:math';

import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/line_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/uniqueness.dart';

import 'plates.dart';

class PixelChange {
  PixelChange(this.row, this.col, this.from, this.to);

  final int row;
  final int col;
  final int from;
  final int to;

  @override
  String toString() =>
      'row ${row + 1}, col ${col + 1}: "${charForColor(from)}" -> "${charForColor(to)}"';
}

class NudgeResult {
  NudgeResult(this.changes, this.rows, this.solved);

  final List<PixelChange> changes;
  final List<String> rows;

  /// True if the changes produce a line-solvable, unique picture.
  final bool solved;
}

/// Greedy search, up to [maxChanges] flips. Each step tries flipping every
/// undecided cell and its neighbors and keeps the flip that leaves the fewest
/// undecided cells. Added pixels take the most common neighboring color.
NudgeResult nudge(Plate plate, {int maxChanges = 4, int seed = 20261102}) {
  final w = plate.width;
  final h = plate.height;
  final colors = List<int>.of(plate.colors);
  final logic = LogicSolver();
  final rng = Random(seed);
  final changes = <PixelChange>[];

  int undecided(List<int> grid) {
    final clues = Clues.fromSolution(Solution(w, h, [for (final c in grid) c != 0]));
    final trace = logic.solve(clues);
    return trace.grid.where((k) => k == Knowledge.unknown).length;
  }

  bool accepted(List<int> grid) {
    final clues = Clues.fromSolution(Solution(w, h, [for (final c in grid) c != 0]));
    return logic.solve(clues).isSolved && countSolutions(clues).isUnique;
  }

  int neighborColor(List<int> grid, int r, int c) {
    final counts = <int, int>{};
    for (final (dr, dc) in [(-1, 0), (1, 0), (0, -1), (0, 1)]) {
      final rr = r + dr, cc = c + dc;
      if (rr < 0 || rr >= h || cc < 0 || cc >= w) continue;
      final v = grid[rr * w + cc];
      if (v != 0) counts[v] = (counts[v] ?? 0) + 1;
    }
    if (counts.isEmpty) return 1;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  var current = undecided(colors);
  while (current > 0 && changes.length < maxChanges) {
    // Candidate cells: undecided ones plus their neighbors.
    final clues = Clues.fromSolution(Solution(w, h, [for (final c in colors) c != 0]));
    final trace = logic.solve(clues);
    final candidates = <int>{};
    for (var i = 0; i < w * h; i++) {
      if (trace.grid[i] != Knowledge.unknown) continue;
      final r = i ~/ w, c = i % w;
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          final rr = r + dr, cc = c + dc;
          if (rr >= 0 && rr < h && cc >= 0 && cc < w) candidates.add(rr * w + cc);
        }
      }
    }
    final ordered = candidates.toList()..shuffle(rng);

    var bestIndex = -1;
    var bestColor = 0;
    var bestScore = current;
    for (final i in ordered) {
      final trial = List<int>.of(colors);
      final r = i ~/ w, c = i % w;
      trial[i] = colors[i] == 0 ? neighborColor(colors, r, c) : 0;
      final score = undecided(trial);
      if (score < bestScore) {
        bestScore = score;
        bestIndex = i;
        bestColor = trial[i];
        if (score == 0) break;
      }
    }
    if (bestIndex < 0) break; // No single flip helps.
    changes.add(PixelChange(bestIndex ~/ w, bestIndex % w, colors[bestIndex], bestColor));
    colors[bestIndex] = bestColor;
    current = bestScore;
  }

  final rows = [
    for (var r = 0; r < h; r++)
      [for (var c = 0; c < w; c++) charForColor(colors[r * w + c])].join(),
  ];
  return NudgeResult(changes, rows, current == 0 && accepted(colors));
}
