import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/clues.dart';
import '../../state/board_controller.dart';
import '../../state/monetization.dart' show bonusHintsProvider;
import '../../state/providers.dart';
import '../../state/services.dart';
import '../../state/settings.dart';
import '../board/board_geometry.dart';
import '../board/board_tour.dart';
import '../board/board_view.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';

/// Loads the saved board, then shows [_BoardPage].
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedBoardProvider(puzzleId));
    return Scaffold(
      body: SafeArea(
        child: saved.isLoading
            ? const SizedBox()
            : _BoardPage(puzzleId: puzzleId),
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

class _BoardPageState extends ConsumerState<_BoardPage>
    with WidgetsBindingObserver {
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
    if (outcome == HintOutcome.nothingToHint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing left to hint here.')),
      );
    }
  }

  void _endTour() {
    setState(() => _touring = false);
    _controller.resume();
    unawaited(
      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(boardTourDone: true)),
    );
  }

  Rect _rectOf(GlobalKey key, RenderBox overlay) {
    final box = key.currentContext!.findRenderObject()! as RenderBox;
    return box.localToGlobal(Offset.zero, ancestor: overlay) & box.size;
  }

  /// The grid and clue strips, found the way [BoardView] lays them out.
  (Rect grid, List<Rect> clues) _boardParts(RenderBox overlay) {
    final view = _rectOf(_boardKey, overlay);
    final g = BoardGeometry.fit(
      ref.read(boardControllerProvider(widget.puzzleId)).puzzle.clues,
      view.size,
    );
    final origin =
        view.topLeft +
        Offset(
          (view.width - g.totalSize.width) / 2,
          (view.height - g.totalSize.height) / 2,
        );
    final grid = g.gridRect.shift(origin);
    return (
      grid,
      [
        Rect.fromLTRB(grid.left, origin.dy, grid.right, grid.top),
        Rect.fromLTRB(origin.dx, grid.top, grid.left, grid.bottom),
      ],
    );
  }

  List<TourStep> _tourSteps(bool showTimer) => [
    TourStep(
      title: 'The clues',
      body:
          'Each number is a run of filled squares, in order. Numbers on top read down their '
          'column, and numbers at the side read across their row.',
      targets: (o) => _boardParts(o).$2,
    ),
    TourStep(
      title: 'The grid',
      body:
          'Tap a square to mark it, or drag across several at once. '
          'On the biggest boards, pinch to zoom in.',
      targets: (o) => [_boardParts(o).$1],
    ),
    TourStep(
      title: 'Fill or Cross',
      body:
          'Fill marks a square as part of the picture. Cross marks one you know is empty. '
          'Crosses are only notes to yourself.',
      targets: (o) => [_rectOf(_modeKey, o)],
    ),
    TourStep(
      title: 'Row and column',
      body:
          'The clues for the square you touched appear here, large enough to read. '
          'Finished clues are struck through.',
      targets: (o) => [_rectOf(_readoutKey, o)],
    ),
    TourStep(
      title: 'Undo',
      body: 'Takes back your last move. Use it as often as you like.',
      targets: (o) => [_rectOf(_undoKey, o)],
    ),
    TourStep(
      title: 'Hint',
      body:
          'Stuck? A hint marks the next square logic can prove and explains why. '
          'The number beside it shows how many you have left.',
      targets: (o) => [_rectOf(_hintKey, o)],
    ),
    if (showTimer)
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
    final headerTitle = isDaily
        ? 'The Daily'
        : set.collections.firstWhere((c) => c.id == puzzle.collectionId).name;

    // Turn the page once the solve is recorded (not merely detected).
    ref.listen(lastCompletionProvider, (_, result) {
      if (_navigated || result == null || result.puzzle.id != widget.puzzleId) {
        return;
      }
      _navigated = true;
      final router = GoRouter.of(context);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) router.pushReplacement('/complete');
      });
    });

    final big = puzzle.width >= 15;
    // The walkthrough points at the controls, so an open note waits behind it.
    final note = _touring ? null : session.note;
    final header = FolioHeader(
      leading: isDaily ? 'Daily' : 'Contents',
      onLeading: () => context.pop(),
      center: headerTitle,
      trailing: settings.showTimer
          ? Text(
              key: _timerKey,
              formatClock(_controller.elapsedMs),
              style: FolioType.header(p),
            )
          : null,
    );
    final title = Padding(
      padding: const EdgeInsets.fromLTRB(folioMargin, 18, folioMargin, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                isDaily ? "TODAY'S LEAF" : 'NO. ${puzzle.plateNumber}',
                style: FolioType.kicker(p),
              ),
              const Spacer(),
              Text(
                '${puzzle.width} × ${puzzle.height}',
                style: FolioType.header(p)
                    .copyWith(fontStyle: FontStyle.normal),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            puzzle.name,
            style: FolioType.plateTitle(p, size: big ? 36 : 40),
          ),
        ],
      ),
    );
    final board = BoardView(
      key: _boardKey,
      clues: puzzle.clues,
      board: session.board,
      rowRetired: session.rowRetired,
      colRetired: session.colRetired,
      mistakes: settings.showProvenMistakes ? session.mistakeCells : const {},
      cursorRow: session.cursorRow,
      cursorCol: session.cursorCol,
      flashCell: note == null ? null : (note.row, note.col),
      enabled: !session.solved,
      onStrokeStart: _controller.strokeStart,
      onStrokeMove: _controller.strokeMove,
      onStrokeEnd: _controller.strokeEnd,
      onStrokeCancel: _controller.strokeCancel,
    );
    // The dock never changes size, and the controls at its foot never move.
    // Only the slot above them changes: the clue readout, or a hint or
    // mistake note in exactly the same space.
    final dock = Column(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: note != null
                ? _NoteSheet(
                    key: const ValueKey('note'),
                    note: note,
                    session: session,
                    controller: _controller,
                  )
                : _LineReadout(key: _readoutKey, session: session),
          ),
        ),
        _Footer(
          session: session,
          controller: _controller,
          onHint: _hint,
          undoKey: _undoKey,
          modeKey: _modeKey,
          hintKey: _hintKey,
        ),
      ],
    );

    final page = LayoutBuilder(
      builder: (context, c) {
        // Tablets in landscape: board on the left, everything else beside it.
        final sideBySide = c.maxWidth >= 840 && c.maxWidth > c.maxHeight * 1.15;
        if (sideBySide) {
          return Column(
            children: [
              header,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: board,
                      ),
                    ),
                    SizedBox(
                      width: 400,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          title,
                          const SizedBox(height: 12),
                          Expanded(child: dock),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final dockHeight = (c.maxHeight * 0.36).clamp(
          230 * textScale,
          300 * textScale,
        );
        return Column(
          children: [
            header,
            title,
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: big ? 8 : folioMargin,
                ),
                child: board,
              ),
            ),
            SizedBox(height: dockHeight, child: dock),
          ],
        );
      },
    );

    if (!_touring) return page;
    return Stack(
      children: [
        page,
        Positioned.fill(
          child: BoardTour(
            steps: _tourSteps(settings.showTimer),
            onDone: _endTour,
          ),
        ),
      ],
    );
  }
}

