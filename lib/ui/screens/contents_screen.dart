import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
import '../../state/store_prompts.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

/// The home page: a book's contents. Today's daily, the bookmark (last board
/// in progress), every collection with its progress, and the first plates of
/// the collection the player is in.
class ContentsScreen extends ConsumerWidget {
  const ContentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final inProgress = ref.watch(inProgressProvider).value ?? const <BoardSave>[];
    final updateReady = ref.watch(updateReadyProvider);
    final solvedTotal = set.puzzles.where((x) => progress[x.id]?.isSolved ?? false).length;

    // Bookmark: the most recent board in progress, if any.
    final bookmark = inProgress.isEmpty
        ? null
        : set.puzzles.where((x) => x.id == inProgress.first.puzzleId).firstOrNull;
    final bookmarkSave = inProgress.isEmpty ? null : inProgress.first;

    // The collection to feature: the bookmark's, else the first unfinished.
    final featured =
        bookmark?.collectionId ??
        set.collections
            .firstWhere(
              (c) => set.inCollection(c.id).any((x) => !(progress[x.id]?.isSolved ?? false)),
              orElse: () => set.collections.first,
            )
            .id;
    final featuredIndex = set.collections.indexWhere((c) => c.id == featured);
    final featuredPlates = set.inCollection(featured);

    return FolioFillPage(
      minHeight: bookmark == null ? 560 : 620,
      child: Column(
        children: [
          // Takes the same line as the solved count, so nothing moves.
          updateReady
              ? WordmarkHeader(
                  trailing: 'Update ready · Restart',
                  onTrailing: ref.read(updateReadyProvider.notifier).install,
                )
              : WordmarkHeader(trailing: '$solvedTotal of ${set.puzzles.length} solved'),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Contents', style: FolioType.display(p)),
                  const SizedBox(height: 18),
                  const Hairline(strong: true),
                  if (bookmark != null && bookmarkSave != null) ...[
                    _Bookmark(puzzle: bookmark, save: bookmarkSave),
                    const Hairline(),
                  ],
                  const SizedBox(height: 8),
                  for (var i = 0; i < set.collections.length; i++)
                    _ContentsLine(
                      numeral: roman(i + 1),
                      name: set.collections[i].name,
                      solved: set
                          .inCollection(set.collections[i].id)
                          .where((x) => progress[x.id]?.isSolved ?? false)
                          .length,
                      total: set.inCollection(set.collections[i].id).length,
                      current: set.collections[i].id == featured,
                      onTap: () => context.push('/collection/${set.collections[i].id}'),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${roman(featuredIndex + 1)}. ${set.collections[featuredIndex].name.toUpperCase()} · PLATES',
                            maxLines: 1,
                            style: FolioType.kicker(p, color: p.textPrimary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => context.push('/collection/$featured'),
                        child: Text('All ${featuredPlates.length} →', style: FolioType.header(p)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // As many rows of plates as the page has room for, spread evenly.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) {
                        const gap = 12.0;
                        // Pick the column count that leaves the least height unused, so the
                    // plates fill the page on phones and tablets alike.
                    final options = c.maxWidth > 500 ? const [5, 6, 7, 8] : const [5];
                    var columns = options.first, rows = 1, tile = 0.0, best = double.infinity;
                    for (final n in options) {
                      final t = (c.maxWidth - gap * (n - 1)) / n;
                      final fit = (((c.maxHeight + gap) / (t + gap)).floor()).clamp(1, (featuredPlates.length / n).ceil());
                      final left = c.maxHeight - fit * (t + gap) + gap;
                      if (left >= 0 && left < best) {
                        best = left;
                        columns = n;
                        rows = fit;
                        tile = t;
                      }
                    }
                    if (tile == 0) tile = (c.maxWidth - gap * (columns - 1)) / columns;
                    return Column(
                          mainAxisAlignment: rows > 1 ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                          children: [
                            for (var r = 0; r < rows; r++)
                              Row(
                                children: [
                                  for (var i = 0; i < columns; i++) ...[
                                    if (i > 0) const SizedBox(width: gap),
                                    SizedBox(
                                      width: tile,
                                      child: r * columns + i < featuredPlates.length
                                          ? _PlateLink(
                                              puzzle: featuredPlates[r * columns + i],
                                              progress: progress,
                                              inProgress: inProgress,
                                            )
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bookmark extends StatelessWidget {
  const _Bookmark({required this.puzzle, required this.save});

  final PuzzleRecord puzzle;
  final BoardSave save;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filled = save.cells.split('').where((c) => c == '#').length;
    final target = puzzle.solution.filledCount;
    final pct = target == 0 ? 0 : (100 * filled / target).clamp(0, 99).round();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/play/${puzzle.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(width: 14, height: 22, color: p.accent),
            const SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Bookmark: ', style: FolioType.bodyMuted(p, size: 17)),
                    TextSpan(text: puzzle.name, style: FolioType.body(p)),
                    TextSpan(text: ' · $pct%', style: FolioType.bodyMuted(p, size: 17)),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Resume',
              style: FolioType.body(p).copyWith(decoration: TextDecoration.underline, decorationColor: p.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentsLine extends StatelessWidget {
  const _ContentsLine({
    required this.numeral,
    required this.name,
    required this.solved,
    required this.total,
    required this.current,
    required this.onTap,
  });

  final String numeral;
  final String name;
  final int solved;
  final int total;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = solved == total ? 'complete' : (solved == 0 ? 'not begun' : '$solved / $total');
    final italic = solved == total || solved == 0;
    return Semantics(
      button: true,
      label: '$name, $status',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 56,
                child: Text('$numeral.', style: FolioType.style(size: 19, color: current ? p.accent : p.textMuted)),
              ),
              // A table-of-contents leader: the name at its natural width (an
              // ellipsis only when it truly cannot fit), dots filling the rest.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, c) {
                    final nameStyle = FolioType.style(size: 24, color: p.textPrimary, weight: current ? 600 : 400);
                    final natural = (TextPainter(
                      text: TextSpan(text: name, style: nameStyle),
                      textDirection: TextDirection.ltr,
                      textScaler: MediaQuery.textScalerOf(context),
                      maxLines: 1,
                    )..layout()).width;
                    final nameWidth = math.min(natural + 1, math.max(0.0, c.maxWidth - 24));
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: nameWidth,
                          child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 7),
                            child: LayoutBuilder(
                              builder: (context, d) => Text(
                                '.' * (d.maxWidth / 4.2).floor(),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                style: FolioType.style(size: 10, color: p.ruleStrong, letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Text(
                status,
                style: italic
                    ? FolioType.style(size: 21, color: p.textMuted, italic: true)
                    : FolioType.style(size: 22, color: p.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlateLink extends StatelessWidget {
  const _PlateLink({required this.puzzle, required this.progress, required this.inProgress});

  final PuzzleRecord puzzle;
  final Map<String, PuzzleProgressData> progress;
  final List<BoardSave> inProgress;

  @override
  Widget build(BuildContext context) {
    final save = inProgress.where((s) => s.puzzleId == puzzle.id).firstOrNull;
    final solved = progress[puzzle.id]?.isSolved ?? false;
    return Semantics(
      button: true,
      label: solved ? '${puzzle.name}, solved' : 'Plate ${puzzle.plateNumber}',
      child: GestureDetector(
        onTap: () => context.push('/play/${puzzle.id}'),
        child: PlateThumb(
          puzzle: puzzle,
          state: solved ? PlateState.solved : (save != null ? PlateState.inProgress : PlateState.untouched),
          progressCells: save?.cells,
        ),
      ),
    );
  }
}
