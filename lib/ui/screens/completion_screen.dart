import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/puzzle.dart';
import '../../state/account.dart';
import '../../state/board_controller.dart';
import '../../state/completion.dart';
import '../../state/monetization.dart';
import '../../state/online.dart';
import '../../state/reminders.dart';
import '../../state/settings.dart';
import '../../state/providers.dart';
import '../../state/store_prompts.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../theme/palette.dart';
import '../widgets/tally.dart';

/// The payoff: the picture resolves edge to edge at the top, then the name,
/// the time counting up, collection progress, and finally NEXT PUZZLE.
///
/// A tap anywhere skips to the end state. Skipping never also counts as
/// "Next": that button only appears at the end and ignores taps for a moment
/// after a skip.
class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key});

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen>
    with SingleTickerProviderStateMixin {
  /// Whether the picture gave up height for a card, fixed on first build.
  bool? _heroMadeRoom;

  late final AnimationController _t;
  late final CompletionResult? _result;
  DateTime _acceptNextAfter = DateTime.now();

  @override
  void initState() {
    super.initState();
    _result = ref.read(lastCompletionProvider);
    final r = _result;
    // Full sequence for a best or a finished collection; tighter otherwise.
    final full = r != null && (r.outcome.isPersonalBest && !r.outcome.isFirstSolve || r.completedCollection || r.beatSizeBest);
    _t = AnimationController(vsync: this, duration: Duration(milliseconds: full ? 3200 : 1700))
      ..forward();
    if (r != null) {
      ref.read(interstitialPolicyProvider).recordCompletion();
      ref.read(reviewPrompterProvider).onCompletion(r);
      // Board state lives for the whole session, so a finished board would come
      // back dead on "Solve again". Drop it once the route transition is over:
      // nothing watches it then, so no empty board flashes and no new session starts.
      final container = ProviderScope.containerOf(context, listen: false);
      final id = r.puzzle.id;
      Future<void>.delayed(const Duration(milliseconds: 600), () {
        container.invalidate(boardControllerProvider(id));
        container.invalidate(savedBoardProvider(id));
      });
    }
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  void _skip() {
    if (_t.isAnimating) {
      _t.value = 1;
      _acceptNextAfter = DateTime.now().add(const Duration(milliseconds: 450));
    }
  }

  Future<void> _next(PuzzleRecord? next) async {
    if (DateTime.now().isBefore(_acceptNextAfter) || _t.isAnimating) return;
    // The only place a between-puzzle ad can ever appear.
    final policy = ref.read(interstitialPolicyProvider);
    switch (policy.decide()) {
      case BetweenPuzzleAd.offerRewardedInterstitial:
        final accepted = await showModalBottomSheet<bool>(
          context: context,
          isDismissible: false,
          enableDrag: false,
          backgroundColor: context.palette.surface,
          shape: const RoundedRectangleBorder(),
          builder: (_) => const _RewardedIntro(),
        );
        if (accepted == true) {
          final earned = await policy.playRewardedInterstitial();
          if (mounted) {
            tallyToast(
              context,
              earned
                  ? 'Thanks for watching. A bonus hint is waiting for you.'
                  : 'No bonus hint this time. On to the next one.',
            );
          }
        } else {
          policy.declinedOffer();
        }
      case BetweenPuzzleAd.interstitial:
        await policy.playInterstitial();
      case BetweenPuzzleAd.none:
        break;
    }
    if (!mounted) return;
    if (next == null) {
      context.go(_result?.dailyDate != null ? '/daily' : '/contents');
    } else {
      context.pushReplacement('/play/${next.id}');
    }
  }

  double _phase(double start, double end) =>
      Curves.easeOutCubic.transform(((_t.value - start) / (end - start)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final r = _result;
    if (r == null) {
      return const Scaffold(body: SizedBox());
    }
    final p = context.palette;
    final set = ref.watch(puzzleSetProvider);
    final puzzle = r.puzzle;
    final isDaily = r.dailyDate != null;
    final collectionName = isDaily
        ? 'The Daily'
        : set.collections.firstWhere((c) => c.id == puzzle.collectionId).name;
    final next = isDaily ? null : nextPuzzleAfter(set, ref.watch(progressProvider).value ?? const {}, puzzle);
    final pad = MediaQuery.paddingOf(context);
    final kicker = isDaily
        ? (r.dailyOnDay ? 'Solved · The Daily' : 'Solved late · The Daily')
        : 'Solved · $collectionName ${puzzle.plateNumber}';

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _skip,
        child: AnimatedBuilder(
          animation: _t,
          builder: (context, _) {
            final resolve = _phase(0.0, 0.30); // ink -> colors, row by row
            final title = _phase(0.30, 0.48);
            final time = _phase(0.42, 0.70);
            final progress = _phase(0.64, 0.86);
            final cta = _phase(0.86, 1.0);
            final shownMs = (r.timeMs * time).round();
            return LayoutBuilder(builder: (context, c) {
              // The picture runs edge to edge under the status bar; on short
              // screens it gives up height before the details do.
              final pictureHeight = c.maxWidth * puzzle.height / puzzle.width;
              // Tablets are wide, so a full-width picture would take half the
              // page and push the details below the fold.
              // A card (reminder or account offer) needs room too, so the
              // picture gives some up rather than push the card off screen.
              // Decided once: answering the card must not resize the picture.
              final card = _heroMadeRoom ??= (r.outcome.isFirstSolve && !ref.read(settingsProvider).notificationsAsked) ||
                  ref.read(showAccountOfferProvider);
              final share = c.maxWidth >= 600 ? 0.38 : (card ? 0.28 : 0.5);
              final heroHeight = (pad.top + pictureHeight).clamp(0.0, c.maxHeight * share);
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Container(
                  height: heroHeight,
                  color: p.tile,
                  padding: EdgeInsets.only(top: pad.top),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: puzzle.width / puzzle.height,
                      child: CustomPaint(painter: _HeroPainter(puzzle: puzzle, palette: p, reveal: resolve)),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 20),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Opacity(
                            opacity: title,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Overline(kicker, color: p.accent),
                              const SizedBox(height: 10),
                              Text(puzzle.name, style: TallyType.titleL(p.ink)),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          Opacity(opacity: time, child: _TimeLine(result: r, shownMs: shownMs)),
                          const SizedBox(height: 26),
                          if (isDaily)
                            Opacity(
                              opacity: progress,
                              child: Text(
                                r.dailyOnDay
                                    ? "Marked on your calendar. Your time goes on today's leaderboard when you're online."
                                    : 'Marked on your calendar. Late solves are not ranked.',
                                style: TallyType.prose(p.ink2),
                              ),
                            )
                          else
                            Opacity(
                              opacity: progress,
                              child: _CollectionProgress(
                                name: collectionName,
                                solved: r.collectionSolved,
                                total: r.collectionTotal,
                                justSolved: r.outcome.isFirstSolve,
                              ),
                            ),
                          if (isDaily && r.dailyOnDay)
                            Opacity(opacity: progress, child: _Leaderboard(date: r.dailyDate!)),
                          if (r.outcome.isFirstSolve && !ref.watch(settingsProvider).notificationsAsked)
                            IgnorePointer(ignoring: cta < 1, child: Opacity(opacity: cta, child: const _ReminderOptIn()))
                          else if (ref.watch(showAccountOfferProvider))
                            IgnorePointer(ignoring: cta < 1, child: Opacity(opacity: cta, child: const _AccountOffer())),
                        ]),
                      ),
                    ),
                  ),
                ),
                IgnorePointer(
                  ignoring: cta < 1,
                  child: Opacity(
                    opacity: 0.35 + 0.65 * cta,
                    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      SlabRow(height: 54, children: [
                        SlabButton(
                          label: 'Replay',
                          onPressed: () => context.pushReplacement('/play/${puzzle.id}'),
                        ),
                        SlabButton(
                          label: isDaily ? 'Calendar' : 'Collection',
                          onPressed: () => isDaily
                              ? context.go('/daily')
                              : context.pushReplacement('/collection/${puzzle.collectionId}'),
                        ),
                      ]),
                      PrimarySlab(
                        label: next == null ? (isDaily ? 'Back to the calendar' : 'Back to contents') : 'Next puzzle',
                        sublabel: next == null ? null : 'No. ${next.plateNumber} · ${next.width}×${next.height}',
                        onPressed: () => _next(next),
                      ),
                    ]),
                  ),
                ),
              ]);
            });
          },
        ),
      ),
    );
  }
}

