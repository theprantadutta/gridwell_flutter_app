import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/cell_state.dart';
import '../../engine/model/clues.dart';
import '../../state/board_controller.dart';
import '../../state/monetization.dart' show bonusHintsProvider;
import '../../state/providers.dart';
import '../../state/services.dart';
import '../../state/settings.dart';
import '../board/board_geometry.dart';
import '../board/board_painter.dart';
import '../board/board_tour.dart';
import '../board/board_view.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/tally.dart';

/// Loads the saved board, then shows [_BoardPage].
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedBoardProvider(puzzleId));
    return Scaffold(
      body: SafeArea(
        // The mode slabs run to the bottom edge and pad for the home
        // indicator themselves.
        bottom: false,
        child: saved.isLoading ? const SizedBox() : _BoardPage(puzzleId: puzzleId),
      ),
    );
  }
}

class _BoardPage extends ConsumerStatefulWidget {
  const _BoardPage({required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<_BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<_BoardPage> with WidgetsBindingObserver {
  late final BoardController _controller;
  Timer? _ticker;
  bool _navigated = false;

  // What the first-game walkthrough points at.
  final _boardKey = GlobalKey();
  final _timerKey = GlobalKey();
  final _readoutKey = GlobalKey();
  final _undoKey = GlobalKey();
  final _modeKey = GlobalKey();
  final _hintKey = GlobalKey();

  /// The clock waits until the walkthrough is over.
  late bool _touring = !ref.read(settingsProvider).boardTourDone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(boardControllerProvider(widget.puzzleId).notifier);
    if (!_touring) _controller.resume();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _controller.logAbandon('exit');
    _controller.pause();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _controller.pause();
        _controller.logAbandon('background');
        unawaited(ref.read(analyticsProvider).flush());
      case AppLifecycleState.resumed:
        _controller.resetAbandon();
        if (!_touring) _controller.resume();
      default:
        break;
    }
  }

  Future<void> _hint() async {
    final outcome = await _controller.requestHint();
    if (!mounted) return;
    final message = switch (outcome) {
      HintOutcome.nothingToHint => 'Nothing left to hint here.',
      HintOutcome.shownAfterAd => "Thanks for watching. Here's your hint.",
      HintOutcome.shownFree => "No video right now, so this hint is on us.",
      HintOutcome.shownFromBonus => 'Bonus hint used. Here it is.',
      HintOutcome.adNotWatched => 'The video was closed early, so no hint this time.',
      HintOutcome.shown => null,
    };
    if (message != null) tallyToast(context, message);
  }

  void _endTour() {
    setState(() => _touring = false);
    _controller.resume();
    unawaited(ref.read(settingsProvider.notifier).update((s) => s.copyWith(boardTourDone: true)));
  }

  Rect _rectOf(GlobalKey key, RenderBox overlay) {
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  /// The grid and clue strips, found the way [BoardView] lays them out.
  (Rect grid, List<Rect> clues) _boardParts(RenderBox overlay, {required bool center}) {
    final view = _rectOf(_boardKey, overlay);
    final g = BoardGeometry.fit(ref.read(boardControllerProvider(widget.puzzleId)).puzzle.clues, view.size);
    final origin = view.topLeft + g.originIn(view.size, center: center);
    final grid = g.gridRect.shift(origin);
    return (
      grid,
      [
        Rect.fromLTRB(grid.left, origin.dy + BoardGeometry.tickBand, grid.right, grid.top),
        Rect.fromLTRB(origin.dx, grid.top, grid.left, grid.bottom),
      ],
    );
  }

  List<TourStep> _tourSteps({required bool timer, required bool readout, required bool center}) => [
        TourStep(
          title: 'The clues',
          body: 'Each number is a run of filled squares, in order. Numbers on top read down their '
              'column, and numbers at the side read across their row.',
          targets: (o) => _boardParts(o, center: center).$2,
        ),
        TourStep(
          title: 'The grid',
          body: 'Tap a square to mark it, or drag across several at once. '
              'On the biggest boards, pinch to zoom in.',
          targets: (o) => [_boardParts(o, center: center).$1],
        ),
        TourStep(
          title: 'Fill or mark',
          body: 'FILL marks a square as part of the picture. MARK puts a dash on one you know is empty. '
              'Dashes are only notes to yourself.',
          targets: (o) => [_rectOf(_modeKey, o)],
        ),
        if (readout)
          TourStep(
            title: 'Row and column',
            body: 'The clues for the square you touched appear here, large enough to read. '
                'Finished clues fade.',
            targets: (o) => [_rectOf(_readoutKey, o)],
          ),
        TourStep(
          title: 'Undo',
          body: 'Takes back your last move. Use it as often as you like.',
          targets: (o) => [_rectOf(_undoKey, o)],
        ),
        TourStep(
          title: 'Hint',
          body: 'Stuck? A hint finds the next square logic can prove and shows its working. '
              'The number beside it shows how many you have left.',
          targets: (o) => [_rectOf(_hintKey, o)],
        ),
        if (timer)
          TourStep(
            title: 'Your time',
            body: 'The clock starts when you do and pauses when you leave. You can hide it in Settings.',
            targets: (o) => [_rectOf(_timerKey, o)],
          ),
      ];

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(boardControllerProvider(widget.puzzleId));
    final settings = ref.watch(settingsProvider);
    final set = ref.watch(puzzleSetProvider);
    final p = context.palette;
    final puzzle = session.puzzle;
    final isDaily = puzzle.collectionId == 'daily';
    final collectionName =
        isDaily ? 'The Daily' : set.collections.firstWhere((c) => c.id == puzzle.collectionId).name;

    // Turn the page once the solve is recorded (not merely detected).
    ref.listen(lastCompletionProvider, (_, result) {
      if (_navigated || result == null || result.puzzle.id != widget.puzzleId) return;
      _navigated = true;
      final router = GoRouter.of(context);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) router.pushReplacement('/complete');
      });
    });

    // The walkthrough points at the controls, so an open note waits behind it.
    final note = _touring ? null : session.note;
    // Boards up to 15×15 show the big clock under the grid. 20×20 boards have
    // tiny clues, so that space holds a large readout of the active lines and
    // the clock moves up to the top bar. Hiding the clock also frees the space
    // for the readout.
    final bigTimer = settings.showTimer && puzzle.width < 20;
    final readout = !bigTimer;
    final clock = formatClock(_controller.elapsedMs);
    final topTimer = settings.showTimer && (!bigTimer || note != null);

    final topBar = TallyTopBar(
      title: puzzle.name,
      chip: '${puzzle.width}×${puzzle.height}',
      onBack: () => context.pop(),
      trailing: topTimer
          ? Text.rich(clockSpan(clock, TallyType.tabular(TallyType.titleS(p.ink))), key: note == null ? _timerKey : null, maxLines: 1)
          : null,
    );

    Widget boardView({required bool center}) => BoardView(
          key: _boardKey,
          clues: puzzle.clues,
          board: session.board,
          rowRetired: session.rowRetired,
          colRetired: session.colRetired,
          mistakes: settings.showProvenMistakes ? session.mistakeCells : const {},
          cursorRow: session.cursorRow,
          cursorCol: session.cursorCol,
          hint: note != null && note.kind == BoardNoteKind.hint && note.result != null
              ? HintMark(note.row, note.col, note.result!)
              : null,
          errorLine: note != null && note.kind == BoardNoteKind.mistake
              ? ErrorLine(isRow: note.lineAxisIsRow, index: note.lineIndex)
              : null,
          center: center,
          enabled: !session.solved,
          onStrokeStart: _controller.strokeStart,
          onStrokeMove: _controller.strokeMove,
          onStrokeEnd: _controller.strokeEnd,
          onStrokeCancel: _controller.strokeCancel,
        );

    final bigModes = puzzle.width < 20;
    Widget dock({required double inset}) {
      final middle = bigTimer
          ? _BigClock(
              timerKey: _timerKey,
              clock: clock,
              label: isDaily ? 'ELAPSED\nTHE DAILY' : 'ELAPSED\n${collectionName.toUpperCase()} ${puzzle.plateNumber}',
            )
          : _LineReadout(key: _readoutKey, session: session);
      return Stack(
        fit: StackFit.expand,
        children: [
          Column(children: [
            Expanded(child: middle),
            _Controls(
              session: session,
              controller: _controller,
              onHint: _hint,
              undoKey: _undoKey,
              modeKey: _modeKey,
              hintKey: _hintKey,
              modeHeight: bigModes ? 132 : 104,
              inset: inset,
            ),
          ]),
          // A hint or mistake covers the dock exactly; the board and the
          // controls beneath never move.
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, a) => FadeTransition(
                opacity: a,
                child: SlideTransition(
                  position: Tween(begin: const Offset(0, 0.06), end: Offset.zero).animate(a),
                  child: child,
                ),
              ),
              child: note == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : note.kind == BoardNoteKind.hint
                      ? _HintSheet(
                          key: ValueKey('hint ${note.row} ${note.col}'),
                          note: note,
                          session: session,
                          controller: _controller,
                          inset: inset,
                        )
                      : _MistakeSheet(
                          key: ValueKey('mistake ${note.row} ${note.col}'),
                          note: note,
                          controller: _controller,
                          inset: inset,
                        ),
            ),
          ),
        ],
      );
    }

    final page = LayoutBuilder(builder: (context, c) {
      final inset = MediaQuery.paddingOf(context).bottom;
      final scaler = MediaQuery.textScalerOf(context);
      // Tablets in landscape: the board on the left, the dock beside it.
      final sideBySide = c.maxWidth >= 840 && c.maxWidth > c.maxHeight * 1.15;
      if (sideBySide) {
        return Column(children: [
          topBar,
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: Padding(padding: const EdgeInsets.all(16), child: boardView(center: true))),
              SizedBox(width: 400, child: dock(inset: inset)),
            ]),
          ),
        ]);
      }
      // Everything below the board is a fixed-height dock, worked out from the
      // screen and the puzzle alone, so nothing on the page ever moves.
      final controls = scaler.scale(58).clamp(58.0, 92.0) + tallyDivider + (bigModes ? 132 : 104) + inset;
      final middleMin = scaler.scale(bigTimer ? 92 : 104).clamp(92.0, 170.0);
      final boardRoom = Size(c.maxWidth, math.max(120, c.maxHeight - 56 - 8 - controls - middleMin));
      final g = BoardGeometry.fit(puzzle.clues, boardRoom);
      final boardHeight = math.min(boardRoom.height, g.totalSize.height + 1);
      return Column(children: [
        topBar,
        const SizedBox(height: 8),
        SizedBox(height: boardHeight, child: boardView(center: false)),
        Expanded(child: dock(inset: inset)),
      ]);
    });

    if (!_touring) return page;
    return Stack(children: [
      page,
      Positioned.fill(
        child: LayoutBuilder(
          builder: (context, c) => BoardTour(
            steps: _tourSteps(
              timer: settings.showTimer,
              readout: readout,
              center: c.maxWidth >= 840 && c.maxWidth > c.maxHeight * 1.15,
            ),
            onDone: _endTour,
          ),
        ),
      ),
    ]);
  }
}

