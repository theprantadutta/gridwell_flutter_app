import 'dart:math';

import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/line_solver.dart';

/// Random solution with each cell filled with probability [density].
Solution randomSolution(Random rng, int width, int height, double density) =>
    Solution(width, height,
        List<bool>.generate(width * height, (_) => rng.nextDouble() < density));

/// Reference line solver: enumerate every placement of [blocks] in a line of
/// [line.length], keep those consistent with [line], intersect them.
///
/// Exponential, so only for short lines in tests. Returns null if no
/// placement is consistent.
List<Knowledge>? bruteForceLine(List<int> blocks, List<Knowledge> line) {
  final n = line.length;
  final placements = <List<bool>>[];

  void place(int block, int start, List<bool> cells) {
    if (block == blocks.length) {
      for (var i = 0; i < n; i++) {
        final k = line[i];
        if (k == Knowledge.filled && !cells[i]) return;
        if (k == Knowledge.empty && cells[i]) return;
      }
      placements.add(List.of(cells));
      return;
    }
    final len = blocks[block];
    for (var s = start; s + len <= n; s++) {
      for (var i = s; i < s + len; i++) {
        cells[i] = true;
      }
      place(block + 1, s + len + 1, cells);
      for (var i = s; i < s + len; i++) {
        cells[i] = false;
      }
    }
  }

  place(0, 0, List<bool>.filled(n, false));
  if (placements.isEmpty) return null;
  return List<Knowledge>.generate(n, (i) {
    final allFilled = placements.every((p) => p[i]);
    final allEmpty = placements.every((p) => !p[i]);
    if (allFilled) return Knowledge.filled;
    if (allEmpty) return Knowledge.empty;
    return Knowledge.unknown;
  });
}