/// The revealed picture, edge to edge on `--tile`. While [reveal] runs, rows
/// turn from ink to color top to bottom, 30 ms apart in the kit's timing.
class _HeroPainter extends CustomPainter {
  _HeroPainter({required this.puzzle, required this.palette, required this.reveal});

  final PuzzleRecord puzzle;
  final GridwellPalette palette;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final w = puzzle.width, h = puzzle.height;
    final cell = size.width / w < size.height / h ? size.width / w : size.height / h;
    final ox = (size.width - cell * w) / 2;
    final oy = (size.height - cell * h) / 2;
    final paint = Paint()..isAntiAlias = false;
    final colors = puzzle.colorLayer;
    for (var i = 0; i < w * h; i++) {
      if (!puzzle.solution.cells[i]) continue;
      final row = i ~/ w;
      // Each row starts a little after the one above it.
      final t = ((reveal * (h + 4) - row) / 4).clamp(0.0, 1.0);
      final index = (colors?[i] ?? 1).clamp(1, palette.art.length - 1);
      paint.color = Color.lerp(palette.ink, palette.art[index], t)!;
      canvas.drawRect(Rect.fromLTWH(ox + (i % w) * cell, oy + row * cell, cell + 0.5, cell + 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_HeroPainter old) => old.puzzle != puzzle || old.palette != palette || old.reveal != reveal;
}

/// "9:42  No hints / best 8:42", or with a new best: "8:42  NEW BEST 15×15 /
/// was 9:15 · −0:33".
class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.result, required this.shownMs});

  final CompletionResult result;
  final int shownMs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = result;
    final size = '${r.puzzle.width}×${r.puzzle.height}';
    final sizeBest = r.beatSizeBest && r.sizeBestMs != null;
    final plateBest = !r.outcome.isFirstSolve && r.outcome.isPersonalBest && r.outcome.previousBestMs != null;
    Widget? tag;
    if (sizeBest || plateBest) {
      final was = sizeBest ? r.sizeBestMs! : r.outcome.previousBestMs!;
      tag = Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Container(
          color: p.lime,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: Text(sizeBest ? 'NEW BEST $size' : 'NEW BEST', style: TallyType.overline(p.onLime).copyWith(fontSize: 12)),
        ),
        const SizedBox(height: 7),
        Text('was ${formatClock(was)} · −${formatClock(was - r.timeMs)}', style: TallyType.label(p.ink2)),
      ]);
    }
    final hints = switch (r.hintsUsed) { 0 => 'No hints', 1 => '1 hint', final n => '$n hints' };
    final best = r.sizeBestMs == null ? 'first $size' : 'best ${formatClock(r.sizeBestMs!)}';
    // Tabular while the time counts up (no jitter); proportional once it
    // settles, since Schibsted's tabular 1 leaves wide gaps ("1 : 30").
    final settled = shownMs >= r.timeMs;
    final clockStyle = settled
        ? TallyType.displayL(p.ink).copyWith(fontFeatures: const [FontFeature('tnum', 0)])
        : TallyType.displayL(p.ink);
    return BigStat(
      value: clockSpan(formatClock(shownMs), clockStyle),
      style: clockStyle,
      gap: 16,
      label: '$hints\n$best',
      labelColor: p.ink,
      trailing: tag,
    );
  }
}

