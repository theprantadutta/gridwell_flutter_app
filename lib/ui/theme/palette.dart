import 'package:flutter/painting.dart';
import 'package:flutter/services.dart' show Brightness;

/// Folio color tokens.
///
/// Values are the design's OKLCH tokens converted to sRGB (the comment on each
/// light/dark pair gives the source). Light and dark are a token remap, not a
/// second design: every widget reads semantic roles from [GridwellPalette].
///
/// The three cell states are separated by structure first (solid fill, a cross
/// mark, emptiness) and by color second. `test/legibility/` checks contrast for
/// every variant under protanopia, deuteranopia, tritanopia and monochromacy.
class GridwellPalette {
  const GridwellPalette({
    required this.brightness,
    required this.surface,
    required this.surfaceRaised,
    required this.textPrimary,
    required this.textMuted,
    required this.textFaint,
    required this.rule,
    required this.ruleStrong,
    required this.gridLine,
    required this.gridLineMajor,
    required this.cellEmpty,
    required this.cellFilled,
    required this.cellCrossed,
    required this.clueText,
    required this.clueRetired,
    required this.accent,
    required this.highlight,
    required this.highlightBlend,
    required this.onInk,
    required this.art,
    required this.gridLineWidth,
    required this.gridLineMajorWidth,
  });

  final Brightness brightness;

  /// Page background (`--paper`).
  final Color surface;

  /// Cells, plates and sheets (`--paper-2`).
  final Color surfaceRaised;

  /// Body text, titles (`--ink`).
  final Color textPrimary;

  /// Secondary text, inactive tabs (`--ink-2`).
  final Color textMuted;

  /// Disabled text (`--ink-3`).
  final Color textFaint;

  /// Hairlines (`--rule`).
  final Color rule;

  /// Plate borders, dotted leaders, switch tracks (`--rule-2`).
  final Color ruleStrong;

  /// Minor grid lines.
  final Color gridLine;

  /// Every fifth grid line and the board border.
  final Color gridLineMajor;

  /// An untouched cell.
  final Color cellEmpty;

  /// A filled cell: solid, edge to edge.
  final Color cellFilled;

  /// The cross mark drawn on a crossed cell (the cell itself stays [cellEmpty]).
  final Color cellCrossed;

  /// Clue numbers still in play.
  final Color clueText;

  /// Clue numbers already satisfied (also struck through).
  final Color clueRetired;

  /// Cursor, labels, hints, proven mistakes.
  final Color accent;

  /// Active row and column highlighter.
  final Color highlight;

  /// How [highlight] is composited over cells.
  final BlendMode highlightBlend;

  /// Text and glyphs on ink fills.
  final Color onInk;

  /// Revealed-picture colors, indexed by `PictureColor` (0 = background).
  final List<Color> art;

  /// Logical-pixel stroke widths for grid lines.
  final double gridLineWidth;
  final double gridLineMajorWidth;

  bool get isDark => brightness == Brightness.dark;

  // oklch(0.965 0.012 85) / oklch(0.19 0.01 65)
  static const _paperL = Color(0xFFF7F3EB), _paperD = Color(0xFF17130F);
  // oklch(0.982 0.008 85) / oklch(0.215 0.011 65)
  static const _paper2L = Color(0xFFFCF9F3), _paper2D = Color(0xFF1D1814);
  // oklch(0.22 0.015 60) / oklch(0.91 0.02 85)
  static const _inkL = Color(0xFF201914), _inkD = Color(0xFFE7E1D3);
  // oklch(0.48 0.015 60) / oklch(0.70 0.015 80)
  static const _ink2L = Color(0xFF645C55), _ink2D = Color(0xFFA39E94);
  // oklch(0.68 0.015 70) / oklch(0.46 0.012 70)
  static const _ink3L = Color(0xFF9E978F), _ink3D = Color(0xFF5C5751);
  // oklch(0.82 0.015 80) / oklch(0.32 0.012 70)
  static const _ruleL = Color(0xFFC9C3BA), _ruleD = Color(0xFF37322C);
  // oklch(0.74 0.015 78) / oklch(0.42 0.012 70)
  static const _rule2L = Color(0xFFB0AAA1), _rule2D = Color(0xFF514C46);
  // oklch(0.56 0.17 35) / oklch(0.70 0.15 40)
  static const _accentL = Color(0xFFC44323), _accentD = Color(0xFFEB7A52);
  // oklch(0.93 0.11 95), multiply / oklch(0.80 0.11 90 / 0.17), normal
  static const _hlL = Color(0xFFFFE891), _hlD = Color(0x2BD9BB66);

