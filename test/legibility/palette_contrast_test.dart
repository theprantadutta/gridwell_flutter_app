// Token-level legibility gate: every pair that carries meaning must stay above
// its contrast floor for every palette variant and every simulated color
// vision. If this fails, the palette is not committed.

import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';

import 'cvd.dart';

class _Check {
  const _Check(this.name, this.a, this.b, this.min, {double? cvdMin}) : cvdMin = cvdMin ?? min;

  final String name;
  final Color Function(GridwellPalette) a;
  final Color Function(GridwellPalette) b;

  /// Floor under typical vision.
  final double min;

  /// Floor under the simulated color visions, where it differs.
  final double cvdMin;
}

/// The active row and column band over [under].
Color _hl(GridwellPalette p, Color under) => composite(p.hl, under, BlendMode.srcOver);

/// Floors (DESIGN-SPEC section 8). Clue numbers and the filled state use WCAG
/// AAA (7:1): they are small and everywhere. Body and secondary text use AA
/// (4.5:1). Graphical marks and rings use WCAG 1.4.11 (3:1). `--ink-3` is
/// decorative (retired clues repeat what the board already shows), so it only
/// has to stay visible and clearly apart from live clues. The grid gaps and
/// major rules only guide the eye; the shapes inside the cells carry the
/// meaning, so they get a lower floor (rules thicken in high contrast).
/// The active band tints whatever is under it; filled and empty stay at AA
/// apart there, and the band follows the finger, so it is never the only
/// place a cell is seen.
List<_Check> _checks(bool highContrast) => [
      _Check('filled vs empty cell', (p) => p.ink, (p) => p.cell, 7),
      _Check('dash vs empty cell', (p) => p.mark, (p) => p.cell, 3),
      _Check('clue number vs page', (p) => p.ink, (p) => p.bg, 7),
      _Check('retired clue vs page (still visible)', (p) => p.ink3, (p) => p.bg, highContrast ? 4.5 : 1.8),
      _Check('live vs retired clue (visibly different)', (p) => p.ink, (p) => p.ink3, highContrast ? 1.5 : 2.5),
      _Check('major rule vs empty cell', (p) => p.rule, (p) => p.cell, 2.5),
      _Check('grid gap vs empty cell', (p) => p.sunk, (p) => p.cell, 1.1),
      _Check('secondary text vs page', (p) => p.ink2, (p) => p.bg, 4.5),
      _Check('secondary text on a surface', (p) => p.ink2, (p) => p.surface, 4.5),
      _Check('accent text vs page', (p) => p.accent, (p) => p.bg, 4.5),
      _Check('cursor ring vs empty cell', (p) => p.accent, (p) => p.cell, 3),
      _Check('mistake ring vs empty cell', (p) => p.error, (p) => p.cell, 3),
      _Check('text on lime', (p) => p.onLime, (p) => p.lime, 7),
      // The kit's light error red is AA for typical vision and 4.3:1 under
      // deuteranopia; its headline is large text (3:1) and the body is bold.
      _Check('text on error', (p) => p.onError, (p) => p.error, 4.5, cvdMin: 4.0),
      _Check('clue number on the band', (p) => p.ink, (p) => _hl(p, p.bg), 7),
      _Check('filled vs empty, both on the band', (p) => _hl(p, p.ink), (p) => _hl(p, p.cell), 4.5),
      _Check('dash on a banded cell (drawn in --ink-2)', (p) => p.ink2, (p) => _hl(p, p.cell), 3),
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
            final floor = vision == Vision.typical ? check.min : check.cvdMin;
            expect(ratio, greaterThanOrEqualTo(floor),
                reason: '$name / ${check.name} under ${vision.name}: '
                    '${ratio.toStringAsFixed(2)} < $floor');
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
