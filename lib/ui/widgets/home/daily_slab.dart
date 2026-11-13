import 'package:material_ui/material_ui.dart';

import '../../../engine/model/puzzle.dart';
import '../../theme/gridwell_theme.dart';
import '../../theme/typography.dart';
import '../tally.dart';

const _weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
const _months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
const monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

/// "MON 9 NOV".
String shortDate(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

/// "Monday 9 November".
String longDate(DateTime d) {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return '${days[d.weekday - 1]} ${d.day} ${monthNames[d.month - 1]}';
}

/// The daily slab: full-width lime with an overline ("DAILY · MON 9 NOV"),
/// the puzzle name in `title-m`, its size and a 44 pt round arrow. Once solved
/// it drops to `--surface`, since lime only marks the thing to press.
class DailySlab extends StatelessWidget {
  const DailySlab({
    super.key,
    required this.kicker,
    required this.puzzle,
    required this.solved,
    required this.onTap,
    this.solvedTimeMs,
    this.emptyText,
  });

  /// "DAILY" or "TODAY"; the date is appended.
  final String kicker;
  final PuzzleRecord? puzzle;
  final bool solved;
  final int? solvedTimeMs;
  final VoidCallback? onTap;

  /// Shown when there is no puzzle yet (before the calendar starts).
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final x = puzzle;
    final date = shortDate(DateTime.now());
    if (x == null) {
      return Container(
        color: p.surface,
        padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Overline('$kicker · $date', color: p.accent),
          const SizedBox(height: 10),
          Text(emptyText ?? 'The Daily begins soon.', style: TallyType.prose(p.ink2)),
        ]),
      );
    }
    final fg = solved ? p.ink : p.onLime;
    final size = '${x.width}×${x.height}';
    return Pressable(
      color: solved ? p.surface : p.lime,
      onTap: onTap,
      semanticLabel: solved
          ? '$kicker, ${x.name}, solved'
          : '$kicker, ${x.name}, $size',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 18),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Overline(
                solved ? '$kicker · $date · SOLVED' : '$kicker · $date',
                color: solved ? p.accent : p.onLime,
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(x.name, maxLines: 1, style: TallyType.titleM(fg)),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text.rich(
            clockSpan(
              solved && solvedTimeMs != null ? formatClock(solvedTimeMs!) : size,
              TallyType.tabular(TallyType.bodyL(fg).copyWith(fontWeight: FontWeight.w900)),
            ),
          ),
          if (!solved) ...[const SizedBox(width: 14), const RoundArrow()],
        ]),
      ),
    );
  }
}
