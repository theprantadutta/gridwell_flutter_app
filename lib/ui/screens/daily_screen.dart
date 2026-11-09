import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/daily.dart';
import '../../state/online.dart';
import '../../state/providers.dart';
import '../../state/services.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/home/daily_slab.dart';
import '../widgets/tally.dart';

String _beginsText(String start) {
  final d = DateTime.tryParse(start);
  if (d == null) return 'The Daily begins soon.';
  return 'The first Daily arrives on ${longDate(d)}. Until then, every collection is open.';
}

/// The Daily: your streak, today's puzzle and the month's calendar. Swipe the
/// calendar sideways for earlier months.
class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _canGoForward {
    final now = DateTime.now();
    return _month.isBefore(DateTime(now.year, now.month));
  }

  void _shift(int months) {
    if (months > 0 && !_canGoForward) return;
    setState(() => _month = DateTime(_month.year, _month.month + months));
  }

  Future<void> _openDay(DailyDay day) async {
    final puzzle = day.puzzle;
    if (puzzle == null) return;
    if (day.state == DayState.missed) {
      final ok = await _confirmUnlock(day);
      if (ok != true) return;
      final unlocked = await ref.read(dailyActionsProvider).unlockMissed(day);
      if (!unlocked || !mounted) return;
    }
    if (mounted) context.push('/play/${puzzle.id}');
  }

  Future<bool?> _confirmUnlock(DailyDay day) {
    final p = context.palette;
    final premium = ref.read(entitlementsProvider).premium;
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.surface,
      shape: const RoundedRectangleBorder(),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: 4, color: p.lime),
          Padding(
            padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Overline('Missed · ${shortDate(day.date)}', color: p.accent),
              const SizedBox(height: 10),
              Text('Open this day?', style: TallyType.titleS(p.ink).copyWith(fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(
                premium
                    ? 'You can solve it any time. Late solves are not ranked.'
                    : 'Watch a short video to open it. You can solve it any time. Late solves are not ranked.',
                style: TallyType.prose(p.ink2, size: 14),
              ),
            ]),
          ),
          SlabRow(height: 64, children: [
            SlabButton(
              label: 'OPEN IT',
              color: p.lime,
              textColor: p.onLime,
              onPressed: () => Navigator.pop(context, true),
            ),
            SlabButton(label: 'NOT NOW', onPressed: () => Navigator.pop(context, false)),
          ]),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final today = ref.watch(todayDailyProvider);
    final days = ref.watch(dailyMonthProvider(_month));
    final streak = ref.watch(dailyStreakProvider);
    final results = ref.watch(dailyResultsProvider).value ?? const {};
    final todayResult = results[localDateString(now)];
    final solvedCount = days.where((d) => d.state == DayState.solved).length;
    final pastCount = days.where((d) => d.puzzle != null && d.state != DayState.future).length;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1 = Monday

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const TallyPageTitle('Daily'),
        Padding(
          padding: const EdgeInsets.fromLTRB(tallyMargin, 22, tallyMargin, 24),
          child: BigStat(
            value: '${streak.current}',
            style: TallyType.displayL(p.ink),
            label: 'day streak\nbest ${streak.best}',
            gap: 12,
          ),
        ),
        DailySlab(
          kicker: 'TODAY',
          puzzle: today,
          solved: todayResult?.solved ?? false,
          solvedTimeMs: todayResult?.timeMs,
          emptyText: _beginsText(ref.watch(puzzleSetProvider).dailyStartDate),
          onTap: today == null || (todayResult?.solved ?? false) ? null : () => context.push('/play/${today.id}'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(tallyMargin, 24, tallyMargin, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Semantics(
                label: '${monthNames[_month.month - 1]} ${_month.year}',
                hint: 'Swipe the calendar for other months',
                customSemanticsActions: {
                  const CustomSemanticsAction(label: 'Previous month'): () => _shift(-1),
                  if (_canGoForward) const CustomSemanticsAction(label: 'Next month'): () => _shift(1),
                },
                excludeSemantics: true,
                child: Text(
                  '${monthNames[_month.month - 1]} ${_month.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TallyType.bodyL(p.ink).copyWith(fontSize: 19, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('$solvedCount of $pastCount solved', style: TallyType.tabular(TallyType.label(p.ink2))),
          ]),
        ),
        const SizedBox(height: 14),
        _CalendarWidth(
          child: Row(children: [
            for (final (i, d) in ['M', 'T', 'W', 'T', 'F', 'S', 'S'].indexed) ...[
              if (i > 0) const SizedBox(width: _gap),
              Expanded(child: Center(child: Text(d, style: TallyType.label(p.ink2).copyWith(fontWeight: FontWeight.w800)))),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v > 250) _shift(-1);
            if (v < -250) _shift(1);
          },
          child: _CalendarWidth(
            child: LayoutBuilder(builder: (context, c) {
              final cell = (c.maxWidth - _gap * 6) / 7;
              final slots = [for (var i = 1; i < firstWeekday; i++) null, ...days];
              final rows = (slots.length / 7).ceil();
              return Column(children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: _gap),
                  Row(children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      SizedBox(
                        width: cell,
                        height: cell,
                        child: r * 7 + i < slots.length && slots[r * 7 + i] != null
                            ? _DayCell(day: slots[r * 7 + i]!, onTap: () => _openDay(slots[r * 7 + i]!))
                            : null,
                      ),
                    ],
                  ]),
                ],
              ]);
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 28),
          child: Wrap(spacing: 22, runSpacing: 10, children: [
            _LegendItem(swatch: Container(width: 12, height: 12, color: p.ink), label: 'Solved'),
            _LegendItem(
              swatch: Container(
                width: 12,
                height: 12,
                color: p.surface,
                alignment: Alignment.center,
                child: Container(width: 6, height: 2, color: p.mark),
              ),
              label: 'Missed',
            ),
            _LegendItem(swatch: Container(width: 12, height: 12, color: p.lime), label: 'Today'),
          ]),
        ),
      ],
    );
  }

  static const _gap = 4.0;
}

