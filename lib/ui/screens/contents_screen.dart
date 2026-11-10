import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/daily.dart';
import '../../state/online.dart';
import '../../state/providers.dart';
import '../../state/store_prompts.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/gridwell_mark.dart';
import '../widgets/home/daily_slab.dart';
import '../widgets/home/plate_grid.dart';
import '../widgets/tally.dart';

/// Play: overall percent solved, today's daily, every collection's progress,
/// and the plates of the collection you're in.
class ContentsScreen extends ConsumerWidget {
  const ContentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final inProgress = ref.watch(inProgressProvider).value ?? const <BoardSave>[];
    final updateReady = ref.watch(updateReadyProvider);
    final today = ref.watch(todayDailyProvider);
    final todayResult = (ref.watch(dailyResultsProvider).value ?? const {})[localDateString(DateTime.now())];
    bool isSolved(PuzzleRecord x) => progress[x.id]?.isSolved ?? false;
    final solvedTotal = set.puzzles.where(isSolved).length;
    // Floor, so 100% means everything; but any progress at all shows as 1%.
    final percent = set.puzzles.isEmpty
        ? 0
        : math.max(solvedTotal > 0 ? 1 : 0, (100 * solvedTotal / set.puzzles.length).floor());

    // The most recent board in progress, if any (book plates only).
    final bookmark = inProgress
        .map((s) => set.puzzles.where((x) => x.id == s.puzzleId).firstOrNull)
        .nonNulls
        .firstOrNull;

    // The collection you're in: the bookmark's, else the first unfinished.
    final featured = bookmark?.collectionId ??
        set.collections
            .firstWhere((c) => set.inCollection(c.id).any((x) => !isSolved(x)), orElse: () => set.collections.first)
            .id;
    final featuredInfo = set.collections.firstWhere((c) => c.id == featured);
    final featuredPlates = set.inCollection(featured);
    final current = bookmark?.collectionId == featured
        ? bookmark
        : featuredPlates.where((x) => !isSolved(x)).firstOrNull;

    return LayoutBuilder(builder: (context, box) {
      final columns = box.maxWidth > 560 ? 6 : 4;
      final tile = PlateGrid.tileFor(box.maxWidth, columns);
      final scaler = MediaQuery.textScalerOf(context);
      return TallyFillPage(
        minHeight: 470 + set.collections.length * 48 + tile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(tallyMargin, 12, tallyMargin, 0),
              child: Row(children: [
                // The 5 × 5 G needs about 26 pt for its cells to read as a grid.
                const GridwellMark(size: 26),
                const SizedBox(width: 10),
                const GridwellWordmark(size: 21),
                const Spacer(),
                if (updateReady)
                  Semantics(
                    button: true,
                    label: 'Update ready. Restart',
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: ref.read(updateReadyProvider.notifier).install,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Overline('Update ready · Restart', color: p.accent),
                      ),
                    ),
                  ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 26),
              child: BigStat(
                value: '$percent%',
                style: TallyType.displayXl(p.ink),
                label: '$solvedTotal of ${set.puzzles.length}\nsolved',
                gap: 16,
              ),
            ),
            DailySlab(
              kicker: 'DAILY',
              puzzle: today,
              solved: todayResult?.solved ?? false,
              solvedTimeMs: todayResult?.timeMs,
              emptyText: 'The Daily begins soon. Until then, every collection is open.',
              onTap: today == null
                  ? null
                  : (todayResult?.solved ?? false)
                      ? () => context.go('/daily')
                      : () => context.push('/play/${today.id}'),
            ),
            const SizedBox(height: 20),
            for (final c in set.collections)
              _CollectionRow(
                name: c.name,
                solved: set.inCollection(c.id).where(isSolved).map((x) => x.plateNumber - 1).toSet(),
                total: set.inCollection(c.id).length,
                current: c.id == featured,
                onTap: () => context.push('/collection/${c.id}'),
              ),
            SectionHeader(
              featuredInfo.name,
              action: 'All ${featuredPlates.length}',
              onAction: () => context.push('/collection/$featured'),
            ),
            // As many rows of plates as the page has room for. The plate
            // you're on (and the one after it) always shows.
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                final rows = math.max(1, ((c.maxHeight + PlateGrid.gap) / (tile + PlateGrid.gap)).floor());
                final shown = _window(featuredPlates, rows * columns, current);
                return ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topCenter,
                    maxHeight: double.infinity,
                    child: PlateGrid(
                      plates: shown,
                      columns: columns,
                      progress: progress,
                      inProgress: inProgress,
                      current: current?.id,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: scaler.scale(12)),
          ],
        ),
      );
    });
  }

  /// The first [n] plates, unless [current] falls beyond them: then the first
  /// n - 2, the current plate and the one after it.
  static List<PuzzleRecord> _window(List<PuzzleRecord> plates, int n, PuzzleRecord? current) {
    if (plates.length <= n) return plates;
    final at = current == null ? -1 : plates.indexWhere((x) => x.id == current.id);
    if (at < n - 1) return plates.take(n).toList();
    final tail = plates.skip(at).take(2).toList();
    return [...plates.take(n - tail.length), ...tail];
  }
}

class _CollectionRow extends StatelessWidget {
  const _CollectionRow({
    required this.name,
    required this.solved,
    required this.total,
    required this.current,
    required this.onTap,
  });

  final String name;

  /// Plate indices (0-based) solved.
  final Set<int> solved;
  final int total;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = TallyType.bodyS(current ? p.accent : p.ink).copyWith(fontSize: 16);
    return Semantics(
      button: true,
      label: '$name, ${solved.length} of $total solved',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(tallyMargin, 6, tallyMargin, 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: style)),
              const SizedBox(width: 12),
              Text('${solved.length}/$total', style: TallyType.bodyS(p.ink).copyWith(fontSize: 16)),
            ]),
            const SizedBox(height: 8),
            ProgressTicks(total: total, done: solved, doneColor: current ? p.lime : p.ink),
          ]),
        ),
      ),
    );
  }
}
