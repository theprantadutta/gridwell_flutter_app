import 'package:flutter/material.dart';

import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

/// One stop on the first-game walkthrough.
class TourStep {
  const TourStep({
    required this.title,
    required this.body,
    required this.targets,
  });

  final String title;
  final String body;

  /// The parts of the screen to light up, given the overlay's render box.
  final List<Rect> Function(RenderBox overlay) targets;
}

/// Dims the screen, lights up one control at a time, and explains it. Blocks
/// the board underneath until it is finished or skipped.
class BoardTour extends StatefulWidget {
  const BoardTour({super.key, required this.steps, required this.onDone});

  final List<TourStep> steps;
  final VoidCallback onDone;

  @override
  State<BoardTour> createState() => _BoardTourState();
}

class _BoardTourState extends State<BoardTour>
    with SingleTickerProviderStateMixin {
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: 1,
  );
  int _step = 0;
  List<Rect> _from = const [];
  List<Rect> _to = const [];
  Size? _measuredFor;

  @override
  void dispose() {
    _move.dispose();
    super.dispose();
  }

  void _measure({bool animate = false}) {
    if (!mounted) return;
    final overlay = context.findRenderObject();
    if (overlay is! RenderBox || !overlay.hasSize) return;
    final next = [
      for (final r in widget.steps[_step].targets(overlay)) r.inflate(4),
    ];
    setState(() {
      _from = _holes(_move.value);
      _to = next;
    });
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (animate && !still && _from.isNotEmpty) {
      _move.forward(from: 0);
    } else {
      _move.value = 1;
    }
  }

  /// The lit areas part-way through a move. A step with fewer areas than the
  /// last has its final area stand in for the missing ones.
  List<Rect> _holes(double t) {
    if (_from.isEmpty || t >= 1) return _to;
    final count = _from.length > _to.length ? _from.length : _to.length;
    Rect at(List<Rect> list, int i) =>
        list[i < list.length ? i : list.length - 1];
    final curved = Curves.easeOutCubic.transform(t);
    return [
      for (var i = 0; i < count; i++)
        Rect.lerp(at(_from, i), at(_to, i), curved)!,
    ];
  }

  void _next() {
    if (_step == widget.steps.length - 1) {
      widget.onDone();
      return;
    }
    setState(() => _step++);
    _measure(animate: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final step = widget.steps[_step];
    final last = _step == widget.steps.length - 1;
    return LayoutBuilder(
      builder: (context, c) {
        // First layout, and any rotation: find the controls again once laid out.
        if (_measuredFor != c.biggest) {
          _measuredFor = c.biggest;
          WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
        }
        if (_to.isEmpty) return const ModalBarrier(dismissible: false);
        // The card goes on the side with more room.
        final bounds = _to.reduce((a, b) => a.expandToInclude(b));
        final cardOnTop = bounds.top > c.maxHeight - bounds.bottom;
        return Stack(
          children: [
            const Positioned.fill(child: ModalBarrier(dismissible: false)),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _move,
                  builder: (context, _) => CustomPaint(
                    painter: _Spotlight(
                      holes: _holes(_move.value),
                      ring: p.accent,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: cardOnTop
                  ? Alignment.topCenter
                  : Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      key: ValueKey(_step),
                      decoration: BoxDecoration(
                        color: p.surfaceRaised,
                        border: Border.all(color: p.textPrimary, width: 1.2),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Flexible(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_step + 1} OF ${widget.steps.length}',
                                    style: FolioType.kicker(p),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    step.title,
                                    style: FolioType.plateTitle(p, size: 26),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    step.body,
                                    style: FolioType.body(p, size: 17),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              if (!last)
                                TextAction(
                                  label: 'Skip',
                                  onPressed: widget.onDone,
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkButton(
                                  label: last ? 'Start solving' : 'Next',
                                  height: 50,
                                  onPressed: _next,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Spotlight extends CustomPainter {
  _Spotlight({required this.holes, required this.ring});

  final List<Rect> holes;
  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size);
    // One combined cut-out, so overlapping areas stay lit.
    var cut = Path();
    for (final h in holes) {
      cut = Path.combine(PathOperation.union, cut, Path()..addRect(h));
    }
    canvas.drawPath(
      Path.combine(PathOperation.difference, scrim, cut),
      Paint()..color = const Color(0xB3000000),
    );
    canvas.drawPath(
      cut,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_Spotlight old) => old.holes != holes || old.ring != ring;
}
