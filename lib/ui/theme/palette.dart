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

  /// The signal color (`--lime`): primary slabs and the active cursor. Lime
  /// in the standard theme, the same in light and dark; every other theme
  /// brings its own (marigold, aqua, yellow, orange, pink, lavender, sky).
  final Color lime;

  /// Text and glyphs on the signal color (`--on-lime`).
  final Color onLime;

  /// Accent text and lines on the page (`--accent`): the signal color itself
  /// on dark pages, a deep version of it on light ones, where a pale signal
  /// color would not read as text.
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

  // ---------------------------------------------------------------------------
  // Themes (`lib/state/themes.dart`). Each is one fixed look built on the same
  // roles: the shapes, layout and type stay Tally, only the colors change. Every
  // one passes the same `test/legibility/` floors as light and dark, plain and
  // high contrast, under every simulated color vision.

  /// Warm cream and marigold, like a puzzle book. Free.
  static const themePaper = GridwellPalette(
    brightness: Brightness.light,
    bg: Color(0xFFF7F1E5),
    sunk: Color(0xFFDCD0BC),
    surface: Color(0xFFEEE6D6),
    cell: Color(0xFFFFFCF5),
    track: Color(0xFFE3D9C6),
    tile: Color(0xFFEADFCB),
    ink: Color(0xFF231B12),
    ink2: Color(0xFF5E5242),
    ink3: Color(0xFFA89A84),
    rule: Color(0xFF5A4A36),
    mark: Color(0xFF8A7A64),
    outline: Color(0xFFBDAF98),
    lime: Color(0xFFF2C14E),
    onLime: Color(0xFF241A0E),
    accent: Color(0xFF8A4A0C),
    hl: Color(0x52F2C14E),
    error: Color(0xFFC22F1F),
    onError: Color(0xFFFFFFFF),
    art: [
      Color(0x00000000),
      Color(0xFF231B12), // sepia ink
      Color(0xFFD6553A), // brick
      Color(0xFFE0A43A), // marigold
      Color(0xFF8A7A64), // pebble
      Color(0xFF3B5B8C), // denim
    ],
  );

  /// Deep navy and aqua.
  static const themeMidnight = GridwellPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF0B1324),
    sunk: Color(0xFF060C18),
    surface: Color(0xFF141E33),
    cell: Color(0xFF152038),
    track: Color(0xFF1F2B44),
    tile: Color(0xFF17233B),
    ink: Color(0xFFEAF0FB),
    ink2: Color(0xFF93A3BF),
    ink3: Color(0xFF46536B),
    rule: Color(0xFF56688A),
    mark: Color(0xFF7586A3),
    outline: Color(0xFF3E4C66),
    lime: Color(0xFF5CE1CF),
    onLime: Color(0xFF06201C),
    accent: Color(0xFF5CE1CF),
    hl: Color(0x2E5CE1CF),
    error: Color(0xFFFF7A6B),
    onError: Color(0xFF1A0805),
    art: [
      Color(0x00000000),
      Color(0xFFEAF0FB), // starlight
      Color(0xFFFF7E6B), // coral
      Color(0xFFF2C45A), // lamp
      Color(0xFF56688A), // slate
      Color(0xFF6FA8FF), // sky
    ],
  );

  /// True black, white and signal yellow. Crisp, and kind to OLED screens.
  static const themeInk = GridwellPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF000000),
    sunk: Color(0xFF000000),
    surface: Color(0xFF121212),
    cell: Color(0xFF161616),
    track: Color(0xFF262626),
    tile: Color(0xFF101010),
    ink: Color(0xFFFFFFFF),
    ink2: Color(0xFFA6A6A6),
    ink3: Color(0xFF4D4D4D),
    rule: Color(0xFF6B6B6B),
    mark: Color(0xFF8A8A8A),
    outline: Color(0xFF444444),
    lime: Color(0xFFFFE14A),
    onLime: Color(0xFF141000),
    accent: Color(0xFFFFE14A),
    hl: Color(0x2EFFE14A),
    error: Color(0xFFFF6B5B),
    onError: Color(0xFF140200),
    art: [
      Color(0x00000000),
      Color(0xFFFFFFFF), // white
      Color(0xFFFF6B5B), // red
      Color(0xFFFFE14A), // yellow
      Color(0xFF6B6B6B), // graphite
      Color(0xFF5AA9FF), // blue
    ],
  );

  /// Warm charcoal and orange, like a fire at night.
  static const themeEmber = GridwellPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF17110D),
    sunk: Color(0xFF0E0906),
    surface: Color(0xFF221913),
    cell: Color(0xFF241B15),
    track: Color(0xFF30251C),
    tile: Color(0xFF261D16),
    ink: Color(0xFFF7EEE3),
    ink2: Color(0xFFB8A694),
    ink3: Color(0xFF5C4D40),
    rule: Color(0xFF7A6450),
    mark: Color(0xFF998470),
    outline: Color(0xFF4E3F33),
    lime: Color(0xFFFF9F5A),
    onLime: Color(0xFF1F1205),
    accent: Color(0xFFFF9F5A),
    hl: Color(0x2EFF9F5A),
    error: Color(0xFFFF5C7A),
    onError: Color(0xFF1F0508),
    art: [
      Color(0x00000000),
      Color(0xFFF7EEE3), // ash white
      Color(0xFFF2705C), // ember red
      Color(0xFFFFC24A), // flame
      Color(0xFF7A6450), // driftwood
      Color(0xFF7FA6D9), // dusk blue
    ],
  );

  /// Soft pink and plum.
  static const themeBlossom = GridwellPalette(
    brightness: Brightness.light,
    bg: Color(0xFFFBF0F3),
    sunk: Color(0xFFE6CCD5),
    surface: Color(0xFFF4E3E9),
    cell: Color(0xFFFFFAFC),
    track: Color(0xFFEBD6DE),
    tile: Color(0xFFF1DDE5),
    ink: Color(0xFF2A1220),
    ink2: Color(0xFF6A4A5A),
    ink3: Color(0xFFB497A5),
    rule: Color(0xFF6B3F55),
    mark: Color(0xFF957484),
    outline: Color(0xFFCDB0BE),
    lime: Color(0xFFF5A8C4),
    onLime: Color(0xFF2A1220),
    accent: Color(0xFF7B3A96),
    hl: Color(0x52F5A8C4),
    error: Color(0xFFC2362B),
    onError: Color(0xFFFFFFFF),
    art: [
      Color(0x00000000),
      Color(0xFF2A1220), // plum ink
      Color(0xFFD9485F), // rose
      Color(0xFFE8A23D), // apricot
      Color(0xFF957484), // mauve
      Color(0xFF5B5FB5), // iris
    ],
  );

  /// Deep violet and lavender.
  static const themeViolet = GridwellPalette(
    brightness: Brightness.dark,
    bg: Color(0xFF150F22),
    sunk: Color(0xFF0D0817),
    surface: Color(0xFF20182F),
    cell: Color(0xFF221A33),
    track: Color(0xFF2D2440),
    tile: Color(0xFF241B36),
    ink: Color(0xFFF1ECFA),
    ink2: Color(0xFFAA9FC2),
    ink3: Color(0xFF544A6B),
    rule: Color(0xFF6E6290),
    mark: Color(0xFF8E83AA),
    outline: Color(0xFF463C5C),
    lime: Color(0xFFC6A5FF),
    onLime: Color(0xFF1A0F2E),
    accent: Color(0xFFC6A5FF),
    hl: Color(0x2EC6A5FF),
    error: Color(0xFFFF7A8A),
    onError: Color(0xFF22060B),
    art: [
      Color(0x00000000),
      Color(0xFFF1ECFA), // moonlight
      Color(0xFFFF7A8A), // rose
      Color(0xFFFFD166), // gold
      Color(0xFF6E6290), // dusk
      Color(0xFF7FD1FF), // ice
    ],
  );

  /// Pale sky and bright blue.
  static const themeSky = GridwellPalette(
    brightness: Brightness.light,
    bg: Color(0xFFEFF5FB),
    sunk: Color(0xFFC9D8E8),
    surface: Color(0xFFE1EBF5),
    cell: Color(0xFFFBFDFF),
    track: Color(0xFFD3E0EE),
    tile: Color(0xFFDCE7F3),
    ink: Color(0xFF0F1D2E),
    ink2: Color(0xFF44566B),
    ink3: Color(0xFF93A4B8),
    rule: Color(0xFF34506E),
    mark: Color(0xFF6A7E95),
    outline: Color(0xFFA6B8CC),
    lime: Color(0xFF8CC8FF),
    onLime: Color(0xFF0B1A2B),
    accent: Color(0xFF1F5EA8),
    hl: Color(0x528CC8FF),
    error: Color(0xFFC8352B),
    onError: Color(0xFFFFFFFF),
    art: [
      Color(0x00000000),
      Color(0xFF0F1D2E), // navy ink
      Color(0xFFE2574C), // kite red
      Color(0xFFF2B13F), // sun
      Color(0xFF6A7E95), // cloud shadow
      Color(0xFF2C7BD8), // blue
    ],
  );

  /// Every theme's fixed palette, by theme id. The standard theme is not here:
  /// it is [light] or [dark], following the Light / Dark setting.
  static const themes = <String, GridwellPalette>{
    'paper': themePaper,
    'midnight': themeMidnight,
    'ink': themeInk,
    'ember': themeEmber,
    'blossom': themeBlossom,
    'violet': themeViolet,
    'sky': themeSky,
  };

  /// The palette for theme [id]. [brightness] (from System / Light / Dark)
  /// only picks between light and dark for the standard theme. An unknown id
  /// falls back to standard.
  static GridwellPalette forTheme(String id, Brightness brightness, {bool highContrast = false}) {
    final base = themes[id] ?? (brightness == Brightness.dark ? dark : light);
    return highContrast ? GridwellPalette.highContrast(base) : base;
  }
}
