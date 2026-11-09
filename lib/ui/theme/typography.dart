import 'package:flutter/painting.dart';

/// Tally type: Schibsted Grotesk (bundled static weights 500, 700, 800, 900).
///
/// Numbers use tabular figures so timers and counts never jitter. Schibsted's
/// `tnum` also widens `.` and `,`, so running text keeps proportional
/// figures: number styles (display, clue, chip, micro, body-s) are tabular,
/// and [tabular] makes any other style tabular for a number set in it.
///
/// Every style takes its color; sizes, weights, line heights and tracking are
/// the kit's (`DESIGN-SPEC.md` section 3).
abstract final class TallyType {
  static const family = 'Schibsted Grotesk';

  static const figures = [FontFeature.tabularFigures()];

  static TextStyle style({
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w700,
    double tracking = 0,
    double? height,
    bool tabular = false,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontFeatures: tabular ? figures : null,
        letterSpacing: size * tracking,
        height: height,
      );

  /// [base] with tabular figures, for a number set in a text style (a timer
  /// in the top bar, a count in a row).
  static TextStyle tabular(TextStyle base) => base.copyWith(fontFeatures: figures);

  /// 92 / 900: the overall percent on Home.
  static TextStyle displayXl(Color c) => style(size: 92, color: c, weight: FontWeight.w900, height: 0.8, tracking: -0.05, tabular: true);

  /// 72 / 900: the solve time on Complete, the price on the store.
  static TextStyle displayL(Color c) => style(size: 72, color: c, weight: FontWeight.w900, height: 0.8, tracking: -0.05, tabular: true);

  /// 60 / 900: the live timer on the board.
  static TextStyle displayM(Color c) => style(size: 60, color: c, weight: FontWeight.w900, height: 0.85, tracking: -0.04, tabular: true);

  /// 40 / 900: screen titles, the puzzle name on Complete.
  static TextStyle titleL(Color c) => style(size: 40, color: c, weight: FontWeight.w900, height: 1, tracking: -0.035);

  /// 32 / 900: the daily puzzle name, section heroes.
  static TextStyle titleM(Color c) => style(size: 32, color: c, weight: FontWeight.w900, height: 1, tracking: -0.03);

  /// 26 / 900 uppercase: FILL, MARK, NEXT PUZZLE.
  static TextStyle slab(Color c) => style(size: 26, color: c, weight: FontWeight.w900, height: 1, tracking: -0.01);

  /// 22 / 800: the board's top bar title.
  static TextStyle titleS(Color c) => style(size: 22, color: c, weight: FontWeight.w800, height: 1, tracking: -0.02);

  /// 18 / 800: section headers, collection names.
  static TextStyle bodyL(Color c) => style(size: 18, color: c, weight: FontWeight.w800, height: 1, tracking: -0.01);

  /// 16 / 700: buttons, list rows.
  static TextStyle body(Color c) => style(size: 16, color: c, weight: FontWeight.w700, height: 1);

  /// 15 / 800: progress row labels and counts.
  static TextStyle bodyS(Color c) => style(size: 15, color: c, weight: FontWeight.w800, height: 1, tabular: true);

  /// Running text: explanations, blurbs (14-16 / 700, comfortable leading).
  static TextStyle prose(Color c, {double size = 15}) => style(size: size, color: c, weight: FontWeight.w700, height: 1.4);

  /// 13 / 700: captions and secondary info.
  static TextStyle label(Color c) => style(size: 13, color: c, weight: FontWeight.w700, height: 1.35);

  /// 12 / 700: size chips.
  static TextStyle chip(Color c) => style(size: 12, color: c, weight: FontWeight.w700, height: 1, tabular: true);

  /// 11 / 800 uppercase, tracked +14%: DAILY · MON 9 NOV.
  static TextStyle overline(Color c) => style(size: 11, color: c, weight: FontWeight.w800, height: 1, tracking: 0.14);

  /// 9 / 700: plate numbers.
  static TextStyle micro(Color c) => style(size: 9, color: c, weight: FontWeight.w700, height: 1, tabular: true);

  /// Clue numbers: 700 open, 500 retired.
  static TextStyle clue(Color c, double size, {bool retired = false}) =>
      style(size: size, color: c, weight: retired ? FontWeight.w500 : FontWeight.w700, height: 1.07, tabular: true);
}
