// Token-level legibility gate: every pair that carries meaning on the board
// must stay above its contrast floor for every palette variant and every
// simulated color vision. If this fails, the palette is not committed.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';

import 'cvd.dart';

class _Check {
  const _Check(this.name, this.a, this.b, this.min, {this.max});

  final String name;
  final Color Function(GridwellPalette) a;
  final Color Function(GridwellPalette) b;
  final double min;

  /// Optional ceiling, for pairs that must stay visibly *different* in strength.
  final double? max;
}

Color _hl(GridwellPalette p, Color under) => composite(p.highlight, under, p.highlightBlend);

/// Floors. Text uses WCAG AAA (7:1) because clue numbers are small and
/// everywhere; graphical marks use WCAG 1.4.11 (3:1).
List<_Check> _checks(bool highContrast) => [
      _Check('filled vs untouched cell', (p) => p.cellFilled, (p) => p.cellEmpty, 7),
      _Check('cross mark vs untouched cell', (p) => p.cellCrossed, (p) => p.cellEmpty, 3),
      _Check('clue number vs page', (p) => p.clueText, (p) => p.surface, 7),
      _Check('retired clue vs page (still readable)', (p) => p.clueRetired, (p) => p.surface,
          highContrast ? 3 : 1.8),
      _Check('live vs retired clue (visibly different)', (p) => p.clueText, (p) => p.clueRetired,
          highContrast ? 1.5 : 2.5),
      _Check('major grid line vs cell', (p) => p.gridLineMajor, (p) => p.cellEmpty, 7),
      _Check('minor grid line vs cell', (p) => p.gridLine, (p) => p.cellEmpty,
          highContrast ? 3 : 1.25),
      _Check('muted text vs page', (p) => p.textMuted, (p) => p.surface, 4.5),
      _Check('accent (cursor, mistake ring) vs cell', (p) => p.accent, (p) => p.cellEmpty, 3),
      _Check('clue number on highlighted band', (p) => p.clueText, (p) => _hl(p, p.surface), 7),
      _Check('filled vs untouched, both highlighted', (p) => _hl(p, p.cellFilled),
          (p) => _hl(p, p.cellEmpty), 7),
      _Check('cross mark on highlighted cell', (p) => p.cellCrossed, (p) => _hl(p, p.cellEmpty), 3),
    ];

void main() {
  final variants = <String, GridwellPalette>{
    'light': GridwellPalette.light,
    'dark': GridwellPalette.dark,
    'light high contrast': GridwellPalette.highContrast(GridwellPalette.light),
    'dark high contrast': GridwellPalette.highContrast(GridwellPalette.dark),
  };

  final report = StringBuffer('palette contrast (worst case across visions):\n');
  variants.forEach((name, palette) {
    final hc = name.contains('high contrast');
    group(name, () {
      for (final check in _checks(hc)) {
        test(check.name, () {
          var worst = double.infinity;
          var worstVision = Vision.typical;
          for (final vision in Vision.values) {
            final ratio = contrast(
              simulate(check.a(palette), vision),
              simulate(check.b(palette), vision),
            );
            if (ratio < worst) {
              worst = ratio;
              worstVision = vision;
            }
            expect(ratio, greaterThanOrEqualTo(check.min),
                reason: '$name / ${check.name} under ${vision.name}: '
                    '${ratio.toStringAsFixed(2)} < ${check.min}');
          }
          report.writeln('  $name | ${check.name}: ${worst.toStringAsFixed(2)} '
              '(${worstVision.name}, floor ${check.min})');
        });
      }
    });
  });

  tearDownAll(() {
    // ignore: avoid_print
    print(report);
  });
}
