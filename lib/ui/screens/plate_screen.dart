import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// A solved picture shown large on `--tile`, with its facts and a way back in.
class PlateScreen extends ConsumerWidget {
  const PlateScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final x = set.puzzles.firstWhere((e) => e.id == puzzleId);
    final progress = ref.watch(progressProvider).value?[puzzleId];
    final collection = set.collections.firstWhere((c) => c.id == x.collectionId);
    final solves = progress?.solveCount ?? 0;
    return Scaffold(
      body: TallyBody(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TallyTopBar(
            title: collection.name,
            trailing: Text('No. ${x.plateNumber}', style: TallyType.overline(p.ink2).copyWith(fontSize: 12)),
          ),
          Expanded(
            child: TallyFillPage(
              minHeight: 520,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    color: p.tile,
                    padding: const EdgeInsets.all(tallyMargin),
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: x.width / x.height,
                        child: CustomPaint(painter: _PicturePainter(puzzle: x, palette: p)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Overline('${collection.name} ${x.plateNumber}', color: p.accent),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(x.name, maxLines: 1, style: TallyType.titleL(p.ink)),
                    ),
                  ]),
                ),
                ColoredBox(
                  color: p.sunk,
                  child: Row(children: [
                    _Fact(label: 'Size', value: '${x.width}×${x.height}'),
                    const SizedBox(width: tallyDivider),
                    _Fact(
                      label: 'Best time',
                      value: progress?.bestTimeMs == null ? '–' : formatClock(progress!.bestTimeMs!),
                    ),
                    const SizedBox(width: tallyDivider),
                    _Fact(label: 'Solved', value: solves == 1 ? 'Once' : '$solves times'),
                  ]),
                ),
                const SizedBox(height: tallyDivider),
                PrimarySlab(
                  label: 'Solve again',
                  sublabel: '${x.width}×${x.height} · from a blank grid',
                  height: 96,
                  onPressed: () => context.push('/play/${x.id}'),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        color: p.surface,
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Overline(label),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, maxLines: 1, style: TallyType.tabular(TallyType.bodyL(p.ink))),
          ),
        ]),
      ),
    );
  }
}

/// The picture in full color, edge to edge in its box.
class _PicturePainter extends CustomPainter {
  _PicturePainter({required this.puzzle, required this.palette});

  final PuzzleRecord puzzle;
  final GridwellPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = puzzle.width, h = puzzle.height;
    final cell = size.width / w < size.height / h ? size.width / w : size.height / h;
    final ox = (size.width - cell * w) / 2;
    final oy = (size.height - cell * h) / 2;
    final paint = Paint()..isAntiAlias = false;
    final colors = puzzle.colorLayer;
    for (var i = 0; i < w * h; i++) {
      if (!puzzle.solution.cells[i]) continue;
      paint.color = palette.art[(colors?[i] ?? 1).clamp(1, palette.art.length - 1)];
      canvas.drawRect(Rect.fromLTWH(ox + (i % w) * cell, oy + (i ~/ w) * cell, cell + 0.5, cell + 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_PicturePainter old) => old.puzzle != puzzle || old.palette != palette;
}
