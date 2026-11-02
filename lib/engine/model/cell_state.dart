/// What the player has marked in a cell.
///
/// The three states are structurally different in the UI (solid fill, a cross
/// mark, emptiness), never distinguished by color alone.
enum CellState {
  /// Untouched.
  empty,

  /// Filled by the player.
  filled,

  /// Crossed out: the player's note that the cell is known empty. Crosses are
  /// bookkeeping only and never affect the win check.
  crossed,
}

/// Which way a line runs.
enum LineAxis { row, column }

/// A row or column of a puzzle.
class LineRef {
  const LineRef(this.axis, this.index);

  const LineRef.row(this.index) : axis = LineAxis.row;
  const LineRef.column(this.index) : axis = LineAxis.column;

  final LineAxis axis;

  /// Zero-based row or column index.
  final int index;

  @override
  bool operator ==(Object other) =>
      other is LineRef && other.axis == axis && other.index == index;

  @override
  int get hashCode => Object.hash(axis, index);

  @override
  String toString() => '${axis.name} $index';
}
