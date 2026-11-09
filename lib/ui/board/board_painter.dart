import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../engine/model/board.dart';
import '../../engine/model/cell_state.dart';
import '../../engine/model/clues.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import 'board_geometry.dart';

/// A hint on screen, before Apply: the square and what it will become.
class HintMark {
  const HintMark(this.row, this.col, this.result);

  final int row;
  final int col;
  final CellState result;

  @override
  bool operator ==(Object other) => other is HintMark && other.row == row && other.col == col && other.result == result;

  @override
  int get hashCode => Object.hash(row, col, result);
}

/// Paints cells, marks, the active line band, rules and rings (DESIGN-SPEC
/// section 5).
///
/// States are told apart by shape: filled is a solid `--ink` square, crossed
/// is a short `--mark` dash, empty is the bare `--cell`. A proven mistake is
/// hatched in `--error` with an `--error` ring; a hint waiting to be applied
/// shows what it will place, ringed in lime inside and out.
class GridPainter extends CustomPainter {
  GridPainter({
    required this.geometry,
    required this.board,
    required this.palette,
    required this.mistakes,
    this.cursorRow,
    this.cursorCol,
    this.hint,
    this.bleedLeft = 0,
  });

  final BoardGeometry geometry;
  final Board board;
  final GridwellPalette palette;
  final Set<int> mistakes;
  final int? cursorRow;
  final int? cursorCol;
  final HintMark? hint;

  /// How far left of this canvas the viewport begins. The active row's band
  /// and lime tick run out to the viewport's edge.
  final double bleedLeft;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final p = palette;
    final grid = g.gridRect;
    final pitch = g.cell;
    final inner = g.inner;

    // The gaps show --sunk.
    canvas.drawRect(grid, Paint()..color = p.sunk);

    final empty = Paint()..color = p.cell;
    final fill = Paint()..color = p.ink;
    final dash = Paint()..color = p.mark;
    final cells = board.cells;
    final w = board.width;
    for (var i = 0; i < cells.length; i++) {
      canvas.drawRect(g.cellSquare(i ~/ w, i % w), cells[i] == CellState.filled ? fill : empty);
    }

    // Major rules: every fifth gap becomes a --rule line.
    final rule = Paint()..color = p.rule;
    final rw = math.max(g.gap, p.majorRuleWidth);
    for (var c = 5; c < g.columns; c += 5) {
      final x = grid.left + c * pitch - g.gap / 2;
      canvas.drawRect(Rect.fromLTWH(x - rw / 2, grid.top, rw, grid.height), rule);
    }
    for (var r = 5; r < g.rows; r += 5) {
      final y = grid.top + r * pitch - g.gap / 2;
      canvas.drawRect(Rect.fromLTWH(grid.left, y - rw / 2, grid.width, rw), rule);
    }

    // The active row and column: a band over everything, lime ticks at the
    // outer edges, an --accent ring round the square.
    final cr = cursorRow, cc = cursorCol;
    if (cr != null && cc != null) {
      final band = Paint()..color = p.hl;
      final rowTop = grid.top + cr * pitch;
      final colLeft = grid.left + cc * pitch;
      canvas.drawRect(Rect.fromLTRB(-bleedLeft, rowTop, grid.right, rowTop + inner), band);
      canvas.drawRect(Rect.fromLTRB(colLeft, BoardGeometry.tickBand, colLeft + inner, rowTop), band);
      canvas.drawRect(Rect.fromLTRB(colLeft, rowTop + inner, colLeft + inner, grid.bottom), band);
      final lime = Paint()..color = p.lime;
      canvas.drawRect(Rect.fromLTWH(-bleedLeft, rowTop, 4, inner), lime);
      canvas.drawRect(Rect.fromLTWH(colLeft, BoardGeometry.tickBand - 4, inner, 4), lime);
    }