/// "6:18" at `display-m` with "ELAPSED / COASTLINE 15" beside it.
class _BigClock extends StatelessWidget {
  const _BigClock({required this.timerKey, required this.clock, required this.label});

  final Key timerKey;
  final String clock;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text.rich(clockSpan(clock, TallyType.displayM(p.ink)), key: timerKey, maxLines: 1),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TallyType.overline(p.ink2).copyWith(fontSize: 12, height: 1.45, letterSpacing: 12 * 0.08),
          ),
        ),
      ]),
    );
  }
}

/// "ROW 12  2 10 | COLUMN 9  8 1" under a 20×20 board, at a size you can read
/// away from the tiny grid. Before the first tap it says how to play.
///
/// Every line of clues is set at one size for the whole puzzle, chosen so the
/// longest fits, inside a block of fixed height. Moving between rows changes
/// the numbers and nothing else: no rescaling, no re-centering.
class _LineReadout extends StatelessWidget {
  const _LineReadout({super.key, required this.session});

  final BoardSession session;

  static const _divider = 33.0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scaler = MediaQuery.textScalerOf(context);
    final r = session.cursorRow, c = session.cursorCol;
    final clues = session.puzzle.clues;
    return Padding(
      padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 12),
      child: LayoutBuilder(builder: (context, box) {
        final size = _clueSize(clues, (box.maxWidth - _divider) / 2, scaler);
        final kicker = TallyType.overline(p.accent).copyWith(fontSize: 12);
        final kickerHeight = _height('ROW', kicker, scaler);
        final numbersHeight = _height('0', TallyType.tabular(TallyType.titleL(p.ink)).copyWith(fontSize: size), scaler);
        final blockHeight = math.min(box.maxHeight, kickerHeight + 10 + numbersHeight);

        Widget line(String label, List<int> values, Set<int> retired) {
          final zero = Clues.blocksOf(values).isEmpty;
          return Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, maxLines: 1, style: kicker),
              const SizedBox(height: 10),
              SizedBox(
                height: numbersHeight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(children: [
                    for (var j = 0; j < values.length; j++) ...[
                      if (j > 0) SizedBox(width: size * 0.3),
                      Text(
                        '${values[j]}',
                        maxLines: 1,
                        style: TallyType.tabular(TallyType.titleL(zero || retired.contains(j) ? p.ink3 : p.ink)).copyWith(fontSize: size),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            height: blockHeight,
            width: box.maxWidth,
            child: r == null || c == null
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Tap or drag across the squares. The clues say how many are filled, and in what runs.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TallyType.prose(p.ink2),
                    ),
                  )
                : Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    line('ROW ${r + 1}', clues.rows[r], session.rowRetired[r]),
                    VerticalDivider(color: p.track, width: _divider, thickness: 1),
                    line('COLUMN ${c + 1}', clues.columns[c], session.colRetired[c]),
                  ]),
          ),
        );
      }),
    );
  }

  static double _height(String text, TextStyle style, TextScaler scaler) =>
      (TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textScaler: scaler)
            ..layout())
          .height;

  /// The largest size, up to 30, at which every row and column clue fits on
  /// one line in [width].
  static double _clueSize(Clues clues, double width, TextScaler scaler) {
    const base = 30.0;
    final style = TallyType.titleL(const Color(0xFF000000)).copyWith(fontSize: base);
    var widest = 0.0;
    for (final line in [...clues.rows, ...clues.columns]) {
      final digits = TextPainter(
        text: TextSpan(text: line.join(), style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, digits.width + base * 0.3 * (line.length - 1));
    }
    if (widest <= width) return base;
    return math.max(12, (base * width / widest).floorToDouble());
  }
}

