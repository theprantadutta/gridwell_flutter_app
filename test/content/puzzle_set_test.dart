import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/content/puzzle_set.dart';
import 'package:gridwell_flutter_app/engine/model/clues.dart';
import 'package:gridwell_flutter_app/engine/model/puzzle.dart';
import 'package:gridwell_flutter_app/engine/model/solution.dart';
import 'package:gridwell_flutter_app/engine/solver/logic_solver.dart';
import 'package:gridwell_flutter_app/engine/solver/uniqueness.dart';

import '../../tool/content/bake.dart';

void main() {
  test('codec round-trips a set, including rectangles and colors', () {
    final a = Solution.fromRows(['#.#', '###']);
    final b = Solution.fromRows(['#####', '#...#', '#####']);
    final set = PuzzleSet(
      puzzleSetVersion: 7,
      seed: 42,
      collections: const [CollectionInfo(id: 'c', name: 'Cé', blurb: 'Blurb · two')],
      puzzles: [
        PuzzleRecord(
          id: 'c-a',
          name: 'A',
          solution: a,
          clues: Clues.fromSolution(a),
          difficulty: 12.34,
          collectionId: 'c',
          plateNumber: 1,
          colorLayer: const [2, 0, 3, 1, 4, 5],
        ),
        PuzzleRecord(
          id: 'c-b',
          name: 'B',
          solution: b,
          clues: Clues.fromSolution(b),
          difficulty: 99.99,
          collectionId: 'c',
          plateNumber: 2,
        ),
      ],
    );
    final decoded = PuzzleSetCodec.decode(PuzzleSetCodec.encode(set));
    expect(decoded.puzzleSetVersion, 7);
    expect(decoded.seed, 42);
    expect(decoded.collections.single.name, 'Cé');
    expect(decoded.collections.single.blurb, 'Blurb · two');
    expect(decoded.puzzles, hasLength(2));
    expect(decoded.puzzles[0].solution, a);
    expect(decoded.puzzles[0].colorLayer, [2, 0, 3, 1, 4, 5]);
    expect(decoded.puzzles[0].difficulty, 12.34);
    expect(decoded.puzzles[1].solution, b);
    expect(decoded.puzzles[1].clues.rows, Clues.fromSolution(b).rows);
    expect(decoded.puzzles[1].plateNumber, 2);
  });

  test('decoding rejects garbage and truncation', () {
    expect(() => PuzzleSetCodec.decode(Uint8List.fromList([1, 2, 3, 4, 5])), throwsFormatException);
    final bytes = File('assets/puzzles/set.bin').readAsBytesSync();
    expect(() => PuzzleSetCodec.decode(bytes.sublist(0, bytes.length - 3)), throwsFormatException);
  });

  group('shipped asset', () {
    final bytes = File('assets/puzzles/set.bin').readAsBytesSync();
    final set = PuzzleSetCodec.decode(bytes);

    test('rebuilds byte for byte from content/ with the default seed', () {
      final result = bake(Directory('content'));
      expect(result.errors, isEmpty, reason: result.errors.join('\n'));
      expect(result.bytes, bytes,
          reason: 'assets/puzzles/set.bin is stale or the bake is not deterministic. '
              'Run: dart run tool/gridwell.dart bake');
      expect(result.dailyJson, File('content/daily_pool.json').readAsStringSync());
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('every shipped puzzle is line-solvable and unique', () {
      final logic = LogicSolver();
      for (final p in set.puzzles) {
        expect(logic.solve(p.clues).isSolved, isTrue, reason: p.id);
        expect(countSolutions(p.clues).isUnique, isTrue, reason: p.id);
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('plates are numbered 1..n within each collection', () {
      for (final c in set.collections) {
        final plates = set.inCollection(c.id).map((p) => p.plateNumber).toList();
        expect(plates, List.generate(plates.length, (i) => i + 1), reason: c.id);
      }
    });
  });
}
