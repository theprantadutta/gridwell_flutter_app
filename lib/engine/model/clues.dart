import 'solution.dart';

/// Row and column clues: the lengths of consecutive filled runs.
///
/// Rows read left to right, columns top to bottom. An empty line has the
/// clue `[0]`, as players expect to see it. Use [blocksOf] to get the run
/// lengths with the `[0]` convention removed.
class Clues {
  Clues(this.width, this.height, List<List<int>> rows, List<List<int>> columns)
      : rows = List.unmodifiable(rows.map((r) => List<int>.unmodifiable(r))),
        columns =
            List.unmodifiable(columns.map((c) => List<int>.unmodifiable(c))) {
    if (rows.length != height || columns.length != width) {
      throw ArgumentError(
        'Expected $height row clues and $width column clues, '
        'got ${rows.length} and ${columns.length}',
      );
    }
  }

  factory Clues.fromSolution(Solution s) => Clues(
        s.width,
        s.height,
        [for (var r = 0; r < s.height; r++) lineClue(s.row(r))],
        [for (var c = 0; c < s.width; c++) lineClue(s.column(c))],
      );

  final int width;
  final int height;
  final List<List<int>> rows;
  final List<List<int>> columns;

  /// Clue for one line of booleans. Returns `[0]` for an empty line.
  static List<int> lineClue(List<bool> line) {
    final runs = <int>[];
    var run = 0;
    for (final filled in line) {
      if (filled) {
        run++;
      } else if (run > 0) {
        runs.add(run);
        run = 0;
      }
    }
    if (run > 0) runs.add(run);
    return runs.isEmpty ? const [0] : runs;
  }

  /// Run lengths without the `[0]` convention: an empty line gives `[]`.
  static List<int> blocksOf(List<int> clue) =>
      (clue.length == 1 && clue[0] == 0) ? const [] : clue;
}