    // Dashes above the band. Inside it they use --ink-2: --mark over the dark
    // theme's band falls just short of 3:1.
    final bandDash = Paint()..color = p.ink2;
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != CellState.crossed) continue;
      final r = i ~/ w, c = i % w;
      _dash(canvas, g.cellSquare(r, c), r == cr || c == cc ? bandDash : dash);
    }

    // Proven mistakes.
    final errorRing = Paint()
      ..color = p.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final i in mistakes) {
      final r = g.cellSquare(i ~/ w, i % w);
      if (cells[i] == CellState.filled) {
        canvas.drawRect(r, empty);
        _hatch(canvas, r.deflate(2));
      }
      canvas.drawRect(r.deflate(1), errorRing);
    }

    // A hint waiting for Apply: what it will place, ringed in lime.
    final h = hint;
    if (h != null) {
      final r = g.cellSquare(h.row, h.col);
      if (h.result == CellState.filled) {
        canvas.drawRect(r, fill);
      } else {
        canvas.drawRect(r, empty);
        if (h.result == CellState.crossed) _dash(canvas, r, dash);
      }
      final ring = Paint()
        ..color = p.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(r.deflate(1), ring);
      canvas.drawRect(r.inflate(2), ring);
    } else if (cr != null && cc != null) {
      canvas.drawRect(
        g.cellSquare(cr, cc).inflate(2),
        Paint()
          ..color = p.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// A crossed square: a short horizontal dash, 40% of the cell wide.
  void _dash(Canvas canvas, Rect r, Paint paint) {
    final t = r.width >= 30 ? 3.0 : 2.0;
    final len = r.width * 0.4;
    canvas.drawRect(Rect.fromCenter(center: r.center, width: len, height: t), paint);
  }

  /// 45° hatch, 2 pt lines with a 5 pt period.
  void _hatch(Canvas canvas, Rect r) {
    canvas.save();
    canvas.clipRect(r);
    final paint = Paint()
      ..color = palette.error
      ..strokeWidth = 2;
    const period = 5.0 * 1.41421356; // 5 pt measured across the lines
    for (var d = -r.height; d < r.width; d += period) {
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
      old.hint != hint ||
      old.bleedLeft != bleedLeft ||
      old.geometry.cell != geometry.cell;
}

/// Which clue line to ring in `--error`: the line that proves a mistake.
class ErrorLine {
  const ErrorLine({required this.isRow, required this.index});

  final bool isRow;
  final int index;

  @override
  bool operator ==(Object other) => other is ErrorLine && other.isRow == isRow && other.index == index;

  @override
  int get hashCode => Object.hash(isRow, index);
}

/// Paints row and column clues: 700 `--ink` while open, 500 `--ink-3` once
/// satisfied. Repaints only when retirement or the ringed line changes, so
/// drags do not re-lay text.
class CluePainter extends CustomPainter {
  CluePainter({
    required this.geometry,
    required this.clues,
    required this.palette,
    required this.rowRetired,
    required this.colRetired,
    this.errorLine,
  });

  final BoardGeometry geometry;
  final Clues clues;
  final GridwellPalette palette;
  final List<Set<int>> rowRetired;
  final List<Set<int>> colRetired;
  final ErrorLine? errorLine;

  static final _cache = <String, TextPainter>{};

  TextPainter _text(int n, bool retired) {
    final color = retired ? palette.ink3 : palette.ink;
    final key = '$n|$retired|${geometry.clueSize}|${color.toARGB32()}';
    return _cache.putIfAbsent(
      key,
      () => TextPainter(
        text: TextSpan(text: '$n', style: TallyType.clue(color, geometry.clueSize, retired: retired)),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final g = geometry;
    final pitch = g.cell;
    final grid = g.gridRect;
    Rect? ring;

    // Row clues: right-aligned, ending clueGap left of the grid.
    for (var r = 0; r < g.rows; r++) {
      final clue = clues.rows[r];
      final zero = Clues.blocksOf(clue).isEmpty;
      var x = grid.left - g.clueGap;
      final top = grid.top + r * pitch;
      var left = x;
      for (var j = clue.length - 1; j >= 0; j--) {
        final retired = zero || (rowRetired.length > r && rowRetired[r].contains(j));
        final tp = _text(clue[j], retired);
        final dx = x - tp.width;
        tp.paint(canvas, Offset(dx, top + (g.inner - tp.height) / 2));
        left = dx;
        x = dx - g.clueSpacing;
      }
      if (errorLine == ErrorLine(isRow: true, index: r)) {
        ring = Rect.fromLTRB(left - 4, top - 2, grid.left - g.clueGap + 4, top + g.inner + 2);
      }
    }

    // Column clues: bottom-aligned, ending colClueGap above the grid.
    for (var c = 0; c < g.columns; c++) {
      final clue = clues.columns[c];
      final zero = Clues.blocksOf(clue).isEmpty;
      final left = grid.left + c * pitch;
      var bottom = grid.top - BoardGeometry.colClueGap;
      for (var j = clue.length - 1; j >= 0; j--) {
        final retired = zero || (colRetired.length > c && colRetired[c].contains(j));
        final tp = _text(clue[j], retired);
        tp.paint(canvas, Offset(left + (g.inner - tp.width) / 2, bottom - g.clueLine + (g.clueLine - tp.height) / 2));
        bottom -= g.clueLine;
      }
      if (errorLine == ErrorLine(isRow: false, index: c)) {
        ring = Rect.fromLTRB(left - 2, bottom - 4, left + g.inner + 2, grid.top - BoardGeometry.colClueGap + 4);
      }
    }

    if (ring != null) {
      canvas.drawRect(
        ring,
        Paint()
          ..color = palette.error
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(CluePainter old) =>
      old.rowRetired != rowRetired ||
      old.colRetired != colRetired ||
      old.palette != palette ||
      old.errorLine != errorLine ||
      old.geometry.cell != geometry.cell;
}
