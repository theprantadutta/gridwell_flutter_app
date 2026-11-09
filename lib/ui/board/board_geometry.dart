import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../../engine/model/clues.dart';
import '../theme/typography.dart';

/// Where everything on the board sits, in logical pixels (Tally, DESIGN-SPEC
/// section 5).
///
/// The grid is the hero: it gets the largest square pitch that fits after the
/// clue strips are reserved. Cells are `pitch - gap` squares; the gap (1 pt,
/// 2 pt once cells reach 30 pt) shows `--sunk` through, and every fifth gap is
/// a `--rule` line. Clue text is measured, so the strips are exactly as wide
/// and tall as the longest clue needs.
///
/// Reference fits on a 390 pt phone: 5×5 pitch 56 (cell 54, clue 22),
/// 15×15 pitch 21 (cell 20, clue 14), 20×20 pitch 15 (cell 14, clue 11).
class BoardGeometry {
  BoardGeometry._({
    required this.columns,
    required this.rows,
    required this.cell,
    required this.gap,
    required this.rowClueWidth,
    required this.colClueHeight,
    required this.clueSize,
    required this.clueGap,
    required this.clueLine,
    required this.clueSpacing,
  });

  /// Room above the column clues for the active column's 4 pt lime tick.
  static const tickBand = 10.0;

  /// Space between the column clues and the grid.
  static const colClueGap = 8.0;

  /// Largest pitch, so a 5×5 on a tablet stays a board, not a wall.
  static const maxPitch = 64.0;

  /// Fits a [clues] board into [available].
  factory BoardGeometry.fit(Clues clues, Size available, {double maxCell = maxPitch}) {
    var pitch = math.min(maxCell, available.width / clues.width);
    for (var i = 0; i < 6; i++) {
      final m = _Metrics.of(clues, pitch);
      final byWidth = (available.width - m.rowClueWidth + m.gap) / clues.width;
      final byHeight = (available.height - m.colClueHeight + m.gap) / clues.height;
      final next = math.min(maxCell, math.min(byWidth, byHeight)).floorToDouble().clamp(6.0, maxCell);
      if (next == pitch) break;
      pitch = next;
    }
    final m = _Metrics.of(clues, pitch);
    return BoardGeometry._(
      columns: clues.width,
      rows: clues.height,
      cell: pitch,
      gap: m.gap,
      rowClueWidth: m.rowClueWidth,
      colClueHeight: m.colClueHeight,
      clueSize: m.clueSize,
      clueGap: m.clueGap,
      clueLine: m.clueLine,
      clueSpacing: m.clueSpacing,
    );
  }

  final int columns;
  final int rows;

  /// The pitch: one cell plus one gap. Hit-testing and rings use this.
  final double cell;

  /// The gap between cells.
  final double gap;
  final double rowClueWidth;
  final double colClueHeight;
  final double clueSize;

  /// Space between the row clues and the grid.
  final double clueGap;

  /// Line height of stacked column clues.
  final double clueLine;

  /// Space between row clue numbers.
  final double clueSpacing;

  /// The square drawn for a cell.
  double get inner => cell - gap;

  Offset get gridOrigin => Offset(rowClueWidth, colClueHeight);
  Size get gridSize => Size(columns * cell - gap, rows * cell - gap);
  Size get totalSize => Size(rowClueWidth + gridSize.width, colClueHeight + gridSize.height);
  Rect get gridRect => gridOrigin & gridSize;

  /// The pitch box of a cell (cell plus the gap to its right and below).
  Rect cellRect(int row, int col) => Rect.fromLTWH(rowClueWidth + col * cell, colClueHeight + row * cell, cell, cell);

  /// The square actually painted for a cell.
  Rect cellSquare(int row, int col) => Rect.fromLTWH(rowClueWidth + col * cell, colClueHeight + row * cell, inner, inner);

  /// Where the board sits in a viewport of [size]: against the right edge
  /// with up to [rightMargin] to spare (the grid runs to the edge, clues sit
  /// outside it), and at the top. With [center], centered both ways.
  Offset originIn(Size size, {bool center = false, double rightMargin = 14}) {
    final spareX = size.width - totalSize.width;
    final spareY = size.height - totalSize.height;
    if (center) return Offset(spareX / 2, math.max(0, spareY / 2));
    return Offset(spareX - spareX.clamp(0.0, rightMargin), 0);
  }

  /// Cell under [p] (in board coordinates), clamped into the grid when
  /// [clamp] is true, otherwise null if outside.
  (int, int)? cellAt(Offset p, {bool clamp = false}) {
    final x = (p.dx - rowClueWidth) / cell;
    final y = (p.dy - colClueHeight) / cell;
    if (!clamp && (x < 0 || y < 0 || x >= columns || y >= rows)) return null;
    return (y.floor().clamp(0, rows - 1), x.floor().clamp(0, columns - 1));
  }
}

class _Metrics {
  _Metrics(this.gap, this.clueSize, this.clueGap, this.clueLine, this.clueSpacing, this.rowClueWidth, this.colClueHeight);

  final double gap, clueSize, clueGap, clueLine, clueSpacing, rowClueWidth, colClueHeight;

  static final _widths = <String, double>{};

  static double _width(int n, double size) => _widths.putIfAbsent('$n@$size', () {
        final tp = TextPainter(
          text: TextSpan(text: '$n', style: TallyType.clue(const Color(0xFF000000), size)),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
        return tp.width;
      });

  static _Metrics of(Clues clues, double pitch) {
    final gap = pitch - 1 >= 30 ? 2.0 : 1.0;
    final clueSize = ((pitch * 0.6 + 2) * 2).floorToDouble().clamp(20.0, 44.0) / 2; // 10..22, half steps
    final clueGap = (clueSize * 0.45).roundToDouble();
    final clueLine = (clueSize * 1.07).roundToDouble();
    final spacing = (clueSize * 0.42).roundToDouble();
    var rowWidth = 0.0;
    for (final line in clues.rows) {
      final nums = line.isEmpty ? const [0] : line;
      var w = 0.0;
      for (var j = 0; j < nums.length; j++) {
        w += _width(nums[j], clueSize) + (j > 0 ? spacing : 0);
      }
      rowWidth = math.max(rowWidth, w);
    }
    final colSlots = clues.columns.map((c) => math.max(1, c.length)).fold<int>(1, math.max);
    return _Metrics(
      gap,
      clueSize,
      clueGap,
      clueLine,
      spacing,
      rowWidth + clueGap + 6, // 6: room for the row's lime edge tick
      BoardGeometry.tickBand + colSlots * clueLine + BoardGeometry.colClueGap,
    );
  }
}
