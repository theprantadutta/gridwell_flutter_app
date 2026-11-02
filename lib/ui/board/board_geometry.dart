import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../engine/model/clues.dart';

/// Where everything on the board sits, in logical pixels.
///
/// The grid is the hero: it gets the largest square cell that fits after the
/// clue strips are reserved. Clue strips scale with the cell so numbers stay
/// proportionate at every size.
class BoardGeometry {
  BoardGeometry._({
    required this.columns,
    required this.rows,
    required this.cell,
    required this.rowClueWidth,
    required this.colClueHeight,
    required this.clueSize,
    required this.clueGap,
  });

  /// Fits a [clues] board into [available].
  factory BoardGeometry.fit(Clues clues, Size available, {double maxCell = 56}) {
    final rowSlots = clues.rows.map((r) => r.length).fold<int>(1, math.max);
    final colSlots = clues.columns.map((c) => c.length).fold<int>(1, math.max);
    // Each clue number takes about 0.62 of a cell horizontally (row clues)
    // and 0.72 of a cell vertically (column clues), plus a small gap.
    const rowSlot = 0.64, colSlot = 0.74, gapCells = 0.35;
    final widthInCells = clues.width + rowSlots * rowSlot + gapCells;
    final heightInCells = clues.height + colSlots * colSlot + gapCells;
    final cell = math.min(
      maxCell,
      math.min(available.width / widthInCells, available.height / heightInCells),
    ).floorToDouble().clamp(6.0, maxCell);
    return BoardGeometry._(
      columns: clues.width,
      rows: clues.height,
      cell: cell,
      rowClueWidth: (rowSlots * rowSlot + gapCells) * cell,
      colClueHeight: (colSlots * colSlot + gapCells) * cell,
      clueSize: (cell * 0.6).clamp(8.0, 26.0),
      clueGap: gapCells * cell,
    );
  }

  final int columns;
  final int rows;
  final double cell;
  final double rowClueWidth;
  final double colClueHeight;
  final double clueSize;
  final double clueGap;

  Offset get gridOrigin => Offset(rowClueWidth, colClueHeight);
  Size get gridSize => Size(columns * cell, rows * cell);
  Size get totalSize => Size(rowClueWidth + gridSize.width, colClueHeight + gridSize.height);
  Rect get gridRect => gridOrigin & gridSize;

  Rect cellRect(int row, int col) =>
      Rect.fromLTWH(rowClueWidth + col * cell, colClueHeight + row * cell, cell, cell);

  /// Cell under [p] (in board coordinates), clamped into the grid when
  /// [clamp] is true, otherwise null if outside.
  (int, int)? cellAt(Offset p, {bool clamp = false}) {
    final x = (p.dx - rowClueWidth) / cell;
    final y = (p.dy - colClueHeight) / cell;
    if (!clamp && (x < 0 || y < 0 || x >= columns || y >= rows)) return null;
    return (y.floor().clamp(0, rows - 1), x.floor().clamp(0, columns - 1));
  }
}