  static const _artLight = [
    Color(0x00000000), // background (not drawn)
    _inkL, // ink = art-b
    Color(0xFFC44323), // red, oklch(0.56 0.17 35)
    Color(0xFFE3AD4B), // ochre, oklch(0.78 0.13 80)
    Color(0xFF84786F), // stone, oklch(0.58 0.02 60)
    Color(0xFF336288), // indigo, oklch(0.48 0.08 245)
  ];
  static const _artDark = [
    Color(0x00000000),
    _inkD,
    Color(0xFFDD6D49), // oklch(0.66 0.15 38)
    Color(0xFFE4B65C), // oklch(0.80 0.12 82)
    Color(0xFF7A6F66), // oklch(0.55 0.02 65)
    Color(0xFF5C8BB3), // oklch(0.62 0.08 245)
  ];

  static const light = GridwellPalette(
    brightness: Brightness.light,
    surface: _paperL,
    surfaceRaised: _paper2L,
    textPrimary: _inkL,
    textMuted: _ink2L,
    textFaint: _ink3L,
    rule: _ruleL,
    ruleStrong: _rule2L,
    gridLine: _ruleL,
    gridLineMajor: _inkL,
    cellEmpty: _paper2L,
    cellFilled: _inkL,
    cellCrossed: _accentL,
    clueText: _inkL,
    clueRetired: _ink3L,
    accent: _accentL,
    highlight: _hlL,
    highlightBlend: BlendMode.multiply,
    onInk: _paperL,
    art: _artLight,
    gridLineWidth: 1,
    gridLineMajorWidth: 1.5,
  );

  static const dark = GridwellPalette(
    brightness: Brightness.dark,
    surface: _paperD,
    surfaceRaised: _paper2D,
    textPrimary: _inkD,
    textMuted: _ink2D,
    textFaint: _ink3D,
    rule: _ruleD,
    ruleStrong: _rule2D,
    gridLine: _ruleD,
    gridLineMajor: _inkD,
    cellEmpty: _paper2D,
    cellFilled: _inkD,
    cellCrossed: _accentD,
    clueText: _inkD,
    clueRetired: _ink3D,
    accent: _accentD,
    highlight: _hlD,
    highlightBlend: BlendMode.srcOver,
    onInk: _paperD,
    art: _artDark,
    gridLineWidth: 1,
    gridLineMajorWidth: 1.5,
  );

  /// High contrast: heavier grid lines, full-strength ink, and retired clues
  /// and minor lines pulled up to `--ink-2` so nothing relies on a faint tone.
  static GridwellPalette highContrast(GridwellPalette base) => GridwellPalette(
        brightness: base.brightness,
        surface: base.surface,
        surfaceRaised: base.surfaceRaised,
        textPrimary: base.textPrimary,
        textMuted: base.textPrimary,
        textFaint: base.textMuted,
        rule: base.ruleStrong,
        ruleStrong: base.textMuted,
        gridLine: base.textMuted,
        gridLineMajor: base.textPrimary,
        cellEmpty: base.surfaceRaised,
        cellFilled: base.textPrimary,
        cellCrossed: base.accent,
        clueText: base.textPrimary,
        clueRetired: base.textMuted,
        accent: base.accent,
        highlight: base.highlight,
        highlightBlend: base.highlightBlend,
        onInk: base.onInk,
        art: base.art,
        gridLineWidth: 1.5,
        gridLineMajorWidth: 2.5,
      );

  static GridwellPalette of(Brightness brightness, {bool highContrast = false}) {
    final base = brightness == Brightness.dark ? dark : light;
    return highContrast ? GridwellPalette.highContrast(base) : base;
  }
}