/// Undo | Hint over the FILL and MARK slabs.
class _Controls extends ConsumerWidget {
  const _Controls({
    required this.session,
    required this.controller,
    required this.onHint,
    required this.undoKey,
    required this.modeKey,
    required this.hintKey,
    required this.modeHeight,
    required this.inset,
  });

  final BoardSession session;
  final BoardController controller;
  final VoidCallback onHint;
  final Key undoKey;
  final Key modeKey;
  final Key hintKey;
  final double modeHeight;
  final double inset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final premium = ref.watch(entitlementsProvider).premium;
    final bonus = ref.watch(bonusHintsProvider);
    final hintsLeft = premium ? null : session.freeHintsLeft + bonus;
    return ColoredBox(
      color: p.sunk,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SlabRow(children: [
          SlabButton(key: undoKey, label: 'Undo', enabled: session.canUndo, onPressed: controller.undo),
          SlabButton(
            key: hintKey,
            label: 'Hint',
            onPressed: onHint,
            trailing: hintsLeft == null ? null : CountBadge(hintsLeft > 0 ? '$hintsLeft' : '▶'),
          ),
        ]),
        const SizedBox(height: tallyDivider),
        SizedBox(
          key: modeKey,
          height: modeHeight + inset,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: _ModeSlab(
                label: 'FILL',
                glyph: _Glyph.square,
                selected: session.mode == InputMode.fill,
                onTap: () => controller.setMode(InputMode.fill),
                inset: inset,
              ),
            ),
            const SizedBox(width: tallyDivider),
            Expanded(
              child: _ModeSlab(
                label: 'MARK',
                glyph: _Glyph.dash,
                selected: session.mode == InputMode.cross,
                onTap: () => controller.setMode(InputMode.cross),
                inset: inset,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

enum _Glyph { square, dash }

/// A mode slab: lime when it is the active mode, `--surface` otherwise. A
/// 20 pt glyph sits 12 pt above the label.
class _ModeSlab extends StatelessWidget {
  const _ModeSlab({required this.label, required this.glyph, required this.selected, required this.onTap, required this.inset});

  final String label;
  final _Glyph glyph;
  final bool selected;
  final VoidCallback onTap;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? p.onLime : p.ink2;
    return Pressable(
      color: selected ? p.lime : p.surface,
      onTap: onTap,
      selected: selected,
      semanticLabel: label == 'FILL' ? 'Fill' : 'Mark',
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 16, 24 + inset * 0.7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Center(
                child: Container(width: 20, height: glyph == _Glyph.square ? 20 : 3.5, color: fg),
              ),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(label, maxLines: 1, style: TallyType.slab(fg)),
            ),
          ],
        ),
      ),
    );
  }
}

