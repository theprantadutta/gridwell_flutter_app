import 'dart:math' as math;

import 'package:flutter/material.dart';
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
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

/// The payoff: the picture resolves, presents itself as a plate in a book,
/// then the name, the time, collection progress, and finally "Next puzzle".
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
          backgroundColor: context.palette.surfaceRaised,
          shape: const RoundedRectangleBorder(),
          builder: (_) => const _RewardedIntro(),
        );
        if (accepted == true) {
          final earned = await policy.playRewardedInterstitial();
          if (earned && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('A bonus hint is waiting for you.')),
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
    final pb = !r.outcome.isFirstSolve && r.outcome.isPersonalBest;

    return Scaffold(
      body: FolioBody(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _skip,
          child: AnimatedBuilder(
            animation: _t,
            builder: (context, _) {
              final resolve = _phase(0.0, 0.28); // ink -> colors
              final present = _phase(0.12, 0.40); // scale up
              final title = _phase(0.34, 0.52);
              final time = _phase(0.46, 0.72);
              final progress = _phase(0.66, 0.86);
              final cta = _phase(0.88, 1.0);
              final shownMs = (r.timeMs * time).round();
              return Column(children: [
                FolioHeader(
                  leading: isDaily ? 'Daily' : 'Contents',
                  onLeading: () => context.go(isDaily ? '/daily' : '/contents'),
                  center: collectionName,
                  trailing: isDaily
                      ? Text(_shortDate(r.dailyDate!), style: FolioType.header(p))
                      : Text('Plate ${puzzle.plateNumber} of ${r.collectionTotal}', style: FolioType.header(p)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: folioMargin),
                    child: Column(children: [
                      const SizedBox(height: 28),
                      Transform.scale(
                        scale: 0.86 + 0.14 * present,
                        child: Stack(clipBehavior: Clip.none, children: [
                          Container(
                            decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
                            padding: const EdgeInsets.all(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: p.surfaceRaised,
                                border: Border.all(color: p.ruleStrong),
                              ),
                              padding: const EdgeInsets.all(28),
                              child: AspectRatio(
                                aspectRatio: puzzle.width / puzzle.height,
                                child: CustomPaint(
                                  painter: PicturePainter(puzzle: puzzle, palette: p, reveal: resolve),
                                ),
                              ),
                            ),
                          ),
                          if (pb || (r.outcome.isFirstSolve && r.beatSizeBest && r.sizeBestMs != null))
                            Positioned(
                              right: -14,
                              top: -24,
                              child: Opacity(
                                opacity: time,
                                child: Transform.rotate(angle: -0.18 * time, child: _BestStamp(puzzle: puzzle)),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(height: 28),
                      Opacity(
                        opacity: title,
                        child: Column(children: [
                          Text(isDaily ? (r.dailyOnDay ? "TODAY'S LEAF" : 'A MISSED LEAF') : 'PLATE ${roman(puzzle.plateNumber)}',
                              style: FolioType.kicker(p)),
                          const SizedBox(height: 8),
                          Text(puzzle.name, style: FolioType.plateTitle(p, size: 48), textAlign: TextAlign.center),
                        ]),
                      ),
                      const SizedBox(height: 12),
                      Opacity(opacity: time, child: _TimeLine(result: r, shownMs: shownMs, personalBest: pb)),
                      const SizedBox(height: 22),
                      const Hairline(),
                      const SizedBox(height: 16),
                      if (isDaily)
                        Opacity(
                          opacity: progress,
                          child: Text(
                            r.dailyOnDay
                                ? "Pressed into your calendar. Your time goes on today's leaderboard when you are online."
                                : 'Pressed into your calendar. Late leaves are not ranked.',
                            textAlign: TextAlign.center,
                            style: FolioType.bodyMuted(p, size: 17),
                          ),
                        )
                      else
                        _CollectionProgress(
                          name: collectionName,
                          solved: r.collectionSolved,
                          total: r.collectionTotal,
                          advanced: progress,
                          justSolved: r.outcome.isFirstSolve,
                        ),
                      if (isDaily && r.dailyOnDay)
                        Opacity(opacity: progress, child: _Leaderboard(date: r.dailyDate!)),
                      if (r.outcome.isFirstSolve && !ref.watch(settingsProvider).notificationsAsked)
                        Opacity(opacity: cta, child: const _ReminderOptIn())
                      else if (ref.watch(showAccountOfferProvider))
                        IgnorePointer(ignoring: cta < 1, child: Opacity(opacity: cta, child: const _AccountOffer())),
                      const SizedBox(height: 28),
                      IgnorePointer(
                        ignoring: cta < 1,
                        child: Opacity(
                          opacity: cta,
                          child: Column(children: [
                            InkButton(
                              label: next == null ? (isDaily ? 'Back to the calendar' : 'Back to contents') : 'Next puzzle',
                              detail: next == null ? null : 'No. ${next.plateNumber} · ${next.width} × ${next.height}',
                              onPressed: () => _next(next),
                            ),
                            const SizedBox(height: 6),
                            Wrap(alignment: WrapAlignment.center, spacing: 40, children: [
                              TextAction(
                                label: 'Solve again',
                                onPressed: () => context.pushReplacement('/play/${puzzle.id}'),
                              ),
                              TextAction(label: 'Return to contents', onPressed: () => context.go('/contents')),
                            ]),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// "2026-11-04" as "4 November".
String _shortDate(String date) {
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
    'October', 'November', 'December'];
  final d = DateTime.tryParse(date);
  return d == null ? date : '${d.day} ${months[d.month - 1]}';
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.result, required this.shownMs, required this.personalBest});

  final CompletionResult result;
  final int shownMs;
  final bool personalBest;

  String _spoken(int ms) {
    final s = ms ~/ 1000;
    return s < 60 ? '$s s' : '${s ~/ 60} min ${s % 60} s';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = result;
    final size = '${r.puzzle.width} × ${r.puzzle.height}';
    if (personalBest && r.outcome.previousBestMs != null) {
      final gained = (r.outcome.previousBestMs! - r.timeMs) ~/ 1000;
      return Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Text(formatClock(shownMs), style: FolioType.style(size: 52, color: p.textPrimary, weight: 500)),
          const SizedBox(width: 24),
          Text('previously ', style: FolioType.bodyMuted(p, size: 18)),
          Text(formatClock(r.outcome.previousBestMs!),
              style: FolioType.bodyMuted(p, size: 18).copyWith(
                  decoration: TextDecoration.lineThrough, decorationColor: p.accent, decorationThickness: 2)),
        ]),
        Text('Your quickest on this plate, by ${gained < 1 ? 'a whisker' : '$gained seconds'}.',
            style: FolioType.bodyMuted(p, size: 18), textAlign: TextAlign.center),
      ]);
    }
    final sizeBest = r.sizeBestMs;
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'Solved in ${_spoken(shownMs)}. ', style: FolioType.body(p, size: 19)),
        if (sizeBest != null)
          TextSpan(
            text: r.beatSizeBest
                ? 'Your quickest $size yet.'
                : 'Your best for $size stands at ${formatClock(sizeBest)}.',
            style: FolioType.bodyMuted(p, size: 19),
          ),
        if (r.hintsUsed > 0)
          TextSpan(text: ' ${r.hintsUsed == 1 ? 'One hint' : '${r.hintsUsed} hints'}.', style: FolioType.bodyMuted(p, size: 19)),
      ]),
      textAlign: TextAlign.center,
    );
  }
}

class _CollectionProgress extends StatelessWidget {
  const _CollectionProgress({
    required this.name,
    required this.solved,
    required this.total,
    required this.advanced,
    required this.justSolved,
  });

  final String name;
  final int solved;
  final int total;
  final double advanced;
  final bool justSolved;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final before = justSolved ? solved - 1 : solved;
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text('$name now holds', style: FolioType.bodyMuted(p, size: 17))),
        const SizedBox(width: 12),
        Text(solved == total ? 'all $total plates' : '$solved of $total plates', style: FolioType.body(p)),
      ]),
      const SizedBox(height: 10),
      LayoutBuilder(builder: (context, c) {
        final gap = 3.0;
        final box = math.min(14.0, (c.maxWidth - gap * (total - 1)) / total);
        return Row(children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) SizedBox(width: gap),
            Container(
              width: box,
              height: box,
              decoration: BoxDecoration(
                color: i < before
                    ? p.textPrimary
                    : (i == before && justSolved ? Color.lerp(p.surfaceRaised, p.accent, advanced) : p.surfaceRaised),
                border: Border.all(color: i < before ? p.textPrimary : p.ruleStrong, width: 1),
              ),
            ),
          ],
        ]);
      }),
    ]);
  }
}