/// "Coastline  15/30" over a full-width row of ticks; the plate just solved
/// is the lime one.
class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress({required this.name, required this.solved, required this.total, required this.justSolved});

  final String name;
  final int solved;
  final int total;
  final bool justSolved;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final before = justSolved ? solved - 1 : solved;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.bodyS(p.ink))),
        Text.rich(TextSpan(children: [
          TextSpan(text: '$solved', style: TallyType.bodyS(p.accent)),
          TextSpan(text: '/$total', style: TallyType.bodyS(p.ink)),
        ])),
      ]),
      const SizedBox(height: 10),
      _Ticks(total: total, done: before, current: justSolved ? before : null),
    ]);
  }
}

/// Full-width flexible ticks, 12 pt tall, 2 pt apart: done in `--ink`, the
/// plate just solved taller, in lime with an `--accent` ring, the rest
/// `--track`.
class _Ticks extends StatelessWidget {
  const _Ticks({required this.total, required this.done, this.current});

  final int total;
  final int done;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: 16,
      child: Row(children: [
        for (var i = 0; i < total; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: Center(
              child: i == current
                  ? Container(
                      height: 16,
                      decoration: BoxDecoration(color: p.lime, border: Border.all(color: p.accent, width: 2)),
                    )
                  : Container(height: 12, color: i < done ? p.ink : p.track),
            ),
          ),
        ],
      ]),
    );
  }
}

/// A Tally card for the one-off offers under the details: `--surface`, an
/// accent overline, a line of prose and two slabs.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.kicker,
    required this.body,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
  });

  final String kicker;
  final String body;
  final String primary;
  final VoidCallback onPrimary;
  final String secondary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: ColoredBox(
        color: p.surface,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Overline(kicker, color: p.accent),
              const SizedBox(height: 8),
              Text(body, style: TallyType.prose(p.ink)),
            ]),
          ),
          SlabRow(height: 50, children: [
            SlabButton(label: primary, onPressed: onPrimary, color: p.lime, textColor: p.onLime),
            SlabButton(label: secondary, onPressed: onSecondary, color: p.track),
          ]),
        ]),
      ),
    );
  }
}

