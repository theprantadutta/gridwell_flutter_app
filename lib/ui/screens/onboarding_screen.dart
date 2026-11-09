import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// How to play, in three steps: read a clue, find the overlap, cross out and
/// reveal. Each step has a demo line of real cells.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pages = PageController();
  var _page = 0;

  Future<void> _finish({required bool play}) async {
    await ref.read(settingsProvider.notifier).update((s) => s.copyWith(onboardingDone: true));
    if (!mounted) return;
    final first = ref.read(puzzleSetProvider).puzzles.first;
    context.go('/contents');
    if (play) context.push('/play/${first.id}');
  }

  void _next() {
    if (_page < 2) {
      _pages.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    } else {
      _finish(play: true);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final picture = set.puzzles.where((x) => x.id == 'coastline-lighthouse').firstOrNull ??
        set.puzzles.where((x) => x.colorLayer != null).firstOrNull;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: TallyBody(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.only(left: tallyMargin),
                child: Row(children: [
                  Expanded(child: Overline('How to play · ${_page + 1}/3', color: p.accent)),
                  Semantics(
                    button: true,
                    label: 'Skip',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _finish(play: false),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, tallyMargin, 12),
                        child: Text('Skip', style: TallyType.body(p.ink2)),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Step(
                    number: 1,
                    title: 'Read a clue.',
                    body: 'The numbers beside each row and above each column are the runs of filled squares in that '
                        'line, in order.',
                    demo: _Demo(
                      lines: const [_LineSpec('3 2', '..........'), _LineSpec('3 2', '-###--##--')],
                      caption: '“3 2” means a run of 3, a gap of at least one, then a run of 2.',
                    ),
                  ),
                  _Step(
                    number: 2,
                    title: 'Find the overlap.',
                    body: 'You never guess. When a run is long, the squares it covers in every possible position must be '
                        'filled.',
                    demo: _Demo(
                      lines: const [_LineSpec('8', '..******..')],
                      caption: 'Wherever 8 sits in 10 squares, the middle 6 are always filled.',
                      indentCaption: true,
                    ),
                  ),
                  _Step(
                    number: 3,
                    title: 'Cross out, then reveal.',
                    body: 'Mark squares you know are empty. Finish every line and the picture appears in full color.',
                    demo: _Demo(
                      lines: const [_LineSpec('3', '###---'), _LineSpec('2', '--##--')],
                      cell: 25,
                      picture: picture,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(tallyMargin, 8, tallyMargin, 20),
              child: Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 28 : 6,
                    height: 6,
                    color: i == _page ? p.lime : p.track,
                  ),
                ],
              ]),
            ),
            PrimarySlab(label: _page < 2 ? 'Next' : 'Start playing', onPressed: _next, height: 78),
          ]),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body, required this.demo});

  final int number;
  final String title;
  final String body;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return TallyFillPage(
      minHeight: 520,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 14),
          Text('$number', style: TallyType.displayXl(p.ink)),
          const SizedBox(height: 14),
          Text(title, style: TallyType.titleL(p.ink)),
          const SizedBox(height: 16),
          Text(body, style: TallyType.prose(p.ink2, size: 16).copyWith(height: 1.5)),
          Expanded(child: Center(child: demo)),
        ]),
      ),
    );
  }
}

/// One demo line: `.` empty, `#` filled, `*` filled with a lime ring, `-` crossed.
class _LineSpec {
  const _LineSpec(this.clue, this.cells);

  final String clue;
  final String cells;
}

class _Demo extends StatelessWidget {
  const _Demo({required this.lines, this.caption, this.indentCaption = false, this.cell = 28, this.picture});

  final List<_LineSpec> lines;
  final String? caption;
  final bool indentCaption;

  /// Cell pitch: cell plus its 1 pt gap.
  final double cell;
  final PuzzleRecord? picture;

  static const _clueWidth = 52.0, _clueGap = 13.0, _pictureGap = 20.0, _pictureSize = 110.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      final n = lines.first.cells.length;
      final withPicture = picture != null;
      final room = c.maxWidth - _clueWidth - _clueGap - (withPicture ? _pictureGap + _pictureSize : 0);
      final pitch = math.min(cell, (room - 1) / n).floorToDouble();
      final linesBlock = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) SizedBox(height: withPicture ? 11 : 22),
          Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
              width: _clueWidth,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (final (j, n) in lines[i].clue.split(' ').indexed) ...[
                  if (j > 0) const SizedBox(width: 8),
                  Text(n, maxLines: 1, style: TallyType.style(size: 22, color: p.ink, weight: FontWeight.w900, height: 1)),
                ],
              ]),
            ),
            const SizedBox(width: _clueGap),
            _Cells(cells: lines[i].cells, pitch: pitch),
          ]),
        ],
      ]);
      return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (withPicture)
          Row(mainAxisSize: MainAxisSize.min, children: [
            linesBlock,
            const SizedBox(width: _pictureGap),
            Container(
              width: _pictureSize,
              height: _pictureSize,
              color: p.tile,
              padding: const EdgeInsets.all(10),
              child: CustomPaint(painter: _PicturePainter(picture!, p)),
            ),
          ])
        else
          linesBlock,
        if (caption != null)
          Padding(
            padding: EdgeInsets.only(top: 22, left: indentCaption ? _clueWidth + _clueGap : 0),
            child: SizedBox(
              width: indentCaption ? pitch * n : c.maxWidth,
              child: Text(caption!, style: TallyType.label(p.ink2).copyWith(fontSize: 13.5)),
            ),
          ),
      ]);
    });
  }
}

/// A line of board cells on the `--sunk` grid: 1 pt gaps, square cells.
class _Cells extends StatelessWidget {
  const _Cells({required this.cells, required this.pitch});

  final String cells;
  final double pitch;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final size = pitch - 1;
    return Container(
      color: p.sunk,
      padding: const EdgeInsets.all(1),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 1),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: switch (cells[i]) {
                '#' || '*' => p.ink,
                _ => p.cell,
              },
              border: cells[i] == '*' ? Border.all(color: p.lime, width: 2) : null,
            ),
            alignment: Alignment.center,
            child: cells[i] == '-' ? Container(width: size * 0.4, height: 2, color: p.mark) : null,
          ),
        ],
      ]),
    );
  }
}

/// The revealed picture, square pixels in the art palette.
class _PicturePainter extends CustomPainter {
  _PicturePainter(this.puzzle, this.palette);

  final PuzzleRecord puzzle;
  final GridwellPalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final w = puzzle.width, h = puzzle.height;
    final px = math.min(size.width / w, size.height / h);
    final origin = Offset((size.width - px * w) / 2, (size.height - px * h) / 2);
    final colors = puzzle.colorLayer;
    final paint = Paint();
    for (var r = 0; r < h; r++) {
      for (var c = 0; c < w; c++) {
        final i = r * w + c;
        final index = colors?[i] ?? (puzzle.solution.cells[i] ? 1 : 0);
        if (index == 0) continue;
        paint.color = palette.art[index.clamp(0, palette.art.length - 1)];
        canvas.drawRect(Rect.fromLTWH(origin.dx + c * px, origin.dy + r * px, px, px), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_PicturePainter old) => old.puzzle != puzzle || old.palette != palette;
}
