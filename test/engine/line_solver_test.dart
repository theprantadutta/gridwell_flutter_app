import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/solver/line_solver.dart';

import 'helpers.dart';

const U = Knowledge.unknown;
const F = Knowledge.filled;
const E = Knowledge.empty;

List<Knowledge> parse(String s) => [
      for (final ch in s.split(''))
        ch == '#' ? F : (ch == '.' ? E : U),
    ];

String show(List<Knowledge>? line) => line == null
    ? 'contradiction'
    : line.map((k) => k == F ? '#' : (k == E ? '.' : '?')).join();

void main() {
  group('known lines', () {
    test('a 7 in 10 cells covers squares 4 to 7 (onboarding example)', () {
      expect(show(solveLine([7], parse('??????????'))), '???####???');
    });

    test('a full-length run fills the line', () {
      expect(show(solveLine([5], parse('?????'))), '#####');
    });

    test('runs that exactly fill the line with gaps', () {
      expect(show(solveLine([2, 1, 1], parse('??????'))), '##.#.#');
    });

    test('an empty clue forces every cell empty', () {
      expect(show(solveLine([], parse('????'))), '....');
    });

    test('a filled cell anchors a run', () {
      // The 3 must cover index 1, so it starts at 0 or 1: indices 1-2 are
      // filled either way, and nothing past index 3 can be reached.
      expect(show(solveLine([3], parse('?#????????'))), '?##?......');
    });

    test('crosses split the line', () {
      // A 3 cannot fit left of the cross at index 2, so it sits in 3..7 and
      // index 5 is covered in every placement.
      expect(show(solveLine([3], parse('??.?????'))), '...??#??');
      expect(show(solveLine([3], parse('??.???'))), '...###');
    });

    test('contradictions return null', () {
      expect(solveLine([3], parse('?.?.?')), isNull);
      expect(solveLine([1], parse('##???')), isNull);
      expect(solveLine([], parse('?#?')), isNull);
      expect(solveLine([2, 2], parse('????')), isNull);
    });

    test('a complete consistent line is returned unchanged', () {
      expect(show(solveLine([2, 1], parse('##..#'))), '##..#');
    });
  });

  test('matches brute-force enumeration on 60,000 random lines', () {
    final rng = Random(20261102);
    var compared = 0;
    var contradictions = 0;
    for (var t = 0; t < 60000; t++) {
      final n = 1 + rng.nextInt(15);
      // Clue from a random line, so most cases are satisfiable.
      final truth = List<bool>.generate(n, (_) => rng.nextDouble() < 0.55);
      var blocks = Clues.blocksOf(Clues.lineClue(truth));
      // Sometimes use a random clue instead, to exercise contradictions.
      if (rng.nextInt(10) == 0) {
        blocks = [for (var i = 0; i < rng.nextInt(4); i++) 1 + rng.nextInt(n)];
      }
      // Reveal some cells: usually from the truth, sometimes at random.
      final line = List<Knowledge>.generate(n, (i) {
        final roll = rng.nextDouble();
        if (roll < 0.55) return U;
        if (rng.nextInt(12) == 0) return rng.nextBool() ? F : E;
        return truth[i] ? F : E;
      });

      final expected = bruteForceLine(blocks, line);
      final actual = solveLine(blocks, line);
      expect(show(actual), show(expected),
          reason: 'blocks=$blocks line=${show(line)}');
      compared++;
      if (expected == null) contradictions++;
    }
    expect(compared, 60000);
    expect(contradictions, greaterThan(100), reason: 'contradiction path exercised');
  });

  test('memoized solver returns identical results and hits the cache', () {
    final solver = LineSolver();
    final a = solver.solve([3, 1], parse('????????'));
    final b = solver.solve([3, 1], parse('????????'));
    expect(show(a), show(b));
    expect(solver.cacheHits, 1);
    expect(solver.cacheMisses, 1);
    // [0] display convention is handled.
    expect(show(solver.solve([0], parse('???'))), '...');
  });

  test('pathological long line with many short runs is fast', () {
    // 60 cells, 20 runs of 1: placements number in the trillions.
    final sw = Stopwatch()..start();
    final result = solveLine(List.filled(20, 1), List.filled(60, U));
    sw.stop();
    expect(result, isNotNull);
    expect(sw.elapsedMilliseconds, lessThan(200));
  });
}