/// The action pair at the foot of a sheet: two full-height slabs.
class _SheetActions extends StatelessWidget {
  const _SheetActions({required this.inset, required this.left, required this.right});

  final double inset;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 62 + inset,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: left),
          Expanded(child: right),
        ]),
      );
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({required this.label, required this.color, required this.textColor, required this.onTap, required this.inset});

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final double inset;

  @override
  Widget build(BuildContext context) => Pressable(
        color: color,
        onTap: onTap,
        semanticLabel: label[0] + label.substring(1).toLowerCase(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 0, 16, inset * 0.7),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1, style: TallyType.slab(textColor)),
            ),
          ),
        ),
      );
}

/// A hint, before it is placed: what the square is and why, with the line
/// drawn out. APPLY places it; CLOSE leaves the board as it is.
class _HintSheet extends ConsumerWidget {
  const _HintSheet({super.key, required this.note, required this.session, required this.controller, required this.inset});

  final BoardNote note;
  final BoardSession session;
  final BoardController controller;
  final double inset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final premium = ref.watch(entitlementsProvider).premium;
    final left = session.freeHintsLeft;
    final text = note.conclusion == null ? note.body : '${note.body} ${note.conclusion}';
    return Container(
      decoration: BoxDecoration(color: p.surface, border: Border(top: BorderSide(color: p.lime, width: 4))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(tallyMargin, 20, tallyMargin, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Overline(premium ? 'Hint' : 'Hint · $left left', color: p.accent)),
                Text('Row ${note.row + 1} · Column ${note.col + 1}', style: TallyType.label(p.ink2)),
              ]),
              const SizedBox(height: 12),
              Text(note.headline, style: TallyType.titleM(p.ink).copyWith(fontSize: 26)),
              const SizedBox(height: 10),
              Text(text, style: TallyType.prose(p.ink2, size: 14)),
              if (note.diagram != null) ...[
                const SizedBox(height: 14),
                _LineDiagram(diagram: note.diagram!, result: note.result),
              ],
            ]),
          ),
        ),
        _SheetActions(
          inset: inset,
          left: _SheetButton(label: 'APPLY', color: p.lime, textColor: p.onLime, onTap: controller.applyShownHint, inset: inset),
          right: _SheetButton(label: 'CLOSE', color: p.bg, textColor: p.ink2, onTap: controller.dismissNote, inset: inset),
        ),
      ]),
    );
  }
}

