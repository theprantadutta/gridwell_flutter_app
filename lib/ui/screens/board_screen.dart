import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/board_controller.dart';
import '../../state/providers.dart';
import '../../state/services.dart';
import '../../state/settings.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = ref.read(boardControllerProvider(widget.puzzleId).notifier);
    _controller.resume();
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
        _controller.resume();
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
      if (_navigated || result == null || result.puzzle.id != widget.puzzleId) return;
      _navigated = true;
      final router = GoRouter.of(context);
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) router.pushReplacement('/complete');
      });
    });

    final big = puzzle.width >= 15;
    final note = session.note;
    return Column(children: [
      FolioHeader(
        leading: 'Contents',
        onLeading: () => context.pop(),
        center: headerTitle,
        trailing: settings.showTimer
            ? Text(formatClock(_controller.elapsedMs), style: FolioType.header(p))
            : null,
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 18, folioMargin, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(isDaily ? "TODAY'S LEAF" : 'NO. ${puzzle.plateNumber}', style: FolioType.kicker(p)),
            const Spacer(),
            Text('${puzzle.width} × ${puzzle.height}', style: FolioType.header(p).copyWith(fontStyle: FontStyle.normal)),
          ]),
          const SizedBox(height: 4),
          Text(puzzle.name, style: FolioType.plateTitle(p, size: big ? 36 : 40)),
        ]),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: big ? 8 : folioMargin),
          child: BoardView(
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
          ),
        ),
      ),
      if (big && note == null && session.cursorRow != null) _LineReadout(session: session),
      if (note != null) _NoteSheet(note: note, session: session, controller: _controller)
      else _Footer(session: session, controller: _controller, onHint: _hint),
    ]);
  }
}

/// "ROW 12  4  |  COLUMN 9  4 2̶ 1 2̶" under big boards, so the active clues
/// can be read at a comfortable size.
class _LineReadout extends StatelessWidget {
  const _LineReadout({required this.session});

  final BoardSession session;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = session.cursorRow!, c = session.cursorCol!;
    Widget clue(String label, List<int> numbers, Set<int> retired) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: FolioType.kicker(p)),
            const SizedBox(height: 6),
            Wrap(spacing: 10, children: [
              for (var j = 0; j < numbers.length; j++)
                Text(
                  '${numbers[j]}',
                  style: FolioType.style(
                    size: 28,
                    weight: 600,
                    color: retired.contains(j) ? p.clueRetired : p.clueText,
                  ).copyWith(
                    decoration: retired.contains(j) ? TextDecoration.lineThrough : null,
                    decorationColor: p.clueRetired,
                  ),
                ),
            ]),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(folioMargin, 10, folioMargin, 0),
      child: Column(children: [
        const Hairline(),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            clue('ROW ${r + 1}', session.puzzle.clues.rows[r], session.rowRetired[r]),
            VerticalDivider(color: p.rule, width: 32, thickness: 1),
            clue('COLUMN ${c + 1}', session.puzzle.clues.columns[c], session.colRetired[c]),
          ]),
        ),
      ]),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({required this.session, required this.controller, required this.onHint});

  final BoardSession session;
  final BoardController controller;
  final VoidCallback onHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final premium = ref.watch(entitlementsProvider).premium;
    final hintsLeft = premium ? null : session.freeHintsLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(folioMargin, 12, folioMargin, 18),
      child: Column(children: [
        const Hairline(),
        const SizedBox(height: 18),
        Row(children: [
          TextAction(label: 'Undo', enabled: session.canUndo, onPressed: controller.undo),
          const Spacer(),
          Segmented<InputMode>(
            value: session.mode,
            onChanged: controller.setMode,
            options: [
              (InputMode.fill, 'Fill', (c) => Container(width: 16, height: 16, color: c)),
              (InputMode.cross, 'Cross', (c) => Icon(Icons.close, size: 22, color: c)),
            ],
          ),
          const Spacer(),
          TextAction(
            label: 'Hint',
            onPressed: onHint,
            trailing: Text(
              hintsLeft == null ? '' : (hintsLeft > 0 ? '$hintsLeft' : '▶'),
              style: FolioType.style(size: 16, color: p.accent),
            ),
          ),
        ]),
      ]),
    );
  }
}

/// The footnote sheet for a hint or a proven mistake.
class _NoteSheet extends ConsumerWidget {
  const _NoteSheet({required this.note, required this.session, required this.controller});

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
        border: Border(top: BorderSide(color: isHint ? p.textPrimary : p.accent, width: 1.2)),
      ),
      padding: const EdgeInsets.fromLTRB(folioMargin, 20, folioMargin, 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(isHint ? 'HINT · ${note.title}' : 'A PROVEN MISTAKE · ${note.title}',
              style: FolioType.kicker(p)),
          const Spacer(),
          if (isHint && !premium)
            Text(
              session.freeHintsLeft == 1 ? '1 hint left' : '${session.freeHintsLeft} hints left',
              style: FolioType.header(p).copyWith(fontSize: 15),
            ),
        ]),
        const SizedBox(height: 10),
        Text(note.body, style: FolioType.body(p, size: 19)),
        if (note.conclusion != null) ...[
          const SizedBox(height: 10),
          Text(note.conclusion!, style: FolioType.bodyMuted(p)),
        ],
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: InkButton(
              label: isHint ? 'Got it' : 'Clear the square',
              height: 54,
              onPressed: isHint ? controller.dismissNote : () => controller.clearSquare(note.row, note.col),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlineButtonFolio(
              label: isHint ? 'Undo hint' : 'Undo to here',
              onPressed: isHint ? controller.undoHint : () => controller.undoToBeforeMark(note.row, note.col),
            ),
          ),
        ]),
      ]),
    );
  }
}
