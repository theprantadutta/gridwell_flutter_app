import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../engine/model/board.dart';
import '../../engine/model/cell_state.dart';
import '../../engine/model/clues.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import 'board_geometry.dart';

/// Paints cells, marks, highlight, grid lines and cursor.
///
/// States are structural: filled is a solid square edge to edge, crossed is a
/// thin accent × on an untouched cell, untouched is empty. A proven mistake is
/// a filled cell hatched in accent with an accent ring.
class GridPainter extends CustomPainter {
  GridPainter({
    required this.geometry,
    required this.board,
    required this.palette,
    required this.mistakes,
    this.cursorRow,
    this.cursorCol,
    this.flashRect,
  });

  final BoardGeometry geometry;
  final Board board;
  final GridwellPalette palette;
  final Set<int> mistakes;
  final int? cursorRow;
  final int? cursorCol;

  /// Extra ring (hint cell or flagged mistake), in board coordinates.
  final Rect? flashRect;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final p = palette;
    final grid = g.gridRect;
    final cell = g.cell;

    // Untouched cells.
    canvas.drawRect(grid, Paint()..color = p.cellEmpty);

    // Highlight band under the marks (multiply keeps ink black in light mode).
    if (cursorRow != null && cursorCol != null) {
      final hl = Paint()
        ..color = p.highlight
        ..blendMode = p.highlightBlend;
      canvas.drawRect(Rect.fromLTWH(grid.left - g.rowClueWidth, grid.top + cursorRow! * cell,
          grid.width + g.rowClueWidth, cell), hl);
      canvas.drawRect(Rect.fromLTWH(grid.left + cursorCol! * cell, grid.top - g.colClueHeight,
          cell, grid.height + g.colClueHeight), hl);
    }

