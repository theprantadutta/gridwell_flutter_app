import 'package:flutter/widgets.dart';

import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';

/// The Gridwell mark: a G drawn as a solved 5×5 nonogram, with one vermilion
/// cross marking a square proven empty. Painted from the logo kit's geometry
/// (brand/README.md), so it is crisp at any size and follows the theme.
///
/// Geometry, in kit units (131 square): 24-unit cells, 1.5-unit gaps, a
/// 2.5-unit frame. Filled rows `.####`, `#....`, `#..##`, `#...#`, `.###.`;
/// the cross sits in row 3, column 2.
class GridwellMark extends StatelessWidget {
  const GridwellMark({super.key, required this.size, this.mono = false});

  final double size;

  /// Single-color version for small sizes and busy backgrounds.
  final bool mono;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Gridwell',
        image: true,
        child: CustomPaint(size: Size.square(size), painter: GridwellMarkPainter(context.palette, mono: mono)),
      );
}

class GridwellMarkPainter extends CustomPainter {
  GridwellMarkPainter(this.palette, {this.mono = false});

  final GridwellPalette palette;
  final bool mono;

  static const _rows = ['.####', '#....', '#..##', '#...#', '.###.'];
  static const _units = 131.0, _cell = 24.0, _gap = 1.5, _frame = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / _units;
    final ink = Paint()..color = palette.textPrimary;
    // Frame, then the gap color beneath the cells.
    canvas.drawRect(Offset.zero & Size.square(_units * u), ink);
    canvas.drawRect(
      Rect.fromLTWH(_frame * u, _frame * u, (_units - 2 * _frame) * u, (_units - 2 * _frame) * u),
      Paint()..color = mono ? palette.surface : palette.rule,
    );
    final empty = Paint()..color = mono ? palette.surface : palette.surfaceRaised;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        final rect = Rect.fromLTWH(
          (_frame + c * (_cell + _gap)) * u,
          (_frame + r * (_cell + _gap)) * u,
          _cell * u,
          _cell * u,
        );
        canvas.drawRect(rect, _rows[r][c] == '#' ? ink : empty);
      }
    }
    // The cross: two 2.5-unit strokes at 45°, each 16 units long, in row 3, column 2.
    final cx = (_frame + 1 * (_cell + _gap) + _cell / 2) * u;
    final cy = (_frame + 2 * (_cell + _gap) + _cell / 2) * u;
    final half = 16 / 2 / 1.41421356 * u;
    final cross = Paint()
      ..color = mono ? palette.textPrimary : palette.accent
      ..strokeWidth = 2.5 * u
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(cx - half, cy - half), Offset(cx + half, cy + half), cross);
    canvas.drawLine(Offset(cx + half, cy - half), Offset(cx - half, cy + half), cross);
  }

  @override
  bool shouldRepaint(GridwellMarkPainter old) => old.palette != palette || old.mono != mono;
}
