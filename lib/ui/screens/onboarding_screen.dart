import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers.dart';
import '../../state/settings.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

/// Three pages: reading a clue, finding the overlap, crossing out.
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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final first = ref.watch(puzzleSetProvider).puzzles.first;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: folioMargin),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              height: 56,
              child: Row(children: [
                for (var i = 0; i < 3; i++) ...[
                  Container(
                    width: 44,
                    height: 3,
                    color: i == _page ? p.accent : (i < _page ? p.textPrimary : p.rule),
                  ),
                  const SizedBox(width: 10),
                ],
                const Spacer(),
                if (_page < 2) TextAction(label: 'Skip', onPressed: () => _finish(play: false)),
              ]),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _Page(
                    kicker: 'HOW TO READ A CLUE',
                    title: 'Each number is a run of filled squares',
                    body: [
                      _Strip(clue: '3 1', cells: '..###..#..', brackets: const [(2, 5, '3'), (7, 8, '1')]),
                      const SizedBox(height: 18),
                      Text('The same clue, placed differently:', style: FolioType.bodyMuted(p)),
                      const SizedBox(height: 8),
                      const _Strip(clue: '3 1', cells: '###......#'),
                      const SizedBox(height: 28),
                      Text.rich(TextSpan(children: [
                        TextSpan(text: '3 1', style: FolioType.body(p, size: 19).copyWith(fontWeight: FontWeight.w600)),
                        TextSpan(
                          text: ' means three filled squares in a row, then at least one gap, then one more. '
                              'The order is fixed; the gaps can be any size.',
                          style: FolioType.body(p, size: 19).copyWith(color: p.textMuted),
                        ),
                      ])),
                    ],
                  ),
                  _Page(
                    kicker: "FINDING WHAT'S CERTAIN",
                    title: 'Long runs always cover the middle',
                    body: [
                      Text('Pushed as far left as it goes', style: FolioType.bodyMuted(p)),
                      const SizedBox(height: 6),
                      const _Strip(clue: '7', cells: '///////...'),
                      const SizedBox(height: 16),
                      Text('Pushed as far right as it goes', style: FolioType.bodyMuted(p)),
                      const SizedBox(height: 6),
                      const _Strip(clue: '7', cells: '...///////'),
                      const SizedBox(height: 22),
                      Text('COVERED EITHER WAY: FILL IT', style: FolioType.kicker(p)),
                      const SizedBox(height: 6),
                      const _Strip(clue: '7', cells: '...####...', ring: (3, 7)),
                      const SizedBox(height: 26),
                      Text(
                        'A 7 in ten squares can slide three places, but squares 4 to 7 are covered '
                        'in every position. Fill those, even before you know the rest.',
                        style: FolioType.body(p, size: 19).copyWith(color: p.textMuted),
                      ),
                    ],
                  ),
                  _Page(
                    kicker: 'CROSSING OUT',
                    title: "Cross off what can't be filled",
                    body: [
                      const _Strip(clue: '2', cells: 'xxxx##xxxx', retired: true),
                      const SizedBox(height: 22),
                      Text(
                        "When a row's runs are all placed, its clue is struck through. Cross the "
                        'remaining squares so you never fill them by mistake.',
                        style: FolioType.body(p, size: 19).copyWith(color: p.textMuted),
                      ),
                      const SizedBox(height: 22),
                      const Hairline(),
                      const SizedBox(height: 22),
                      Row(children: [
                        SizedBox(
                          width: 110,
                          child: Container(
                            decoration: BoxDecoration(border: Border.all(color: p.textPrimary)),
                            padding: const EdgeInsets.all(6),
                            child: PlateThumb(puzzle: first, state: PlateState.solved),
                          ),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Text(
                            'Solve every row and column, and the hidden picture is pressed into your gallery.',
                            style: FolioType.body(p, size: 19),
                          ),
                        ),
                      ]),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkButton(
                label: _page < 2 ? 'Next' : 'Begin your first puzzle',
                detail: switch (_page) {
                  0 => "Finding what's certain",
                  1 => 'Crossing out',
                  _ => '${first.width} × ${first.height}',
                },
                onPressed: () {
                  if (_page < 2) {
                    _pages.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
                  } else {
                    _finish(play: true);
                  }
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.kicker, required this.title, required this.body});

  final String kicker;
  final String title;
  final List<Widget> body;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 40),
        Text(kicker, style: FolioType.kicker(p)),
        const SizedBox(height: 12),
        Text(title, style: FolioType.plateTitle(p, size: 38).copyWith(fontWeight: FontWeight.w400)),
        const SizedBox(height: 32),
        ...body,
      ]),
    );
  }
}

/// A single illustrated line: `.` empty, `#` filled, `/` hatched, `x` crossed.
class _Strip extends StatelessWidget {
  const _Strip({required this.clue, required this.cells, this.brackets = const [], this.ring, this.retired = false});

  final String clue;
  final String cells;
  final List<(int, int, String)> brackets;
  final (int, int)? ring;
  final bool retired;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      const clueWidth = 44.0;
      // Subtract the 1.2 px border on each side so the strip never overflows.
      final cell = ((c.maxWidth - clueWidth - 3) / cells.length).clamp(20.0, 52.0);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          SizedBox(
            width: clueWidth,
            child: Text(clue,
                style: FolioType.style(
                  size: 20,
                  weight: 600,
                  color: retired ? p.clueRetired : p.clueText,
                ).copyWith(decoration: retired ? TextDecoration.lineThrough : null)),
          ),
          Stack(clipBehavior: Clip.none, children: [
            Container(
              decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
              child: Row(children: [
                for (var i = 0; i < cells.length; i++)
                  Container(
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: cells[i] == '#' ? p.cellFilled : p.cellEmpty,
                      border: i == 0 ? null : Border(left: BorderSide(color: cells[i] == '#' ? p.cellEmpty : p.gridLine)),
                    ),
                    child: switch (cells[i]) {
                      '/' => CustomPaint(painter: _Hatch(p.ruleStrong)),
                      'x' => Icon(Icons.close, size: cell * 0.7, color: p.cellCrossed),
                      _ => null,
                    },
                  ),
              ]),
            ),
            if (ring != null)
              Positioned(
                left: ring!.$1 * cell - 4,
                top: -4,
                child: Container(
                  width: (ring!.$2 - ring!.$1 + 1) * cell + 8,
                  height: cell + 8,
                  decoration: BoxDecoration(border: Border.all(color: p.accent, width: 2)),
                ),
              ),
          ]),
        ]),
        if (brackets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: clueWidth, top: 6),
            child: SizedBox(
              height: 40,
              width: cell * cells.length,
              child: Stack(children: [
                for (final (from, to, label) in brackets)
                  Positioned(
                    left: from * cell,
                    width: (to - from) * cell,
                    top: 0,
                    child: Column(children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: p.accent, width: 1.2),
                            right: BorderSide(color: p.accent, width: 1.2),
                            bottom: BorderSide(color: p.accent, width: 1.2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(label, style: FolioType.style(size: 18, color: p.accent, weight: 600)),
                    ]),
                  ),
              ]),
            ),
          ),
      ]);
    });
  }
}

class _Hatch extends CustomPainter {
  _Hatch(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var d = -size.height; d < size.width; d += 7) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Hatch old) => old.color != color;
}
