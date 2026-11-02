/// The picture a puzzle hides: a width x height grid of filled/empty cells.
///
/// Stored row-major. Not necessarily square.
class Solution {
  Solution(this.width, this.height, List<bool> cells)
      : _cells = List<bool>.unmodifiable(cells) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Solution must be at least 1x1 (got ${width}x$height)');
    }
    if (cells.length != width * height) {
      throw ArgumentError('Expected ${width * height} cells, got ${cells.length}');
    }
  }

  /// Builds a solution from text rows, `#` for filled and anything else empty.
  factory Solution.fromRows(List<String> rows) {
    if (rows.isEmpty) throw ArgumentError('No rows');
    final width = rows.first.length;
    final cells = <bool>[];
    for (final row in rows) {
      if (row.length != width) {
        throw ArgumentError('Ragged rows: expected width $width, got "$row"');
      }
      for (var i = 0; i < row.length; i++) {
        cells.add(row[i] == '#');
      }
    }
    return Solution(width, rows.length, cells);
  }

  final int width;
  final int height;
  final List<bool> _cells;

  /// All cells, row-major.
  List<bool> get cells => _cells;

  int get cellCount => width * height;

  bool at(int row, int col) => _cells[row * width + col];

  List<bool> row(int r) => _cells.sublist(r * width, (r + 1) * width);

  List<bool> column(int c) =>
      List<bool>.generate(height, (r) => _cells[r * width + c]);

  int get filledCount => _cells.where((c) => c).length;

  /// Fraction of cells that are filled, 0..1.
  double get density => filledCount / cellCount;

  /// Text form, one string per row, `#` filled and `.` empty.
  List<String> toRows() => List<String>.generate(
        height,
        (r) => row(r).map((c) => c ? '#' : '.').join(),
      );

  @override
  bool operator ==(Object other) {
    if (other is! Solution || other.width != width || other.height != height) {
      return false;
    }
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != other._cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(_cells));

  @override
  String toString() => 'Solution(${width}x$height)\n${toRows().join('\n')}';
}
