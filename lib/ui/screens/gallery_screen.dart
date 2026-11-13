import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/daily.dart';
import '../../state/online.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/plate_thumb.dart';
import '../widgets/tally.dart';

/// Every picture you've solved, in color, filtered by collection.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  /// Collection id, or null for all.
  String? _filter;

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final set = ref.watch(puzzleSetProvider);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final solved = set.puzzles.where((x) => progress[x.id]?.isSolved ?? false).toList();
    final caption = solved.length == 1 ? '1 picture' : '${solved.length} pictures';

    if (solved.isEmpty) return _Empty(caption: caption);

    final collections = set.collections.where((c) => solved.any((x) => x.collectionId == c.id)).toList();
    if (_filter != null && !collections.any((c) => c.id == _filter)) _filter = null;
    final shown = _filter == null ? solved : solved.where((x) => x.collectionId == _filter).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        TallyPageTitle('Gallery', caption: caption),
        const SizedBox(height: 20),
        SizedBox(
          height: MediaQuery.textScalerOf(context).scale(31).clamp(31, 48).toDouble(),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
            children: [
              _Chip(label: 'All ${solved.length}', selected: _filter == null, onTap: () => setState(() => _filter = null)),
              for (final c in collections) ...[
                const SizedBox(width: 4),
                _Chip(label: c.name, selected: _filter == c.id, onTap: () => setState(() => _filter = c.id)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
          child: LayoutBuilder(builder: (context, c) {
            final columns = c.maxWidth > 520 ? 5 : 3;
            final tile = (c.maxWidth - _gap * (columns - 1)) / columns;
            final rows = (shown.length / columns).ceil();
            return Column(children: [
              for (var r = 0; r < rows; r++) ...[
                if (r > 0) const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    SizedBox(
                      width: tile,
                      child: r * columns + i < shown.length
                          ? _Picture(puzzle: shown[r * columns + i], timeMs: progress[shown[r * columns + i].id]?.bestTimeMs)
                          : null,
                    ),
                  ],
                ]),
              ],
            ]);
          }),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      color: selected ? p.lime : p.surface,
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Center(
          widthFactor: 1,
          child: Text(label, maxLines: 1, style: TallyType.body(selected ? p.onLime : p.ink2).copyWith(fontSize: 15, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.puzzle, required this.timeMs});

  final PuzzleRecord puzzle;
  final int? timeMs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = puzzle.width > puzzle.height ? puzzle.width : puzzle.height;
    final style = TallyType.body(p.ink).copyWith(fontSize: 14, fontWeight: FontWeight.w800);
    return Semantics(
      button: true,
      label: timeMs == null ? puzzle.name : '${puzzle.name}, ${formatClock(timeMs!)}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => context.push('/plate/${puzzle.id}'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Big pictures fill the tile; small ones keep a margin of tile.
          PlateThumb(puzzle: puzzle, state: PlateState.solved, background: p.tile, inset: n >= 15 ? 0 : 0.125),
          const SizedBox(height: 8),
          // Long names wrap to a second line rather than lose their ending.
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: LayoutBuilder(builder: (context, c) {
                // Shrink (to 75% at most) until the longest word fits, so a
                // word is never broken across lines; then wrap between words.
                final scaler = MediaQuery.textScalerOf(context);
                final widest = puzzle.name
                    .split(' ')
                    .map((w) => (TextPainter(
                          text: TextSpan(text: w, style: style),
                          textDirection: TextDirection.ltr,
                          textScaler: scaler,
                        )..layout())
                            .width)
                    .fold<double>(0, (a, b) => a > b ? a : b);
                final scale = widest <= c.maxWidth ? 1.0 : (c.maxWidth / widest).clamp(0.75, 1.0);
                return Text(
                  puzzle.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(height: 1.15, fontSize: style.fontSize! * scale - (scale < 1 ? 0.3 : 0)),
                );
              }),
            ),
            if (timeMs != null) ...[
              const SizedBox(width: 6),
              Text(formatClock(timeMs!), style: style.copyWith(color: p.ink2, height: 1.15)),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final today = ref.watch(todayDailyProvider);
    final todaySolved = (ref.watch(dailyResultsProvider).value ?? const {})[localDateString(DateTime.now())]?.solved ?? false;
    final daily = today != null && !todaySolved ? today : null;
    final first = set.puzzles.first;
    return LayoutBuilder(builder: (context, box) {
      const gap = 10.0;
      final columns = box.maxWidth > 520 ? 5 : 3;
      final tile = (box.maxWidth - 2 * tallyMargin - gap * (columns - 1)) / columns;
      // Measured: title, words and slab need about 372. The empty frames take
      // what is left, up to three rows, so the page never scrolls just to
      // show placeholders (tablet landscape fits one row).
      final scaled = MediaQuery.textScalerOf(context).scale(372);
      final rows = ((box.maxHeight - scaled + gap) / (tile + gap)).floor().clamp(1, 3);
      // A single row that still does not fit shrinks its frames instead.
      final frame = rows == 1 ? math.min(tile, math.max(60.0, box.maxHeight - scaled)) : tile;
      return TallyFillPage(
        minHeight: rows * frame + (rows - 1) * gap + 372,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TallyPageTitle('Gallery', caption: caption),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
            child: Column(children: [
              for (var r = 0; r < rows; r++) ...[
                if (r > 0) const SizedBox(height: gap),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: gap),
                    Container(
                      width: frame,
                      height: frame,
                      decoration: BoxDecoration(border: Border.all(color: p.outline)),
                    ),
                  ],
                ]),
              ],
            ]),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.fromLTRB(tallyMargin, 28, tallyMargin, 0),
            child: Text('Your pictures\nland here.', style: TallyType.titleL(p.ink).copyWith(fontSize: 36)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 28),
            child: Text(
              'Solve a puzzle and its picture is saved here in full color.',
              style: TallyType.prose(p.ink2, size: 16),
            ),
          ),
          if (daily != null)
            PrimarySlab(
              label: 'Play the daily',
              sublabel: '${daily.name} · ${daily.width}×${daily.height}',
              height: 92,
              bottomInset: false,
              onPressed: () => context.push('/play/${daily.id}'),
            )
          else
            PrimarySlab(
              label: 'Start No. 01',
              sublabel: '${first.width}×${first.height} · about a minute',
              height: 92,
              bottomInset: false,
              onPressed: () => context.push('/play/${first.id}'),
            ),
        ]),
      );
    });
  }
}
