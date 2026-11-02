import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
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
    final solvedTotal = set.puzzles.where((x) => progress[x.id]?.isSolved ?? false).length;

    // Bookmark: the most recent board in progress, if any.
    final bookmark = inProgress.isEmpty
        ? null
        : set.puzzles.where((x) => x.id == inProgress.first.puzzleId).firstOrNull;
    final bookmarkSave = inProgress.isEmpty ? null : inProgress.first;

    // The collection to feature: the bookmark's, else the first unfinished.
    final featured = bookmark?.collectionId ??
        set.collections
            .firstWhere(
              (c) => set.inCollection(c.id).any((x) => !(progress[x.id]?.isSolved ?? false)),
              orElse: () => set.collections.first,
            )
            .id;
    final featuredIndex = set.collections.indexWhere((c) => c.id == featured);
    final featuredPlates = set.inCollection(featured);

    return ListView(padding: EdgeInsets.zero, children: [
      WordmarkHeader(trailing: '$solvedTotal of ${set.puzzles.length} solved'),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
              solved: set.inCollection(set.collections[i].id).where((x) => progress[x.id]?.isSolved ?? false).length,
              total: set.inCollection(set.collections[i].id).length,
              current: set.collections[i].id == featured,
              onTap: () => context.push('/collection/${set.collections[i].id}'),
            ),
          const SizedBox(height: 28),
          Row(children: [
            Text('${roman(featuredIndex + 1)}. ${set.collections[featuredIndex].name.toUpperCase()} · FIRST PLATES',
                style: FolioType.kicker(p, color: p.textPrimary)),
            const Spacer(),
            GestureDetector(
              onTap: () => context.push('/collection/$featured'),
              child: Text('All ${featuredPlates.length} →', style: FolioType.header(p)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            for (var i = 0; i < 5 && i < featuredPlates.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(child: _PlateLink(puzzle: featuredPlates[i], progress: progress, inProgress: inProgress)),
            ],
          ]),
          const SizedBox(height: 32),
        ]),
      ),
    ]);
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
        child: Row(children: [
          Container(width: 14, height: 22, color: p.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: 'Bookmark: ', style: FolioType.bodyMuted(p, size: 17)),
                TextSpan(text: puzzle.name, style: FolioType.body(p)),
                TextSpan(text: ', $pct% solved', style: FolioType.bodyMuted(p, size: 17)),
              ]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('Resume',
              style: FolioType.body(p).copyWith(
                  decoration: TextDecoration.underline, decorationColor: p.textPrimary)),
        ]),
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
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            SizedBox(
              width: 64,
              child: Text('$numeral.',
                  style: FolioType.style(size: 19, color: current ? p.accent : p.textMuted)),
            ),
            Text(name, style: FolioType.style(size: 24, color: p.textPrimary, weight: current ? 600 : 400)),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: LayoutBuilder(
                  builder: (context, c) => Text(
                    '.' * (c.maxWidth / 4.2).floor(),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    style: FolioType.style(size: 10, color: p.ruleStrong, letterSpacing: 1.2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(status,
                style: italic
                    ? FolioType.style(size: 21, color: p.textMuted, italic: true)
                    : FolioType.style(size: 22, color: p.textPrimary)),
          ]),
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
