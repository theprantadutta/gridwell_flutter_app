import 'package:flutter/widgets.dart';

import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';

/// The Gridwell mark (logo kit v2.0, L6 "Wordmark Cells"): a 2 × 2 grid with
/// one square inked and one solved. Top-left `--ink`, top-right and
/// bottom-left `--track`, bottom-right lime, always.
///
/// Geometry, in kit units (21.5 square): 10-unit cells, 1.5-unit gap.
class GridwellMark extends StatelessWidget {
  const GridwellMark({super.key, required this.size, this.mono = false});

  final double size;

  /// One color: filled cells solid, empty cells outlined. For photos and busy
  /// backgrounds.
  final bool mono;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'Gridwell',
        image: true,
        child: CustomPaint(
          size: Size.square(size),
          painter: GridwellMarkPainter(context.palette, mono: mono),
        ),
      );
}

class GridwellMarkPainter extends CustomPainter {
  GridwellMarkPainter(this.palette, {this.mono = false});

  final GridwellPalette palette;
  final bool mono;

  static const units = 21.5, cell = 10.0, gap = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.shortestSide / units;
    Rect at(int r, int c) => Rect.fromLTWH(c * (cell + gap) * u, r * (cell + gap) * u, cell * u, cell * u);
    if (mono) {
      final solid = Paint()..color = palette.ink;
      final line = Paint()
        ..color = palette.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = u;
      canvas.drawRect(at(0, 0), solid);
      canvas.drawRect(at(1, 1), solid);
      canvas.drawRect(at(0, 1).deflate(u / 2), line);
      canvas.drawRect(at(1, 0).deflate(u / 2), line);
      return;
    }
    canvas.drawRect(at(0, 0), Paint()..color = palette.ink);
    canvas.drawRect(at(0, 1), Paint()..color = palette.track);
    canvas.drawRect(at(1, 0), Paint()..color = palette.track);
    canvas.drawRect(at(1, 1), Paint()..color = palette.lime);
  }

  @override
  bool shouldRepaint(GridwellMarkPainter old) => old.palette != palette || old.mono != mono;
}

/// "Gridwell" in Schibsted Grotesk Black, tracking -3.5%, with a dotless ı
/// whose dot is a lime square (0.2 em, its bottom 0.075 em above the x-height).
class GridwellWordmark extends StatelessWidget {
  const GridwellWordmark({super.key, required this.size, this.color});

  /// Font size in logical pixels.
  final double size;

  /// Defaults to `--ink`.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = TallyType.style(size: size, color: color ?? p.ink, weight: FontWeight.w900, tracking: -0.035, height: 1);
    TextPainter measure(String s) => TextPainter(
          text: TextSpan(text: s, style: style),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.noScaling,
        )..layout();
    final before = measure('Gr');
    final stem = measure('ı');
    final xHeight = size * _xHeightEm;
    final dot = size * 0.2;
    final baseline = before.computeDistanceToActualBaseline(TextBaseline.alphabetic);
    final dotTop = baseline - xHeight - size * 0.075 - dot;
    return Semantics(
      label: 'Gridwell',
      excludeSemantics: true,
      child: Stack(clipBehavior: Clip.none, children: [
        Text('Grıdwell', style: style, textScaler: TextScaler.noScaling),
        Positioned(
          left: before.width + (stem.width - dot) / 2 - size * 0.035 / 2,
          top: dotTop,
          child: Container(width: dot, height: dot, color: p.lime),
        ),
      ]),
    );
  }

  /// Schibsted Grotesk's x-height: OS/2 sxHeight 1080 of 2048 units.
  static const _xHeightEm = 1080 / 2048;
}
