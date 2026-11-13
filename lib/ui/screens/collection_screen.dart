import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/home/plate_grid.dart';
import '../widgets/tally.dart';

/// Inside a collection: solved count, ticks, every plate, and a slab to carry
/// on (or start) at the plate you're on.
class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key, required this.collectionId});

  final String collectionId;

  /// A rough solve time by size, for the start slab.
  static String _duration(PuzzleRecord x) {
    final n = x.width > x.height ? x.width : x.height;
    if (n <= 5) return 'about a minute';
    if (n <= 10) return 'a few minutes';
    if (n <= 15) return 'about ten minutes';
    return 'twenty minutes or so';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final index = set.collections.indexWhere((c) => c.id == collectionId);
    final collection = set.collections[index];
    final plates = set.inCollection(collection.id);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final inProgress = ref.watch(inProgressProvider).value ?? const <BoardSave>[];
    bool isSolved(PuzzleRecord x) => progress[x.id]?.isSolved ?? false;
    final solved = plates.where(isSolved).toList();
    final sizes = plates.map((x) => '${x.width}x${x.height}').toSet().length;
    final started = inProgress.where((s) => plates.any((x) => x.id == s.puzzleId)).toList();
    final notBegun = solved.isEmpty && started.isEmpty;

    // The plate you're on: the latest board in progress here, else the next unsolved.
    final bookmark = started.map((s) => plates.firstWhere((x) => x.id == s.puzzleId)).where((x) => !isSolved(x)).firstOrNull;
    final next = bookmark ?? plates.where((x) => !isSolved(x)).firstOrNull;

    return Scaffold(
      body: TallyBody(
        maxWidth: 760,
        bottom: next == null,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TallyTopBar(
            title: collection.name,
            trailing: Text('VOL. ${roman(index + 1)}', style: TallyType.overline(p.ink2).copyWith(fontSize: 12)),
          ),
          Expanded(
            child: ListView(padding: EdgeInsets.zero, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 12, tallyMargin, 18),
                child: BigStat(
                  value: TextSpan(children: [
                    TextSpan(text: '${solved.length}'),
                    TextSpan(text: '/${plates.length}', style: TextStyle(color: p.ink3)),
                  ]),
                  style: TallyType.displayL(p.ink),
                  label: notBegun ? 'not started\n${plates.length} plates' : 'solved\n$sizes ${sizes == 1 ? 'size' : 'sizes'}',
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                child: ProgressTicks(
                  total: plates.length,
                  done: {for (final x in solved) x.plateNumber - 1},
                  doneColor: p.lime,
                  height: 10,
                  flexible: true,
                ),
              ),
              if (notBegun)
                Padding(
                  padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 0),
                  child: Text(
                    'Every plate starts as an empty grid. Solve the clues and its picture appears.',
                    style: TallyType.prose(p.ink2, size: 16),
                  ),
                ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, c) => PlateGrid(
                  plates: plates,
                  columns: c.maxWidth > 560 ? 7 : 5,
                  progress: progress,
                  inProgress: inProgress,
                  current: bookmark?.id,
                ),
              ),
              const SizedBox(height: 24),
            ]),
          ),
          if (next != null)
            PrimarySlab(
              label: notBegun ? 'START No. ${next.plateNumber.toString().padLeft(2, '0')}' : 'CONTINUE',
              uppercase: false,
              sublabel: notBegun
                  ? '${next.width}×${next.height} · ${_duration(next)}'
                  : 'No. ${next.plateNumber} · ${next.name} · ${next.width}×${next.height}',
              height: 96,
              onPressed: () => context.push('/play/${next.id}'),
            ),
        ]),
      ),
    );
  }
}
