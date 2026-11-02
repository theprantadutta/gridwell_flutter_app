import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/daily.dart';
import '../../state/online.dart';
import '../../state/providers.dart';
import '../theme/gridwell_theme.dart';
import '../theme/typography.dart';
import '../widgets/folio.dart';
import '../widgets/plate_thumb.dart';

const _months = [
  'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
  'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
];
const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

String longDate(DateTime d) {
  final m = _months[d.month - 1];
  return '${_weekdays[d.weekday - 1]} ${d.day} ${m[0]}${m.substring(1).toLowerCase()}';
}

String _beginsText(String start) {
  final d = DateTime.tryParse(start);
  if (d == null) return 'The Daily begins soon.';
  return 'The first leaf of the Daily is pressed on ${longDate(d)}. Until then, the book is yours.';
}

/// The Daily: today's leaf and the month's calendar.
class DailyScreen extends ConsumerStatefulWidget {
  const DailyScreen({super.key});

  @override
  ConsumerState<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends ConsumerState<DailyScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

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
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: p.surfaceRaised,
      shape: const RoundedRectangleBorder(),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(folioMargin),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('A MISSED LEAF · ${day.date.day} ${_months[day.date.month - 1]}', style: FolioType.kicker(p)),
          const SizedBox(height: 10),
          Text('Watch a short video to open this day. You can solve it any time; late leaves are not ranked.',
              style: FolioType.body(p, size: 19)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: InkButton(label: 'Open this day', height: 54, onPressed: () => Navigator.pop(context, true))),
            const SizedBox(width: 16),
            Expanded(child: OutlineButtonFolio(label: 'Not now', onPressed: () => Navigator.pop(context, false))),
          ]),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final today = ref.watch(todayDailyProvider);
    final days = ref.watch(dailyMonthProvider(_month));
    final todayState = days.where((d) => d.key == localDateString(now)).firstOrNull;
    final solvedCount = days.where((d) => d.state == DayState.solved).length;
    final pastCount = days.where((d) => d.puzzle != null && d.state != DayState.future).length;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday; // 1 = Monday

    return ListView(padding: EdgeInsets.zero, children: [
      WordmarkHeader(trailing: longDate(now)),
      Padding(
        padding: const EdgeInsets.fromLTRB(folioMargin, 28, folioMargin, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('The Daily', style: FolioType.display(p)),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(border: Border.all(color: p.textPrimary, width: 1.2)),
            padding: const EdgeInsets.all(10),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: p.ruleStrong)),
              padding: const EdgeInsets.all(22),
              child: today == null
                  ? Text(
                      _beginsText(ref.watch(puzzleSetProvider).dailyStartDate),
                      style: FolioType.bodyMuted(p, size: 18),
                    )
                  : Row(children: [
                      SizedBox(
                        width: 120,
                        child: todayState?.state == DayState.solved
                            ? PlateThumb(puzzle: today, state: PlateState.solved)
                            : AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(color: p.surfaceRaised, border: Border.all(color: p.ruleStrong)),
                                  alignment: Alignment.center,
                                  child: Text('?', style: FolioType.style(size: 40, color: p.textFaint)),
                                ),
                              ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("TODAY'S LEAF", style: FolioType.kicker(p)),
                          const SizedBox(height: 8),
                          Text(today.name, style: FolioType.plateTitle(p, size: 32)),
                          const SizedBox(height: 4),
                          Text('${today.width} × ${today.height} · a new leaf at midnight',
                              style: FolioType.bodyMuted(p, size: 16)),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: 140,
                            child: InkButton(
                              label: todayState?.state == DayState.solved ? 'Solved' : 'Begin',
                              height: 50,
                              onPressed: todayState?.state == DayState.solved
                                  ? null
                                  : () => context.push('/play/${today.id}'),
                            ),
                          ),
                        ]),
                      ),
                    ]),
            ),
          ),
          const SizedBox(height: 32),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              child: Padding(padding: const EdgeInsets.only(right: 10), child: Text('‹', style: FolioType.header(p))),
            ),
            Text(_months[_month.month - 1], style: FolioType.kicker(p, color: p.textPrimary)),
            if (_month.isBefore(DateTime(now.year, now.month)))
              GestureDetector(
                onTap: () => setState(() => _month = DateTime(_month.year, _month.month + 1)),
                child: Padding(padding: const EdgeInsets.only(left: 10), child: Text('›', style: FolioType.header(p))),
              ),
            const Spacer(),
            Text('$solvedCount of $pastCount solved', style: FolioType.header(p)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
              Expanded(child: Center(child: Text(d, style: FolioType.style(size: 15, color: p.textMuted)))),
          ]),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.95,
            children: [
              for (var i = 1; i < firstWeekday; i++) const SizedBox(),
              for (final day in days) _DayCell(day: day, onTap: () => _openDay(day)),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Container(width: 16, height: 16, color: p.textPrimary),
            const SizedBox(width: 8),
            Text('solved', style: FolioType.bodyMuted(p)),
            const SizedBox(width: 24),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(border: Border.all(color: p.ruleStrong)),
              child: Icon(Icons.close, size: 13, color: p.accent),
            ),
            const SizedBox(width: 8),
            Text('missed', style: FolioType.bodyMuted(p)),
            const SizedBox(width: 24),
            Container(width: 16, height: 16, decoration: BoxDecoration(border: Border.all(color: p.accent))),
            const SizedBox(width: 8),
            Text('today', style: FolioType.bodyMuted(p)),
          ]),
        ]),
      ),
    ]);
  }
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
    return Semantics(
      button: playable,
      label: label,
      child: GestureDetector(
        onTap: playable ? onTap : null,
        child: switch (day.state) {
          DayState.solved => Container(
              color: p.textPrimary,
              padding: const EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text(n, style: FolioType.style(size: 15, color: p.onInk, weight: 600)),
            ),
          DayState.today => Container(
              decoration: BoxDecoration(border: Border.all(color: p.accent, width: 1.5)),
              padding: const EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text(n, style: FolioType.style(size: 15, color: p.accent, weight: 600)),
            ),
          DayState.missed || DayState.unlocked => Container(
              decoration: BoxDecoration(color: p.surfaceRaised, border: Border.all(color: p.ruleStrong)),
              padding: const EdgeInsets.all(6),
              child: Stack(children: [
                Text(n, style: FolioType.style(size: 15, color: p.textMuted)),
                if (day.state == DayState.missed)
                  Center(child: Icon(Icons.close, size: 26, color: p.accent)),
              ]),
            ),
          _ => Container(
              padding: const EdgeInsets.all(6),
              alignment: Alignment.topLeft,
              child: Text(n, style: FolioType.style(size: 15, color: p.textFaint)),
            ),
        },
      ),
    );
  }
}