/// After the first solve: offer the 7 PM reminder. The OS permission prompt
/// only appears if the player says yes here.
class _ReminderOptIn extends ConsumerWidget {
  const _ReminderOptIn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduler = ref.read(reminderSchedulerProvider);
    return _OfferCard(
      kicker: 'A quiet reminder?',
      body: "A single note at 7 in the evening when the day's puzzle is still open. Nothing else.",
      primary: 'Remind me',
      onPrimary: () async {
        final granted = await scheduler.optIn();
        if (!context.mounted) return;
        tallyToast(
          context,
          granted
              ? "Reminder set. A note at 7 pm when the day's puzzle is still open."
              : 'Notifications are off, so no reminder. You can turn it on in Settings.',
        );
      },
      secondary: 'No thanks',
      onSecondary: () async {
        await scheduler.decline();
        if (context.mounted) tallyToast(context, 'No reminder. You can turn it on in Settings any time.');
      },
    );
  }
}

/// Once a few plates are solved, a guest is offered (once) to keep their
/// progress with an account. Never on first launch, never again after an
/// answer; Settings > Account is always there.
class _AccountOffer extends ConsumerWidget {
  const _AccountOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) => _OfferCard(
        kicker: 'Keep your progress?',
        body: 'Sign in to keep your solved puzzles and best times if you change phones. '
            'Or carry on as you are; you can always do it later in Settings.',
        primary: 'Sign in',
        onPrimary: () => context.push('/account'),
        secondary: 'Not now',
        onSecondary: () => ref.read(accountOfferProvider.notifier).done(),
      );
}

/// Today's leaderboard on a daily's completion page (online only).
class _Leaderboard extends ConsumerWidget {
  const _Leaderboard({required this.date});

  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final board = ref.watch(dailyLeaderboardProvider(date)).value;
    if (board == null || board.entries.isEmpty) return const SizedBox();
    Widget line(LeaderboardEntry e) => Container(
          color: e.isYou ? p.hl : p.surface,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(children: [
            SizedBox(width: 34, child: Text('${e.rank}', style: TallyType.bodyS(p.ink2))),
            Expanded(child: Text(e.penName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.body(p.ink))),
            Text.rich(clockSpan(formatClock(e.timeMs), TallyType.bodyS(e.isYou ? p.accent : p.ink))),
          ]),
        );
    final rows = [
      for (final e in board.entries) line(e),
      if (board.you != null && !board.entries.any((e) => e.isYou)) line(board.you!),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Overline("Today's quickest", color: p.accent)),
          Text(board.total == 1 ? '1 solver' : '${board.total} solvers', style: TallyType.label(p.ink2)),
        ]),
        const SizedBox(height: 10),
        ColoredBox(
          color: p.sunk,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: tallyDivider),
              rows[i],
            ],
          ]),
        ),
      ]),
    );
  }
}

/// Google requires an intro before a rewarded interstitial: clear reward
/// messaging, an unobstructed way to skip, and time to decide. The ad starts
/// when the countdown ends or on "Watch now"; "No thanks" skips it entirely.
class _RewardedIntro extends StatefulWidget {
  const _RewardedIntro();

  @override
  State<_RewardedIntro> createState() => _RewardedIntroState();
}

class _RewardedIntroState extends State<_RewardedIntro> {
  static const _seconds = 5;
  int _left = _seconds;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && !_closed && _left > 0) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _closed) return;
      setState(() => _left--);
    }
    if (mounted && !_closed) _close(true);
  }

  void _close(bool watch) {
    if (_closed) return;
    _closed = true;
    Navigator.of(context).pop(watch);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inset = MediaQuery.paddingOf(context).bottom;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(height: 4, color: p.lime),
      Padding(
        padding: const EdgeInsets.fromLTRB(tallyMargin, 20, tallyMargin, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Overline('A bonus hint', color: p.accent)),
            Text('Starting in $_left s', style: TallyType.label(p.ink2)),
          ]),
          const SizedBox(height: 12),
          Text('Watch a short ad and your next puzzle starts with a bonus hint, kept until you need it.',
              style: TallyType.bodyL(p.ink).copyWith(height: 1.3)),
          const SizedBox(height: 8),
          Text('Skip it and carry straight on. Nothing is lost.', style: TallyType.prose(p.ink2)),
        ]),
      ),
      SizedBox(
        height: 62 + inset,
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Pressable(
              color: p.lime,
              onTap: () => _close(true),
              semanticLabel: 'Watch now',
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 12, inset * 0.7),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('WATCH NOW', style: TallyType.slab(p.onLime).copyWith(fontSize: 20))),
                ),
              ),
            ),
          ),
          Expanded(
            child: Pressable(
              color: p.bg,
              onTap: () => _close(false),
              semanticLabel: 'No thanks',
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 12, inset * 0.7),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text('NO THANKS', style: TallyType.slab(p.ink2).copyWith(fontSize: 20))),
                ),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }
}
