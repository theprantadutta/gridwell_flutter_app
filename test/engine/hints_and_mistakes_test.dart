import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/engine/hints/hint.dart';
import 'package:gridwell_flutter_app/engine/hints/proven_mistake.dart';
import 'package:gridwell_flutter_app/engine/model/board.dart';
import 'package:gridwell_flutter_app/engine/model/cell_state.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/rules/rules.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';

import 'helpers.dart';

/// Seeded line-solvable puzzles.
List<Solution> _solvable(int seed, int count, int size) {
  final rng = Random(seed);
  final logic = LogicSolver();
  final out = <Solution>[];
  while (out.length < count) {
    final s = randomSolution(rng, size, size, 0.45 + rng.nextDouble() * 0.2);
    if (logic.solve(Clues.fromSolution(s)).isSolved) out.add(s);
  }
  return out;
}

Board _apply(Board b, ResolvingHint hint) => switch (hint) {
      DeducedCellHint h => b.withCell(h.row, h.col, h.value),
      WrongMarkHint h => b.withCell(h.row, h.col, CellState.empty),
    };

void main() {
  group('hints', () {
    test('following hints from a blank board solves every puzzle, each hint correct', () {
      for (final s in [..._solvable(11, 25, 10), ..._solvable(12, 5, 15)]) {
        final clues = Clues.fromSolution(s);
        var board = Board.empty(s.width, s.height);
        var steps = 0;
        while (true) {
          final hint = findHint(clues, s, board);
          if (hint is NoHint) break;
          expect(hint, isA<DeducedCellHint>());
          final h = hint as DeducedCellHint;
          expect(board.at(h.row, h.col), CellState.empty, reason: 'hint on a known cell');
          expect(h.value == CellState.filled, s.at(h.row, h.col), reason: 'wrong hint');
          board = _apply(board, h);
          steps++;
          expect(steps, lessThanOrEqualTo(s.cellCount));
        }
        expect(isSolved(board, s), isTrue);
        expect(board.count(CellState.empty), 0);
      }
    });

    test('a wrong mark is pointed out before any deduction', () {
      final s = _solvable(13, 1, 10).single;
      final clues = Clues.fromSolution(s);
      // Fill one cell that should be empty.
      var wrong = -1;
      for (var i = 0; i < s.cellCount && wrong < 0; i++) {
        if (!s.cells[i]) wrong = i;
      }
      final r = wrong ~/ s.width, c = wrong % s.width;
      final board = Board.empty(s.width, s.height).withCell(r, c, CellState.filled);
      final hint = findHint(clues, s, board);
      expect(hint, isA<WrongMarkHint>());
      expect((hint as WrongMarkHint).row, r);
      expect(hint.col, c);
    });

    test('a solved board has no hint, and NoHint is not redeemable', () {
      final s = Solution.fromRows(['##', '#.']);
      final board = Board(2, 2, [CellState.filled, CellState.filled, CellState.filled, CellState.empty]);
      final hint = findHint(Clues.fromSolution(s), s, board);
      // The remaining untouched cell is empty in the solution, so a cross is
      // still a deducible hint until it is marked.
      expect(hint, isA<DeducedCellHint>());
      final done = _apply(board, hint as ResolvingHint);
      final none = findHint(Clues.fromSolution(s), s, done);
      expect(none, isA<NoHint>());
      expect(none is ResolvingHint, isFalse);
    });
  });

  group('proven mistakes', () {
    test('the design example: a single 3 anchored at column 8 rules out column 5', () {
      // One row, 15 wide. The 3 sits at columns 7-9 (0-based); the player has
      // filled column 7 correctly and column 4 wrongly.
      final s = Solution.fromRows(['.......###.....']);
      final clues = Clues.fromSolution(s);
      final board = Board.empty(15, 1)
          .withCell(0, 7, CellState.filled)
          .withCell(0, 4, CellState.filled);
      final m = provenMistakeAt(clues, s, board, 0, 4);
      expect(m, isNotNull);
      expect(m!.line, const LineRef.row(0));
      expect(m.clue, [3]);
    });

    test('a wrong mark the clues cannot yet rule out is not flagged', () {
      // Row 0 is a single 3 at columns 5-7; column 0's only cell is in row 1.
      // With nothing else marked, a 3 could start at column 0 and column 0's
      // 1 could sit in row 0, so neither line rules the mark out.
      final s = Solution.fromRows(['.....###..', '#.........']);
      final clues = Clues.fromSolution(s);
      final board = Board.empty(10, 2).withCell(0, 0, CellState.filled);
      expect(provenMistakeAt(clues, s, board, 0, 0), isNull);
    });

    test('a wrong cross can be proven too', () {
      final s = Solution.fromRows(['#####']);
      final board = Board.empty(5, 1).withCell(0, 2, CellState.crossed);
      expect(provenMistakeAt(Clues.fromSolution(s), s, board, 0, 2), isNotNull);
    });

    test('a correct cell is never flagged, even next to wrong marks', () {
      final rng = Random(31);
      for (final s in _solvable(14, 40, 10)) {
        final clues = Clues.fromSolution(s);
        // Random marks: mostly correct, some deliberately wrong.
        final cells = List<CellState>.generate(s.cellCount, (i) {
          final roll = rng.nextDouble();
          if (roll < 0.4) return CellState.empty;
          final correct = s.cells[i] ? CellState.filled : CellState.crossed;
          final wrong = s.cells[i] ? CellState.crossed : CellState.filled;
          return roll < 0.9 ? correct : wrong;
        });
        final board = Board(s.width, s.height, cells);
        for (final m in provenMistakes(clues, s, board)) {
          final mark = board.at(m.row, m.col);
          expect((mark == CellState.filled) != s.at(m.row, m.col), isTrue,
              reason: 'flagged a correct cell at ${m.row},${m.col}');
        }
      }
    });
  });
}
