import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/engine/difficulty/difficulty.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';

import 'helpers.dart';

(DifficultyMetrics, double) _score(Solution s) {
  final trace = LogicSolver().solve(Clues.fromSolution(s));
  final m = DifficultyMetrics.measure(s, trace);
  return (m, difficultyScore(m));
}

void main() {
  test('weights sum to 1 and size is the weakest', () {
    const w = [
      DifficultyWeights.passes,
      DifficultyWeights.earlyGiveaway,
      DifficultyWeights.ambiguity,
      DifficultyWeights.density,
      DifficultyWeights.size,
    ];
    expect(w.reduce((a, b) => a + b), closeTo(1, 1e-9));
    for (final other in w.take(4)) {
      expect(DifficultyWeights.size, lessThan(other));
    }
  });

  test('a large board that solves itself scores below a small board full of deduction', () {
    // 20x20 where every row is full or empty: the first sweep of rows
    // determines every cell.
    final big = Solution.fromRows([
      for (var r = 0; r < 20; r++) (r % 3 == 0 ? '.' : '#') * 20,
    ]);
    final (bigMetrics, bigScore) = _score(big);
    expect(bigMetrics.passes, 1);

    // The 10x10 that needs the most passes among seeded random candidates.
    final rng = Random(4242);
    final logic = LogicSolver();
    Solution? hard;
    var hardPasses = 0;
    for (var t = 0; t < 3000; t++) {
      final s = randomSolution(rng, 10, 10, 0.5);
      final trace = logic.solve(Clues.fromSolution(s));
      if (trace.isSolved && trace.passes > hardPasses) {
        hard = s;
        hardPasses = trace.passes;
      }
    }
    expect(hard, isNotNull);
    final (hardMetrics, hardScore) = _score(hard!);

    expect(hardMetrics.passes, greaterThan(3));
    expect(bigScore, lessThan(hardScore),
        reason: 'big=$bigScore ($bigMetrics) hard=$hardScore ($hardMetrics). '
            'If this inverts, size is driving the curve.');
  });

  test('scores stay within 0..100', () {
    final rng = Random(1);
    final logic = LogicSolver();
    var checked = 0;
    while (checked < 200) {
      final size = [5, 10, 15][rng.nextInt(3)];
      final s = randomSolution(rng, size, size, 0.3 + rng.nextDouble() * 0.5);
      final trace = logic.solve(Clues.fromSolution(s));
      if (!trace.isSolved) continue;
      final score = difficultyScore(DifficultyMetrics.measure(s, trace));
      expect(score, inInclusiveRange(0, 100));
      checked++;
    }
  });

  test('measuring a stalled puzzle is rejected', () {
    final s = Solution.fromRows(['#.', '.#']);
    final trace = LogicSolver().solve(Clues.fromSolution(s));
    expect(() => DifficultyMetrics.measure(s, trace), throwsArgumentError);
  });
}