class _BestStamp extends StatelessWidget {
  const _BestStamp({required this.puzzle});

  final PuzzleRecord puzzle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: p.surface,
        border: Border.all(color: p.accent, width: 1.5),
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.accent, width: 1)),
        alignment: Alignment.center,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('NEW', style: FolioType.kicker(p).copyWith(fontSize: 10)),
          Text('Best', style: FolioType.style(size: 26, color: p.accent, weight: 600, italic: true)),
          Text('${puzzle.width} × ${puzzle.height}', style: FolioType.kicker(p).copyWith(fontSize: 10, letterSpacing: 2)),
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
    final p = context.palette;
    final scheduler = ref.read(reminderSchedulerProvider);
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: p.ruleStrong)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('A QUIET REMINDER?', style: FolioType.kicker(p)),
        const SizedBox(height: 8),
        Text("A single note at 7 in the evening when the day's puzzle is still open. Nothing else.",
            style: FolioType.body(p, size: 17)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: InkButton(label: 'Remind me', height: 48, onPressed: scheduler.optIn)),
          const SizedBox(width: 12),
          Expanded(child: OutlineButtonFolio(label: 'No thanks', height: 48, onPressed: scheduler.decline)),
        ]),
      ]),
    );
  }
}

/// Once a few plates are solved, a guest is offered (once) to keep their
/// progress with an account. Never on first launch, never again after an
/// answer; Settings > Account is always there.
class _AccountOffer extends ConsumerWidget {
  const _AccountOffer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(top: 22),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(border: Border.all(color: p.ruleStrong)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('KEEP YOUR PROGRESS?', style: FolioType.kicker(p)),
        const SizedBox(height: 8),
        Text(
          'Sign in to keep your solved plates and best times if you change phones. '
          'Or carry on as you are; you can always do it later in Settings.',
          style: FolioType.body(p, size: 17),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: InkButton(label: 'Sign in', height: 48, onPressed: () => context.push('/account'))),
          const SizedBox(width: 12),
          Expanded(
            child: OutlineButtonFolio(
              label: 'Not now',
              height: 48,
              onPressed: () => ref.read(accountOfferProvider.notifier).done(),
            ),
          ),
        ]),
      ]),
    );
  }
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
    Widget line(LeaderboardEntry e) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            SizedBox(width: 36, child: Text('${e.rank}', style: FolioType.style(size: 16, color: p.textMuted))),
            Expanded(
              child: Text(e.penName,
                  style: FolioType.style(size: 17, color: p.textPrimary, weight: e.isYou ? 600 : 400)),
            ),
            Text(formatClock(e.timeMs), style: FolioType.style(size: 17, color: e.isYou ? p.accent : p.textPrimary)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text("TODAY'S QUICKEST", style: FolioType.kicker(p)),
          const Spacer(),
          Text(board.total == 1 ? '1 solver' : '${board.total} solvers', style: FolioType.header(p)),
        ]),
        const SizedBox(height: 8),
        for (final e in board.entries) line(e),
        if (board.you != null && !board.entries.any((e) => e.isYou)) ...[
          const Hairline(),
          line(board.you!),
        ],
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 22, folioMargin, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('A BONUS HINT', style: FolioType.kicker(p)),
            const Spacer(),
            Text('Starting in $_left s', style: FolioType.header(p).copyWith(fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          Text('Watch a short ad and your next puzzle starts with a bonus hint, kept until you need it.',
              style: FolioType.body(p, size: 19)),
          const SizedBox(height: 8),
          Text('Skip it and carry straight on. Nothing is lost.', style: FolioType.bodyMuted(p)),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: InkButton(label: 'Watch now', height: 52, onPressed: () => _close(true))),
            const SizedBox(width: 14),
            Expanded(child: OutlineButtonFolio(label: 'No thanks', height: 52, onPressed: () => _close(false))),
          ]),
        ]),
      ),
    );
  }
}
