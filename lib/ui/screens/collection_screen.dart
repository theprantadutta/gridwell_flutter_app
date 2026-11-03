import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

enum _Filter { all, solved, unsolved }

/// Inside a collection: every plate, with All / Solved / Unsolved filters.
class CollectionScreen extends ConsumerStatefulWidget {
  const CollectionScreen({super.key, required this.collectionId});

  final String collectionId;

  @override
  ConsumerState<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends ConsumerState<CollectionScreen> {
  var _filter = _Filter.all;

  static const _counts = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];

  String _countWord(int n) {
    const tens = ['', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty'];
    if (n <= 10) return _counts[n];
    if (n < 20) return '$n';
    final t = tens[n ~/ 10];
    final u = n % 10;
    return u == 0 ? t : '$t-${_counts[u].toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final index = set.collections.indexWhere((c) => c.id == widget.collectionId);
    final collection = set.collections[index];
    final plates = set.inCollection(collection.id);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final inProgress = ref.watch(inProgressProvider).value ?? const <BoardSave>[];
    final solved = plates.where((x) => progress[x.id]?.isSolved ?? false).toList();
    final shown = switch (_filter) {
      _Filter.all => plates,
      _Filter.solved => solved,
      _Filter.unsolved => plates.where((x) => !(progress[x.id]?.isSolved ?? false)).toList(),
    };
    final nextUnsolved = plates.where((x) => !(progress[x.id]?.isSolved ?? false)).firstOrNull;
    final sizes = plates.map((x) => x.width).toList()..sort();
    final notBegun = solved.isEmpty && inProgress.every((s) => !plates.any((x) => x.id == s.puzzleId));

    Widget filter(_Filter f, String label) => GestureDetector(
          onTap: () => setState(() => _filter = f),
          child: Padding(
            padding: const EdgeInsets.only(right: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: _filter == f
                      ? FolioType.style(size: 19, color: p.textPrimary, weight: 500)
                      : FolioType.style(size: 19, color: p.textMuted, italic: true)),
              const SizedBox(height: 4),
              Container(height: 2, width: 36, color: _filter == f ? p.accent : Colors.transparent),
            ]),
          ),
        );

    return Scaffold(
      body: FolioBody(
        maxWidth: 760,
        child: Column(children: [
          FolioHeader(
            leading: 'Contents',
            center: 'Collection ${roman(index + 1)}',
            trailing: Text('${solved.length} of ${plates.length}', style: FolioType.header(p)),
          ),
          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(horizontal: folioMargin), children: [
              const SizedBox(height: 22),
              Text('${roman(index + 1)}.', style: FolioType.kicker(p)),
              const SizedBox(height: 6),
              Text(collection.name, style: FolioType.display(p)),
              const SizedBox(height: 8),
              Text(
                notBegun
                    ? '${_countWord(plates.length)} plates, none drawn yet. They grow from '
                        '${sizes.first} × ${sizes.first} to ${sizes.last} × ${sizes.last}, so begin at the beginning.'
                    : '${_countWord(plates.length)} plates. ${collection.blurb} '
                        'From ${sizes.first} × ${sizes.first} to ${sizes.last} × ${sizes.last}.',
                style: FolioType.bodyMuted(p, size: 18),
              ),
              const SizedBox(height: 18),
              const Hairline(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  // Shrinks a touch on the narrowest phones instead of overflowing.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        filter(_Filter.all, 'All'),
                        filter(_Filter.solved, 'Solved ${solved.length}'),
                        filter(_Filter.unsolved, 'Unsolved ${plates.length - solved.length}'),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${(100 * solved.length / plates.length).round()}%',
                      style: FolioType.style(size: 19, color: p.textMuted)),
                ]),
              ),
              const Hairline(),
              const SizedBox(height: 18),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  child: Text(
                    _filter == _Filter.solved
                        ? 'No plates solved here yet. The first one is waiting.'
                        : 'Every plate in this collection is solved.',
                    textAlign: TextAlign.center,
                    style: FolioType.bodyMuted(p, size: 17),
                  ),
                ),
              LayoutBuilder(builder: (context, c) {
                final columns = c.maxWidth > 700 ? 8 : (c.maxWidth > 500 ? 6 : 5);
                // Square plate plus a caption line, sized for the system font
                // scale (a fixed aspect ratio overflows on enlarged text).
                final tile = (c.maxWidth - 12 * (columns - 1)) / columns;
                final caption = MediaQuery.textScalerOf(context).scale(13) * 1.45;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: shown.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 8,
                    mainAxisExtent: tile + 4 + caption + 4,
                  ),
                  itemBuilder: (context, i) {
                    final x = shown[i];
                    final save = inProgress.where((s) => s.puzzleId == x.id).firstOrNull;
                    final isSolved = progress[x.id]?.isSolved ?? false;
                    return GestureDetector(
                      onTap: () => context.push('/play/${x.id}'),
                      child: Column(children: [
                        PlateThumb(
                          puzzle: x,
                          state: isSolved
                              ? PlateState.solved
                              : (save != null ? PlateState.inProgress : PlateState.untouched),
                          progressCells: save?.cells,
                          highlighted: !isSolved && x.id == nextUnsolved?.id,
                        ),
                        const SizedBox(height: 4),
                        Row(children: [
                          Text('${x.plateNumber}', style: FolioType.style(size: 13, color: p.textMuted)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text('${x.width}×${x.height}',
                                  style: FolioType.style(size: 13, color: p.textMuted)),
                            ),
                          ),
                        ]),
                      ]),
                    );
                  },
                );
              }),
              const SizedBox(height: 20),
              if (notBegun && nextUnsolved != null)
                InkButton(
                  label: 'Begin with No. ${nextUnsolved.plateNumber}',
                  detail: '${nextUnsolved.width} × ${nextUnsolved.height}',
                  onPressed: () => context.push('/play/${nextUnsolved.id}'),
                ),
              const SizedBox(height: 28),
            ]),
          ),
        ]),
      ),
    );
  }
}