    final fill = Paint()..color = p.cellFilled;
    final cross = Paint()
      ..color = p.cellCrossed
      ..strokeWidth = math.max(1.2, cell * 0.075)
      ..strokeCap = StrokeCap.round;
    final inset = cell * 0.28;
    final cells = board.cells;
    final w = board.width;
    for (var i = 0; i < cells.length; i++) {
      final state = cells[i];
      if (state == CellState.empty) continue;
      final r = g.cellRect(i ~/ w, i % w);
      if (state == CellState.filled) {
        canvas.drawRect(r, fill);
        if (mistakes.contains(i)) _hatch(canvas, r);
      } else {
        canvas.drawLine(r.topLeft + Offset(inset, inset), r.bottomRight - Offset(inset, inset), cross);
        canvas.drawLine(r.topRight + Offset(-inset, inset), r.bottomLeft + Offset(inset, -inset), cross);
        if (mistakes.contains(i)) {
          canvas.drawRect(r.deflate(1), Paint()
            ..color = p.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
        }
      }
    }

    // Grid lines: minor hairlines, then every fifth line and the border in ink.
    final minor = Paint()
      ..color = p.gridLine
      ..strokeWidth = p.gridLineWidth;
    final major = Paint()
      ..color = p.gridLineMajor
      ..strokeWidth = p.gridLineMajorWidth;
    for (var c = 1; c < g.columns; c++) {
      final x = grid.left + c * cell;
      canvas.drawLine(Offset(x, grid.top), Offset(x, grid.bottom), c % 5 == 0 ? major : minor);
    }
    for (var r = 1; r < g.rows; r++) {
      final y = grid.top + r * cell;
      canvas.drawLine(Offset(grid.left, y), Offset(grid.right, y), r % 5 == 0 ? major : minor);
    }
    canvas.drawRect(grid, Paint()
      ..color = p.gridLineMajor
      ..style = PaintingStyle.stroke
      ..strokeWidth = p.gridLineMajorWidth);

    // Mistake rings and the cursor.
    final ring = Paint()
      ..color = p.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, cell * 0.08);
    for (final i in mistakes) {
      if (cells[i] == CellState.filled) {
        canvas.drawRect(g.cellRect(i ~/ w, i % w).inflate(cell * 0.06), ring);
      }
    }
    if (cursorRow != null && cursorCol != null) {
      canvas.drawRect(g.cellRect(cursorRow!, cursorCol!).inflate(cell * 0.04), ring);
    }
    if (flashRect != null) canvas.drawRect(flashRect!.inflate(cell * 0.06), ring);
  }

  void _hatch(Canvas canvas, Rect r) {
    canvas.save();
    canvas.clipRect(r);
    final paint = Paint()
      ..color = palette.accent
      ..strokeWidth = r.width * 0.14;
    final step = r.width / 3;
    for (var d = -r.height; d < r.width; d += step) {
      canvas.drawLine(Offset(r.left + d, r.bottom), Offset(r.left + d + r.height, r.top), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(GridPainter old) =>
      !identical(old.board, board) ||
      old.palette != palette ||
      old.cursorRow != cursorRow ||
      old.cursorCol != cursorCol ||
      old.mistakes != mistakes ||
      old.flashRect != flashRect ||
      old.geometry.cell != geometry.cell;
}

/// Paints row and column clues. Repaints only when retirement or the active
/// line changes, so drags do not re-lay text.
class CluePainter extends CustomPainter {
  CluePainter({
    required this.geometry,
    required this.clues,
    required this.palette,
    required this.rowRetired,
    required this.colRetired,
    this.activeRow,
    this.activeCol,
  });

  final BoardGeometry geometry;
  final Clues clues;
  final GridwellPalette palette;
  final List<Set<int>> rowRetired;
  final List<Set<int>> colRetired;
  final int? activeRow;
  final int? activeCol;

  static final _cache = <String, TextPainter>{};

  TextPainter _text(int n, bool retired, bool active) {
    final key = '$n|$retired|$active|${geometry.clueSize}|${palette.brightness}|${palette.clueRetired.toARGB32()}';
    return _cache.putIfAbsent(key, () {
      final color = retired ? palette.clueRetired : palette.clueText;
      final style = FolioType.clue(color, geometry.clueSize).copyWith(
        fontWeight: active && !retired ? FontWeight.w700 : null,
      );
      return TextPainter(
        text: TextSpan(text: '$n', style: style),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final cell = g.cell;
    final strike = Paint()
      ..color = palette.clueRetired
      ..strokeWidth = math.max(1, g.clueSize * 0.08);

    // Zebra bands behind column clues on big boards, to keep columns apart.
    if (g.columns >= 15) {
      final band = Paint()..color = palette.rule.withValues(alpha: palette.isDark ? 0.35 : 0.45);
      for (var c = 0; c < g.columns; c += 2) {
        canvas.drawRect(Rect.fromLTWH(g.rowClueWidth + c * cell, 0, cell, g.colClueHeight - g.clueGap * 0.5), band);
      }
    }

    // Row clues: right-aligned, left of the grid.
    final rowStep = g.clueSize * 1.05;
    for (var r = 0; r < g.rows; r++) {
      final clue = clues.rows[r];
      var x = g.rowClueWidth - g.clueGap;
      for (var j = clue.length - 1; j >= 0; j--) {
        final tp = _text(clue[j], rowRetired.length > r && rowRetired[r].contains(j), r == activeRow);
        final dx = x - tp.width;
        final dy = g.colClueHeight + r * cell + (cell - tp.height) / 2;
        tp.paint(canvas, Offset(dx, dy));
        if (rowRetired.length > r && rowRetired[r].contains(j)) {
          final y = dy + tp.height * 0.55;
          canvas.drawLine(Offset(dx - 1, y), Offset(dx + tp.width + 1, y), strike);
        }
        x = dx - (rowStep - tp.width).clamp(g.clueSize * 0.35, rowStep);
      }
    }

    // Column clues: bottom-aligned, above the grid.
    final colStep = g.clueSize * 1.12;
    for (var c = 0; c < g.columns; c++) {
      final clue = clues.columns[c];
      var y = g.colClueHeight - g.clueGap;
      for (var j = clue.length - 1; j >= 0; j--) {
        final tp = _text(clue[j], colRetired.length > c && colRetired[c].contains(j), c == activeCol);
        final dx = g.rowClueWidth + c * cell + (cell - tp.width) / 2;
        final dy = y - tp.height;
        tp.paint(canvas, Offset(dx, dy));
        if (colRetired.length > c && colRetired[c].contains(j)) {
          final ly = dy + tp.height * 0.55;
          canvas.drawLine(Offset(dx - 1, ly), Offset(dx + tp.width + 1, ly), strike);
        }
        y -= colStep;
      }
    }
  }

  @override
  bool shouldRepaint(CluePainter old) =>
      old.rowRetired != rowRetired ||
      old.colRetired != colRetired ||
      old.palette != palette ||
      old.activeRow != activeRow ||
      old.activeCol != activeCol ||
      old.geometry.cell != geometry.cell;
}
