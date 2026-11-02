import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

enum _View { collection, size, latest }

/// Every picture solved, pressed in order.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  var _view = _View.collection;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final progress = ref.watch(progressProvider).value ?? const <String, PuzzleProgressData>{};
    final solved = set.puzzles.where((x) => progress[x.id]?.isSolved ?? false).toList();

    if (solved.isEmpty) return _Empty(firstPlateId: set.puzzles.first.id);

    final groups = <(String, List<PuzzleRecord>)>[];
    switch (_view) {
      case _View.collection:
        for (var i = 0; i < set.collections.length; i++) {
          final c = set.collections[i];
          final list = solved.where((x) => x.collectionId == c.id).toList();
          if (list.isNotEmpty) groups.add(('${roman(i + 1)}. ${c.name.toUpperCase()}', list));
        }
      case _View.size:
        for (final s in [5, 10, 15, 20]) {
          final list = solved.where((x) => _sizeClass(x) == s).toList();
          if (list.isNotEmpty) groups.add(('$s × $s', list));
        }
      case _View.latest:
        final list = [...solved]
          ..sort((a, b) => (progress[b.id]?.solvedAt ?? DateTime(0)).compareTo(progress[a.id]?.solvedAt ?? DateTime(0)));
        groups.add(('MOST RECENT FIRST', list));
    }

    Widget tab(_View v, String label) => GestureDetector(
          onTap: () => setState(() => _view = v),
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: _view == v
                      ? FolioType.style(size: 19, color: p.textPrimary, weight: 500)
                      : FolioType.style(size: 19, color: p.textMuted, italic: true)),
              const SizedBox(height: 4),
              Container(height: 2, width: 120, color: _view == v ? p.accent : Colors.transparent),
            ]),
          ),
        );

    return ListView(padding: EdgeInsets.zero, children: [
      WordmarkHeader(trailing: solved.length == 1 ? '1 picture' : '${solved.length} pictures'),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Gallery', style: FolioType.display(p)),
          const SizedBox(height: 6),
          Text("Every picture you've solved, pressed in order.", style: FolioType.bodyMuted(p, size: 18)),
          const SizedBox(height: 18),
          const Hairline(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(children: [
              tab(_View.collection, 'By collection'),
              tab(_View.size, 'By size'),
              tab(_View.latest, 'Latest'),
            ]),
          ),
          const Hairline(),
          for (final (title, list) in groups) ...[
            const SizedBox(height: 22),
            Row(children: [
              Text(title, style: FolioType.kicker(p, color: p.textPrimary)),
              const Spacer(),
              Text(list.length == 1 ? '1 plate' : '${list.length} plates', style: FolioType.header(p)),
            ]),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, c) {
              final columns = c.maxWidth > 700 ? 8 : (c.maxWidth > 500 ? 6 : 5);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  for (final x in list)
                    Semantics(
                      button: true,
                      label: x.name,
                      child: GestureDetector(
                        onTap: () => context.push('/plate/${x.id}'),
                        child: PlateThumb(puzzle: x, state: PlateState.solved),
                      ),
                    ),
                ],
              );
            }),
          ],
        ]),
      ),
    ]);
  }

  static int _sizeClass(PuzzleRecord x) {
    final longest = x.width > x.height ? x.width : x.height;
    return longest <= 5 ? 5 : (longest <= 10 ? 10 : (longest <= 15 ? 15 : 20));
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.firstPlateId});

  final String firstPlateId;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const WordmarkHeader(trailing: '0 pictures'),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 0),
        child: Text('Gallery', style: FolioType.display(p)),
      ),
      Expanded(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: folioMargin),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(border: Border.all(color: p.ruleStrong)),
                padding: const EdgeInsets.all(8),
                child: CustomPaint(
                  painter: _DashedRect(p.ruleStrong),
                  child: Center(child: Text('PLATE I', style: FolioType.kicker(p, color: p.textMuted))),
                ),
              ),
              const SizedBox(height: 32),
              Text('Nothing pressed yet', style: FolioType.plateTitle(p, size: 34)),
              const SizedBox(height: 10),
              Text('Every picture you solve is kept here, like a plate in a book.',
                  textAlign: TextAlign.center, style: FolioType.bodyMuted(p, size: 18)),
              const SizedBox(height: 28),
              SizedBox(
                width: 230,
                child: InkButton(
                  label: 'Solve your first puzzle',
                  height: 54,
                  onPressed: () => context.push('/play/$firstPlateId'),
                ),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _DashedRect extends CustomPainter {
  _DashedRect(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 5.0, gap = 4.0;
    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      for (var d = 0.0; d < total; d += dash + gap) {
        canvas.drawLine(a + dir * d, a + dir * (d + dash).clamp(0, total), paint);
      }
    }

    line(Offset.zero, Offset(size.width, 0));
    line(Offset(size.width, 0), Offset(size.width, size.height));
    line(Offset(size.width, size.height), Offset(0, size.height));
    line(Offset(0, size.height), Offset.zero);
  }

  @override
  bool shouldRepaint(_DashedRect old) => old.color != color;
}
