import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../../engine/model/puzzle.dart';
import '../../../state/providers.dart';
import '../../theme/gridwell_theme.dart';
import '../plate_thumb.dart';

/// Edge-to-edge plates in rows, 2 pt gaps showing the page through.
class PlateGrid extends StatelessWidget {
  const PlateGrid({
    super.key,
    required this.plates,
    required this.columns,
    required this.progress,
    required this.inProgress,
    this.current,
  });

  final List<PuzzleRecord> plates;
  final int columns;
  final Map<String, PuzzleProgressData> progress;
  final List<BoardSave> inProgress;

  /// The plate you're on: lime ring, percent tag.
  final String? current;

  static const gap = 2.0;

  /// Side of one plate in [width].
  static double tileFor(double width, int columns) => (width - gap * (columns - 1)) / columns;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final rows = (plates.length / columns).ceil();
    return LayoutBuilder(builder: (context, c) {
      final tile = tileFor(c.maxWidth, columns);
      return Column(children: [
        for (var r = 0; r < rows; r++) ...[
          if (r > 0) const SizedBox(height: gap),
          Row(children: [
            for (var i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(
                width: tile,
                child: r * columns + i < plates.length
                    ? PlateTile(
                        puzzle: plates[r * columns + i],
                        progress: progress,
                        inProgress: inProgress,
                        current: plates[r * columns + i].id == current,
                      )
                    // Empty slots keep the row's rhythm without drawing a plate.
                    : AspectRatio(aspectRatio: 1, child: ColoredBox(color: p.bg)),
              ),
            ],
          ]),
        ],
      ]);
    });
  }
}

/// One tappable plate with its state worked out from progress.
class PlateTile extends StatelessWidget {
  const PlateTile({super.key, required this.puzzle, required this.progress, required this.inProgress, this.current = false});

  final PuzzleRecord puzzle;
  final Map<String, PuzzleProgressData> progress;
  final List<BoardSave> inProgress;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final save = inProgress.where((s) => s.puzzleId == puzzle.id).firstOrNull;
    final solved = progress[puzzle.id]?.isSolved ?? false;
    final state = solved ? PlateState.solved : (save != null ? PlateState.inProgress : PlateState.untouched);
    final label = switch (state) {
      PlateState.solved => 'No. ${puzzle.plateNumber}, ${puzzle.name}, solved',
      PlateState.inProgress => 'No. ${puzzle.plateNumber}, ${PlateThumb.percent(puzzle, save?.cells)}% done',
      PlateState.untouched => 'No. ${puzzle.plateNumber}, ${puzzle.width} by ${puzzle.height}',
    };
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push('/play/${puzzle.id}'),
        child: PlateThumb(
          puzzle: puzzle,
          state: state,
          progressCells: save?.cells,
          highlighted: current && !solved,
          showNumber: true,
        ),
      ),
    );
  }
}