/// Holds the calendar to sensible proportions on tablets: days stop growing
/// at 80 pt and the month is centered.
class _CalendarWidth extends StatelessWidget {
  const _CalendarWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
        child: Align(
          alignment: Alignment.center,
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 80 * 7 + 4 * 6), child: child),
        ),
      );
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.swatch, required this.label});

  final Widget swatch;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          swatch,
          const SizedBox(width: 8),
          Text(label, style: TallyType.body(context.palette.ink2)),
        ],
      );
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.onTap});

  final DailyDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = '${day.date.day}';
    final playable = day.puzzle != null && day.state != DayState.future;
    final label = switch (day.state) {
      DayState.solved => '$n, solved',
      DayState.missed => '$n, missed',
      DayState.unlocked => '$n, opened',
      DayState.today => '$n, today',
      _ => n,
    };
    final (Color bg, Color fg) = switch (day.state) {
      DayState.solved => (p.ink, p.bg),
      DayState.today => (p.lime, p.onLime),
      DayState.missed || DayState.unlocked => (p.surface, p.ink),
      _ => (p.surface, p.ink3),
    };
    return Semantics(
      button: playable,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: playable ? onTap : null,
        child: Container(
          color: bg,
          child: LayoutBuilder(builder: (context, c) {
            final size = (c.maxWidth * 0.3).clamp(11.0, 22.0);
            final number = Text(
              n,
              maxLines: 1,
              textScaler: TextScaler.noScaling,
              style: TallyType.style(size: size, color: fg, weight: FontWeight.w800, height: 1),
            );
            if (day.state != DayState.missed) return Center(child: number);
            // Missed: the number with a short `--mark` dash beneath it.
            return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              number,
              SizedBox(height: size * 0.45),
              Container(width: c.maxWidth * 0.26, height: 2, color: p.mark),
            ]);
          }),
        ),
      ),
    );
  }
}