/// "ROW 12  4  |  COLUMN 9  4 2̶ 1 2̶" under the board, so the active clues can
/// be read at a comfortable size. Before the first tap it says how to play.
///
/// Every line of clues is set at one size for the whole puzzle, chosen so the
/// longest fits, inside a block of fixed height. Moving between rows changes
/// the numbers and nothing else: no rescaling, no re-centering.
class _LineReadout extends StatelessWidget {
  const _LineReadout({super.key, required this.session});

  final BoardSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final scaler = MediaQuery.textScalerOf(context);
    final r = session.cursorRow, c = session.cursorCol;
    final clues = session.puzzle.clues;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: folioMargin),
      child: Column(
        children: [
          const Hairline(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final size = _clueSize(clues, (box.maxWidth - 33) / 2, scaler);
                final numbers = FolioType.style(size: size, weight: 600, color: p.clueText);
                final kicker = FolioType.kicker(p);
                final kickerHeight = _height('ROW', kicker, scaler);
                final numbersHeight = _height('0', numbers, scaler);
                final blockHeight = kickerHeight + 6 + numbersHeight;

                Widget line(String label, List<int> values, Set<int> retired) =>
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, maxLines: 1, style: kicker),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: numbersHeight,
                            child: Row(
                              children: [
                                for (var j = 0; j < values.length; j++) ...[
                                  if (j > 0) SizedBox(width: size * 0.36),
                                  Text(
                                    '${values[j]}',
                                    maxLines: 1,
                                    style: numbers.copyWith(
                                      color: retired.contains(j)
                                          ? p.clueRetired
                                          : p.clueText,
                                      decoration: retired.contains(j)
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: p.clueRetired,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );

                return Center(
                  child: SizedBox(
                    height: blockHeight,
                    width: box.maxWidth,
                    child: r == null || c == null
                        ? FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: box.maxWidth,
                              child: Text(
                                'Tap or drag across the squares. The clues say how many are filled, and in what runs.',
                                style: FolioType.bodyMuted(p, size: 16),
                              ),
                            ),
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              line(
                                'ROW ${r + 1}',
                                clues.rows[r],
                                session.rowRetired[r],
                              ),
                              VerticalDivider(
                                color: p.rule,
                                width: 33,
                                thickness: 1,
                              ),
                              line(
                                'COLUMN ${c + 1}',
                                clues.columns[c],
                                session.colRetired[c],
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static double _height(String text, TextStyle style, TextScaler scaler) =>
      (TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout()).height;

  /// The largest size, up to 28, at which every row and column clue fits on
  /// one line in [width].
  static double _clueSize(Clues clues, double width, TextScaler scaler) {
    const base = 28.0;
    final style = FolioType.style(size: base, weight: 600, color: const Color(0xFF000000));
    var widest = 0.0;
    for (final line in [...clues.rows, ...clues.columns]) {
      final digits = TextPainter(
        text: TextSpan(text: line.join(), style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, digits.width + base * 0.36 * (line.length - 1));
    }
    if (widest <= width) return base;
    return math.max(10, (base * width / widest).floorToDouble());
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.session,
    required this.controller,
    required this.onHint,
    required this.undoKey,
    required this.modeKey,
    required this.hintKey,
  });

  final BoardSession session;
  final BoardController controller;
  final VoidCallback onHint;
  final Key undoKey;
  final Key modeKey;
  final Key hintKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final premium = ref.watch(entitlementsProvider).premium;
    final bonus = ref.watch(bonusHintsProvider);
    final hintsLeft = premium ? null : session.freeHintsLeft + bonus;
    return Padding(
      padding: const EdgeInsets.fromLTRB(folioMargin, 0, folioMargin, 18),
      child: Column(
        children: [
          const Hairline(),
          const SizedBox(height: 18),
          Row(
            children: [
              TextAction(
                key: undoKey,
                label: 'Undo',
                enabled: session.canUndo,
                onPressed: controller.undo,
              ),
              // The toggle takes the space between Undo and Hint and scales down
              // on narrow phones or large system font sizes instead of overflowing.
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Segmented<InputMode>(
                      key: modeKey,
                      value: session.mode,
                      onChanged: controller.setMode,
                      options: [
                        (
                          InputMode.fill,
                          'Fill',
                          (c) => Container(width: 16, height: 16, color: c),
                        ),
                        (
                          InputMode.cross,
                          'Cross',
                          (c) => Icon(Icons.close, size: 22, color: c),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              TextAction(
                key: hintKey,
                label: 'Hint',
                onPressed: onHint,
                // Fixed width, so the count changing never nudges the controls.
                trailing: SizedBox(
                  width: 18,
                  child: Text(
                    hintsLeft == null
                        ? ''
                        : (hintsLeft > 0 ? '$hintsLeft' : '▶'),
                    maxLines: 1,
                    style: FolioType.style(size: 16, color: p.accent),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A hint or proven mistake, in the readout's place above the controls. It
/// fills that slot exactly; a long explanation scrolls inside it.
class _NoteSheet extends ConsumerWidget {
  const _NoteSheet({
    super.key,
    required this.note,
    required this.session,
    required this.controller,
  });

  final BoardNote note;
  final BoardSession session;
  final BoardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isHint = note.kind == BoardNoteKind.hint;
    final premium = ref.watch(entitlementsProvider).premium;
    return Container(
      decoration: BoxDecoration(
        color: p.surfaceRaised,
        border: Border(
          top: BorderSide(color: isHint ? p.textPrimary : p.accent, width: 1.2),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(folioMargin, 12, folioMargin, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isHint
                      ? 'HINT · ${note.title}'
                      : 'A PROVEN MISTAKE · ${note.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: FolioType.kicker(p),
                ),
              ),
              if (isHint && !premium)
                Text(
                  session.freeHintsLeft == 1
                      ? '1 hint left'
                      : '${session.freeHintsLeft} hints left',
                  style: FolioType.header(p).copyWith(fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.body, style: FolioType.body(p, size: 17)),
                  if (note.conclusion != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      note.conclusion!,
                      style: FolioType.bodyMuted(p, size: 15),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkButton(
                  label: isHint ? 'Got it' : 'Clear the square',
                  height: 42,
                  onPressed: isHint
                      ? controller.dismissNote
                      : () => controller.clearSquare(note.row, note.col),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlineButtonFolio(
                  label: isHint ? 'Undo hint' : 'Undo to here',
                  height: 42,
                  onPressed: isHint
                      ? controller.undoHint
                      : () => controller.undoToBeforeMark(note.row, note.col),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
