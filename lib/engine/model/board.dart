import 'cell_state.dart';

/// The player's board: one [CellState] per cell, row-major.
///
/// Immutable. Edits return a new board; at 20x20 a copy is 400 entries, which
/// is negligible next to a frame.
class Board {
  Board(this.width, this.height, List<CellState> cells)
      : _cells = List<CellState>.unmodifiable(cells) {
    if (cells.length != width * height) {
      throw ArgumentError('Expected ${width * height} cells, got ${cells.length}');
    }
  }

  Board.empty(this.width, this.height)
      : _cells = List<CellState>.filled(width * height, CellState.empty);

  final int width;
  final int height;
  final List<CellState> _cells;

  List<CellState> get cells => _cells;

  CellState at(int row, int col) => _cells[row * width + col];

  List<CellState> row(int r) => _cells.sublist(r * width, (r + 1) * width);

  List<CellState> column(int c) =>
      List<CellState>.generate(height, (r) => _cells[r * width + c]);

  List<CellState> line(LineRef ref) =>
      ref.axis == LineAxis.row ? row(ref.index) : column(ref.index);

  Board withCell(int row, int col, CellState state) {
    final next = List<CellState>.of(_cells);
    next[row * width + col] = state;
    return Board(width, height, next);
  }

  /// Applies several edits at once. Keys are row-major cell indices.
  Board withCells(Map<int, CellState> edits) {
    if (edits.isEmpty) return this;
    final next = List<CellState>.of(_cells);
    edits.forEach((index, state) => next[index] = state);
    return Board(width, height, next);
  }

  int count(CellState state) => _cells.where((c) => c == state).length;

  @override
  bool operator ==(Object other) {
    if (other is! Board || other.width != width || other.height != height) {
      return false;
    }
    for (var i = 0; i < _cells.length; i++) {
      if (_cells[i] != other._cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(width, height, Object.hashAll(_cells));
}
