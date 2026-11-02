import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/engine/model/board.dart';
import 'package:gridwell_flutter_app/engine/model/cell_state.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/rules/rules.dart';

const F = CellState.filled;
const X = CellState.crossed;
const E = CellState.empty;

void main() {
  group('clue derivation', () {
    test('runs left to right and top to bottom, [0] for empty lines', () {
      final s = Solution.fromRows([
        '##.#.',
        '.....',
        '#####',
      ]);
      final clues = Clues.fromSolution(s);
      expect(clues.rows, [
        [2, 1],
        [0],
        [5],
      ]);
      expect(clues.columns, [
        [1, 1],
        [1, 1],
        [1],
        [1, 1],
        [1],
      ]);
    });

    test('rectangular grids', () {
      final s = Solution.fromRows(['#.#', '###']);
      final clues = Clues.fromSolution(s);
      expect(clues.width, 3);
      expect(clues.height, 2);
      expect(clues.rows, [
        [1, 1],
        [3],
      ]);
      expect(clues.columns, [
        [2],
        [1],
        [2],
      ]);
    });

    test('blocksOf strips the [0] convention', () {
      expect(Clues.blocksOf([0]), isEmpty);
      expect(Clues.blocksOf([3, 1]), [3, 1]);
    });
  });

  group('win check', () {
    final s = Solution.fromRows(['#.', '.#']);

    test('filling exactly the solution wins without any crosses', () {
      final b = Board(2, 2, [F, E, E, F]);
      expect(isSolved(b, s), isTrue);
    });

    test('crosses never affect the result', () {
      expect(isSolved(Board(2, 2, [F, X, X, F]), s), isTrue);
      expect(isSolved(Board(2, 2, [F, X, E, F]), s), isTrue);
    });

    test('every empty cell crossed but a solution cell untouched is not a win', () {
      expect(isSolved(Board(2, 2, [F, X, X, E]), s), isFalse);
    });

    test('an extra filled cell blocks the win', () {
      expect(isSolved(Board(2, 2, [F, F, E, F]), s), isFalse);
    });

    test('filling everything does not win', () {
      expect(isSolved(Board(2, 2, [F, F, F, F]), s), isFalse);
    });
  });

  group('retired clues', () {
    test('everything retires when the runs match exactly', () {
      expect(retiredClueIndices([2, 1], [F, F, E, F, E]), {0, 1});
    });

    test('closed runs retire from the left', () {
      expect(retiredClueIndices([1, 1, 1], [F, X, E, E, E, E]), {0});
    });

    test('closed runs retire from the right', () {
      expect(retiredClueIndices([1, 1, 1], [E, E, E, E, X, F]), {2});
    });

    test('a run touching an untouched cell is not closed', () {
      expect(retiredClueIndices([2, 1], [F, F, E, E, E]), <int>{});
    });

    test('a run of the wrong length does not retire', () {
      expect(retiredClueIndices([2, 1], [F, X, E, E, E]), <int>{});
    });

    test('[0] retires only when the line is all crosses', () {
      expect(retiredClueIndices([0], [X, X, X]), {0});
      expect(retiredClueIndices([0], [X, E, X]), <int>{});
    });
  });

  test('auto-cross fills the rest of a matched line', () {
    expect(autoCrossPositions([2], [E, F, F, E, X]), [0, 3]);
    expect(autoCrossPositions([2], [E, F, E, E, X]), isEmpty);
  });
}
