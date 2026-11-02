// The no-guessing guarantee rests on two independent implementations
// agreeing: the line-logic fixpoint solver and the backtracking solution
// counter. This file checks them against each other over a large seeded batch,
// and checks the counter itself against exhaustive enumeration on small grids.

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/line_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/uniqueness.dart';

import 'helpers.dart';

void main() {
  group('logic solver basics', () {
    test('solves a simple picture and reports passes', () {
      final s = Solution.fromRows([
        '#####',
        '#...#',
        '#.#.#',
        '#...#',
        '#####',
      ]);
      final trace = LogicSolver().solve(Clues.fromSolution(s));
      expect(trace.status, SolveStatus.solved);
      expect(trace.passes, greaterThanOrEqualTo(1));
      for (var r = 0; r < 5; r++) {
        for (var c = 0; c < 5; c++) {
          expect(trace.at(r, c) == Knowledge.filled, s.at(r, c));
        }
      }
    });

    test('stalls on a puzzle with two solutions', () {
      // The diagonal and anti-diagonal share every clue.
      final s = Solution.fromRows(['#.', '.#']);
      final clues = Clues.fromSolution(s);
      expect(LogicSolver().solve(clues).status, SolveStatus.stalled);
      expect(countSolutions(clues).count, 2);
    });

    test('stalls on a unique puzzle that needs more than line logic', () {
      // Unique, but every line is ambiguous on its own; found by search and
      // pinned here as a regression case.
      final s = _findUniqueButNotLineSolvable();
      final clues = Clues.fromSolution(s);
      expect(countSolutions(clues).isUnique, isTrue);
      expect(LogicSolver().solve(clues).status, SolveStatus.stalled);
    });

    test('reports a contradiction for impossible clues', () {
      final clues = Clues(2, 2, [
        [2],
        [2],
      ], [
        [0],
        [0],
      ]);
      expect(LogicSolver().solve(clues).status, SolveStatus.contradiction);
      expect(countSolutions(clues).count, 0);
    });

    test('empty puzzle (all [0]) is trivially solved', () {
      final s = Solution(4, 3, List.filled(12, false));
      final trace = LogicSolver().solve(Clues.fromSolution(s));
      expect(trace.status, SolveStatus.solved);
      expect(trace.passes, 1);
    });
  });

  test('uniqueness oracle matches exhaustive enumeration on small grids', () {
    final rng = Random(7);
    for (var t = 0; t < 120; t++) {
      final w = 3 + rng.nextInt(2); // 3..4
      final h = 3 + rng.nextInt(2);
      final s = randomSolution(rng, w, h, 0.3 + rng.nextDouble() * 0.4);
      final clues = Clues.fromSolution(s);
      final exhaustive = _exhaustiveCount(clues);
      final oracle = countSolutions(clues, limit: 1000);
      expect(oracle.complete, isTrue);
      expect(oracle.count, exhaustive, reason: s.toString());
    }
  });

  test('line solver and uniqueness oracle agree on a large seeded batch', () {
    final rng = Random(20261102);
    final logic = LogicSolver();
    final sizes = <(int, int, int)>[
      // (width, height, count)
      (5, 5, 1500),
      (10, 10, 1500),
      (15, 15, 400),
      (8, 12, 300),
      (12, 7, 300),
      (20, 20, 80),
    ];

    var total = 0;
    var lineSolvable = 0;
    var uniqueNotLineSolvable = 0;
    var multiple = 0;
    var skippedIncomplete = 0;

    for (final (w, h, count) in sizes) {
      for (var t = 0; t < count; t++) {
        final density = 0.35 + rng.nextDouble() * 0.35;
        final s = randomSolution(rng, w, h, density);
        final clues = Clues.fromSolution(s);
        final trace = logic.solve(clues);
        final oracle = countSolutions(clues, maxNodes: 100000);
        total++;

        final where = '${w}x$h #$t\n$s';

        // Clues derived from a real picture are never contradictory.
        expect(trace.status, isNot(SolveStatus.contradiction), reason: where);
        if (oracle.complete) {
          expect(oracle.count, greaterThanOrEqualTo(1), reason: where);
        }

        // Soundness: whatever line logic deduces matches the picture, even
        // when it stalls.
        for (var r = 0; r < h; r++) {
          for (var c = 0; c < w; c++) {
            final k = trace.at(r, c);
            if (k == Knowledge.unknown) continue;
            expect(k == Knowledge.filled, s.at(r, c), reason: 'unsound at $r,$c\n$where');
          }
        }

        if (trace.isSolved) {
          lineSolvable++;
          // Line-solvable implies unique. The oracle must agree, and must
          // finish: an incomplete answer would be a failure in the baker too.
          expect(oracle.complete, isTrue, reason: 'oracle budget\n$where');
          expect(oracle.count, 1, reason: 'line-solvable but oracle found ${oracle.count}\n$where');
        } else if (!oracle.complete) {
          // Only allowed for puzzles the baker would reject anyway.
          skippedIncomplete++;
        } else if (oracle.count >= 2) {
          multiple++;
        } else {
          uniqueNotLineSolvable++;
        }
      }
    }

    // ignore: avoid_print
    print('agreement batch: $total puzzles, $lineSolvable line-solvable (all unique), '
        '$uniqueNotLineSolvable unique but need guessing, $multiple with 2+ solutions, '
        '$skippedIncomplete oracle-incomplete (not line-solvable)');

    expect(lineSolvable, greaterThan(500), reason: 'batch must exercise the solvable path');
    expect(multiple, greaterThan(100), reason: 'batch must exercise the ambiguous path');
    expect(skippedIncomplete, lessThan(total ~/ 50));
  }, timeout: const Timeout(Duration(minutes: 10)));
}

/// Counts every grid matching [clues] by trying all 2^(w*h) fillings.
int _exhaustiveCount(Clues clues) {
  final w = clues.width;
  final h = clues.height;
  var count = 0;
  for (var mask = 0; mask < 1 << (w * h); mask++) {
    final cells = List<bool>.generate(w * h, (i) => (mask >> i) & 1 == 1);
    final candidate = Clues.fromSolution(Solution(w, h, cells));
    if (_sameClues(candidate, clues)) count++;
  }
  return count;
}

bool _sameClues(Clues a, Clues b) {
  bool same(List<List<int>> x, List<List<int>> y) {
    for (var i = 0; i < x.length; i++) {
      if (x[i].length != y[i].length) return false;
      for (var j = 0; j < x[i].length; j++) {
        if (x[i][j] != y[i][j]) return false;
      }
    }
    return true;
  }

  return same(a.rows, b.rows) && same(a.columns, b.columns);
}

/// First seeded random 6x6 that is unique but not line-solvable.
Solution _findUniqueButNotLineSolvable() {
  final rng = Random(99);
  final logic = LogicSolver();
  for (var t = 0; t < 100000; t++) {
    final s = randomSolution(rng, 6, 6, 0.5);
    final clues = Clues.fromSolution(s);
    if (logic.solve(clues).isSolved) continue;
    if (countSolutions(clues).isUnique) return s;
  }
  throw StateError('No example found');
}
