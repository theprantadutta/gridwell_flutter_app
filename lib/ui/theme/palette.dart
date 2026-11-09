import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Brightness;

/// Tally color tokens (design kit v2.0, `04-design-system/DESIGN-SPEC.md`).
///
/// Light and dark are a token remap, not a second design: every widget reads
/// semantic roles from [GridwellPalette]. Lime is a signal, never decoration:
/// it marks the primary action, the active line and fresh progress.
///
/// The three cell states are separated by shape first (solid square, short
/// dash, emptiness) and by color second. `test/legibility/` checks contrast
/// for every variant under protanopia, deuteranopia, tritanopia and
/// monochromacy.
class GridwellPalette {
  const GridwellPalette({
    required this.brightness,
    required this.bg,
    required this.sunk,
    required this.surface,
    required this.cell,
    required this.track,
    required this.tile,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.rule,
    required this.mark,
    required this.outline,
    required this.lime,
    required this.onLime,
    required this.accent,
    required this.hl,
    required this.error,
    required this.onError,
    required this.art,
    this.majorRuleWidth = 1,
  });

  final Brightness brightness;

  /// Page background (`--bg`).
  final Color bg;

  /// Dividers between slabs and the grid gaps (`--sunk`).
  final Color sunk;

  /// Buttons, plates, rows (`--surface`).
  final Color surface;

  /// An empty board cell (`--cell`).
  final Color cell;

  /// Empty progress ticks, switch tracks (`--track`).
  final Color track;

  /// Behind revealed pictures (`--tile`).
  final Color tile;

  /// Text, filled cells, wordmark (`--ink`).
  final Color ink;

  /// Secondary text, inactive tabs (`--ink-2`).
  final Color ink2;

  /// Retired clues, disabled (`--ink-3`).
  final Color ink3;

  /// Major grid lines, every fifth (`--rule`).
  final Color rule;

  /// The dash on a crossed-out cell (`--mark`).
  final Color mark;

  /// Chip and input borders (`--outline`).
  final Color outline;

  /// Primary slabs and the active cursor (`--lime`). The same in both themes.
  final Color lime;

  /// Text and glyphs on lime (`--on-lime`).
  final Color onLime;

  /// Accent text and lines on the page (`--accent`): lime on dark, deep green
  /// on light, where lime text would not read.
  final Color accent;

  /// The active row and column band (`--hl`).
  final Color hl;

  /// Proven mistakes and destructive actions (`--error`).
  final Color error;

  /// Text on error fills (`--on-error`).
  final Color onError;

  /// Revealed-picture colors, indexed by `PictureColor` (0 = background).
  final List<Color> art;

  /// Stroke of every fifth grid line, in logical pixels.
  final double majorRuleWidth;

  bool get isDark => brightness == Brightness.dark;

  // Picture palette. PictureColor order: background, ink (art-b), red (art-a),
  // ochre (art-c), stone (art-d), indigo (art-e). "ink" follows the page ink so
  // single-color pictures read in both themes.
  static const _artDark = [
    Color(0x00000000),
    Color(0xFFF0F3E8), // chalk
    Color(0xFFF47D67), // coral
    Color(0xFFC1EE66), // lime
    Color(0xFF537163), // moss
    Color(0xFF46A0B5), // sea
  ];
  static const _artLight = [
    Color(0x00000000),
    Color(0xFF11241C), // soot
    Color(0xFFE05C45), // coral
    Color(0xFFB0DE49), // lime
    Color(0xFF4E6B5E), // moss
    Color(0xFF008096), // sea
  ];

  static const dark = GridwellPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF071A13),
    sunk: Color(0xFF02130C),
    surface: Color(0xFF12271E),
    cell: Color(0xFF132920),
    track: Color(0xFF1C3329),
    tile: Color(0xFF142C22),
    ink: Color(0xFFF0F3E8),
    ink2: Color(0xFF95AB9E),
    ink3: Color(0xFF465B51),
    rule: Color(0xFF537163),
    mark: Color(0xFF738D81),
    outline: Color(0xFF435C50),
    lime: Color(0xFFC1EE66),
    onLime: Color(0xFF0F190C),
    accent: Color(0xFFC1EE66),
    hl: Color(0x24C1EE66),
    error: Color(0xFFF87962),
    onError: Color(0xFF0F190C),
    art: _artDark,
  );

  static const light = GridwellPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF6F8F0),
    sunk: Color(0xFFCAD4C8),
    surface: Color(0xFFE7EBE1),
    cell: Color(0xFFFDFEFB),
    track: Color(0xFFD2DBCE),
    tile: Color(0xFFDBE5D6),
    ink: Color(0xFF0D1F16),
    ink2: Color(0xFF475B50),
    ink3: Color(0xFF94A396),
    rule: Color(0xFF3A5446),
    mark: Color(0xFF6D8073),
    outline: Color(0xFFA3B3A6),
    lime: Color(0xFFC1EE66),
    onLime: Color(0xFF0F190C),
    accent: Color(0xFF3C740D),
    hl: Color(0x61C1EE66),
    error: Color(0xFFCC3526),
    onError: Color(0xFFFFFFFF),
    art: _artLight,
  );

  /// High contrast: `--ink-3` becomes `--ink-2` so nothing relies on a faint
  /// tone, and major rules thicken to 2 pt.
  static GridwellPalette highContrast(GridwellPalette b) => GridwellPalette(
        brightness: b.brightness,
        bg: b.bg,
        sunk: b.sunk,
        surface: b.surface,
        cell: b.cell,
        track: b.track,
        tile: b.tile,
        ink: b.ink,
        ink2: b.ink2,
        ink3: b.ink2,
        rule: b.rule,
        mark: b.ink2,
        outline: b.ink2,
        lime: b.lime,
        onLime: b.onLime,
        accent: b.accent,
        hl: b.hl,
        error: b.error,
        onError: b.onError,
        art: b.art,
        majorRuleWidth: 2,
      );

  static GridwellPalette of(Brightness brightness, {bool highContrast = false}) {
    final base = brightness == Brightness.dark ? dark : light;
    return highContrast ? GridwellPalette.highContrast(base) : base;
  }
}
