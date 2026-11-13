import 'package:material_ui/material_ui.dart';

import '../../engine/model/puzzle.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';

/// How a plate thumbnail should look.
enum PlateState { untouched, inProgress, solved }

/// A Tally plate: a square `--surface` tile. Solved shows the picture in
/// color; in progress shows the board so far in ink, with a 2 pt lime inner
/// ring and a lime percent tag when [highlighted]; untouched shows its size in
/// `--ink-3`. The plate number sits bottom-right in `micro`.
class PlateThumb extends StatelessWidget {
  const PlateThumb({
    super.key,
    required this.puzzle,
    required this.state,
    this.progressCells,
    this.highlighted = false,
    this.faded = false,
    this.showNumber = false,
    this.background,
    this.inset = 0.14,
  });

  final PuzzleRecord puzzle;
  final PlateState state;

  /// For in-progress plates: board cells as `.#x` chars.
  final String? progressCells;

  /// The plate you're on: lime ring and percent tag.
  final bool highlighted;

  /// Kept for callers that dim plates; Tally plates do not fade.
  final bool faded;

  /// Draw the plate number bottom-right.
  final bool showNumber;

  /// Defaults to `--surface`.
  final Color? background;

  /// Picture inset as a fraction of the side.
  final double inset;

  /// Percent of the picture's filled squares already filled on the board.
  static int percent(PuzzleRecord puzzle, String? cells) {
    if (cells == null) return 0;
    final filled = cells.split('').where((c) => c == '#').length;
    final target = puzzle.solution.filledCount;
    return target == 0 ? 0 : (100 * filled / target).clamp(0, 99).round();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(builder: (context, c) {
        final side = c.maxWidth;
        // About 14 pt on a 96 pt plate.
        final pad = side * inset;
        return Container(
          color: background ?? p.surface,
          foregroundDecoration: highlighted ? BoxDecoration(border: Border.all(color: p.lime, width: 2)) : null,
          child: Stack(children: [
            if (state == PlateState.untouched)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${puzzle.width}×${puzzle.height}',
                      maxLines: 1,
                      textScaler: TextScaler.noScaling,
                      style: TallyType.style(size: (side * 0.15).clamp(9.0, 22.0), color: p.ink3, weight: FontWeight.w800),
                    ),
                  ),
                ),
              )
            else
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(pad),
                  child: CustomPaint(
                    painter: PicturePainter(
                      puzzle: puzzle,
                      palette: p,
                      progressCells: state == PlateState.inProgress ? (progressCells ?? '') : null,
                    ),
                  ),
                ),
              ),
            if (highlighted && state == PlateState.inProgress)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  color: p.lime,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '${percent(puzzle, progressCells)}%',
                    textScaler: TextScaler.noScaling,
                    style: TallyType.style(size: (side * 0.1).clamp(8.0, 13.0), color: p.onLime, weight: FontWeight.w800, height: 1),
                  ),
                ),
              ),
            if (showNumber)
              Positioned(
                right: (side * 0.05).clamp(3.0, 8.0),
                bottom: (side * 0.05).clamp(3.0, 8.0),
                child: Text(
                  puzzle.plateNumber.toString().padLeft(2, '0'),
                  textScaler: TextScaler.noScaling,
                  style: TallyType.micro(p.ink2).copyWith(fontSize: (side * 0.095).clamp(8.0, 12.0)),
                ),
              ),
          ]),
        );
      }),
    );
  }
}

/// Paints a puzzle's revealed picture, centered and letterboxed into a square.
class PicturePainter extends CustomPainter {
  PicturePainter({required this.puzzle, required this.palette, this.progressCells, this.reveal = 1});

  final PuzzleRecord puzzle;
  final GridwellPalette palette;

  /// When set, paints the board so far (filled squares in ink) instead of
  /// the picture.
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
        if (i < progress.length && progress[i] == '#') color = palette.ink;
      } else if (puzzle.solution.cells[i]) {
        final index = colors?[i] ?? 1;
        color = palette.art[index.clamp(1, palette.art.length - 1)];
        if (reveal < 1) color = Color.lerp(palette.ink, color, reveal);
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
