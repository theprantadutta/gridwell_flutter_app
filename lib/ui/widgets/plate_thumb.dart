import 'package:flutter/material.dart';

import '../../engine/model/puzzle.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';

/// How a plate thumbnail should look.
enum PlateState { untouched, inProgress, solved }

/// A plate: a square sheet with a hairline border, showing the picture once
/// solved, the board so far (in faint ink) while in progress, nothing before.
class PlateThumb extends StatelessWidget {
  const PlateThumb({
    super.key,
    required this.puzzle,
    required this.state,
    this.progressCells,
    this.highlighted = false,
    this.faded = false,
  });

  final PuzzleRecord puzzle;
  final PlateState state;

  /// For in-progress plates: board cells as `.#x` chars.
  final String? progressCells;
  final bool highlighted;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: p.surfaceRaised,
          border: Border.all(
            color: highlighted ? p.accent : (faded ? p.rule : p.ruleStrong),
            width: highlighted ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: state == PlateState.untouched
            ? const SizedBox()
            : CustomPaint(
                painter: PicturePainter(
                  puzzle: puzzle,
                  palette: p,
                  progressCells: state == PlateState.inProgress ? progressCells : null,
                ),
              ),
      ),
    );
  }
}

/// Paints a puzzle's revealed picture, centered and letterboxed into a square.
class PicturePainter extends CustomPainter {
  PicturePainter({required this.puzzle, required this.palette, this.progressCells, this.reveal = 1});

  final PuzzleRecord puzzle;
  final GridwellPalette palette;
  final String? progressCells;

  /// 0..1: how much of the picture has resolved (for the completion reveal).
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = puzzle.width, h = puzzle.height;
    final cell = (size.width / w < size.height / h) ? size.width / w : size.height / h;
    final ox = (size.width - cell * w) / 2;
    final oy = (size.height - cell * h) / 2;
    final paint = Paint()..isAntiAlias = false;
    final colors = puzzle.colorLayer;
    for (var i = 0; i < w * h; i++) {
      Color? color;
      final progress = progressCells;
      if (progress != null) {
        if (i < progress.length && progress[i] == '#') color = palette.textFaint;
      } else if (puzzle.solution.cells[i]) {
        final index = colors?[i] ?? 1;
        color = palette.art[index.clamp(1, palette.art.length - 1)];
        if (reveal < 1) color = Color.lerp(palette.cellFilled, color, reveal);
      }
      if (color == null) continue;
      paint.color = color;
      // Slight overlap avoids hairline seams between cells.
      canvas.drawRect(
        Rect.fromLTWH(ox + (i % w) * cell, oy + (i ~/ w) * cell, cell + 0.5, cell + 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(PicturePainter old) =>
      old.puzzle != puzzle || old.palette != palette || old.progressCells != progressCells || old.reveal != reveal;
}