/// The hinted line as a row of squares: filled, dashes, gaps; the target
/// ringed in lime with its number above; and under it the deciding run pushed
/// fully one way (a bold bar) and fully the other (a lighter bar).
class _LineDiagram extends StatelessWidget {
  const _LineDiagram({required this.diagram, required this.result});

  final HintDiagram diagram;
  final CellState? result;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(builder: (context, c) {
      final n = diagram.cells.length;
      final cell = math.min(28.0, (c.maxWidth - 8) / n);
      final h = 16 + cell + (diagram.spans.isEmpty ? 4 : 22);
      return SizedBox(
        height: h,
        width: double.infinity,
        child: CustomPaint(painter: _DiagramPainter(diagram, result, cell, p)),
      );
    });
  }
}

class _DiagramPainter extends CustomPainter {
  _DiagramPainter(this.d, this.result, this.cell, this.p);

  final HintDiagram d;
  final CellState? result;
  final double cell;
  final GridwellPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 16.0;
    const x0 = 4.0;
    final inner = cell - 2;
    final sep = Paint()
      ..color = p.outline
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final ink = Paint()..color = p.ink;
    final mark = Paint()..color = p.mark;
    for (var i = 0; i < d.cells.length; i++) {
      final r = Rect.fromLTWH(x0 + i * cell, top, inner, inner);
      // Every square gets an outline, so a short line reads as squares and
      // not as scattered marks.
      canvas.drawRect(r.deflate(0.5), sep);
      final state = i == d.target ? result : d.cells[i];
      switch (state) {
        case CellState.filled:
          canvas.drawRect(r, i == d.target ? (Paint()..color = p.ink.withValues(alpha: 0.85)) : ink);
        case CellState.crossed:
          canvas.drawRect(Rect.fromCenter(center: r.center, width: inner * 0.45, height: 2), mark);
        case CellState.empty || null:
          break;
      }
    }
    final t = Rect.fromLTWH(x0 + d.target * cell, top, inner, inner);
    canvas.drawRect(
      t.inflate(1),
      Paint()
        ..color = p.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final label = TextPainter(
      text: TextSpan(text: '${d.target + 1}', style: TallyType.chip(p.accent).copyWith(fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    label.paint(canvas, Offset(t.center.dx - label.width / 2, top - 4 - label.height));
    for (var k = 0; k < d.spans.length && k < 2; k++) {
      final (a, b) = d.spans[k];
      final y = top + inner + 8 + k * 8;
      canvas.drawRect(
        Rect.fromLTRB(x0 + a * cell - 1, y, x0 + b * cell + inner + 1, y + 3),
        Paint()..color = k == 0 ? p.accent : p.accent.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_DiagramPainter old) => old.d != d || old.result != result || old.cell != cell || old.p != p;
}

/// A proven mistake: a full-width `--error` block. UNDO IT rewinds to before
/// the mark; CARRY ON leaves it to fix later.
class _MistakeSheet extends StatelessWidget {
  const _MistakeSheet({super.key, required this.note, required this.controller, required this.inset});

  final BoardNote note;
  final BoardController controller;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = note.conclusion == null ? note.body : '${note.body} ${note.conclusion}';
    return ColoredBox(
      color: p.error,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Overline('Proven mistake', color: p.onError),
              const SizedBox(height: 14),
              Text(note.headline, style: TallyType.titleM(p.onError).copyWith(fontSize: 28)),
              const SizedBox(height: 12),
              Text(text, style: TallyType.prose(p.onError, size: 14)),
            ]),
          ),
        ),
        _SheetActions(
          inset: inset,
          left: _SheetButton(
            label: 'UNDO IT',
            color: p.ink,
            textColor: p.bg,
            onTap: () => controller.undoToBeforeMark(note.row, note.col),
            inset: inset,
          ),
          right: _SheetButton(label: 'CARRY ON', color: p.surface, textColor: p.ink, onTap: controller.dismissNote, inset: inset),
        ),
      ]),
    );
  }
}
