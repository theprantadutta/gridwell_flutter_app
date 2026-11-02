
import 'package:flutter/painting.dart';

import 'palette.dart';

/// Folio type: Literata for everything, lining tabular figures for every
/// number so clues, timers and counts line up in columns.
///
/// Literata is a variable font with weight and optical-size axes. Optical size
/// follows the font size, which gives small clue numbers sturdier strokes.
abstract final class FolioType {
  static const family = 'Literata';

  static const figures = [FontFeature.tabularFigures(), FontFeature.liningFigures()];

  static TextStyle style({
    required double size,
    required Color color,
    double weight = 400,
    bool italic = false,
    double letterSpacing = 0,
    double? height,
  }) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        color: color,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        fontWeight: _nearestWeight(weight),
        fontVariations: [
          FontVariation('wght', weight),
          FontVariation('opsz', size.clamp(7, 72).toDouble()),
        ],
        fontFeatures: figures,
        letterSpacing: letterSpacing,
        height: height,
      );

  static FontWeight _nearestWeight(double w) =>
      FontWeight.values[((w / 100).round() - 1).clamp(0, 8)];

  /// Screen titles: "Contents", "Gallery".
  static TextStyle display(GridwellPalette p) =>
      style(size: 44, color: p.textPrimary, height: 1.05);

  /// Plate name on the board and the completion page.
  static TextStyle plateTitle(GridwellPalette p, {double size = 40}) =>
      style(size: size, color: p.textPrimary, weight: 500, height: 1.05);

  /// Small capitals in accent: "NO. 6", "TODAY · SUNDAY 1 NOVEMBER".
  static TextStyle kicker(GridwellPalette p, {Color? color}) =>
      style(size: 12.5, color: color ?? p.accent, weight: 600, letterSpacing: 3);

  /// Brand wordmark in the header: "GRIDWELL".
  static TextStyle wordmark(GridwellPalette p) =>
      style(size: 13, color: p.textPrimary, weight: 600, letterSpacing: 4);

  /// Header bar text: "‹ Contents", "Coastline", "6:18".
  static TextStyle header(GridwellPalette p) =>
      style(size: 17, color: p.textMuted, italic: true);

  static TextStyle body(GridwellPalette p, {double size = 17}) =>
      style(size: size, color: p.textPrimary, height: 1.35);

  static TextStyle bodyMuted(GridwellPalette p, {double size = 16}) =>
      style(size: size, color: p.textMuted, italic: true, height: 1.35);

  static TextStyle button(Color color, {double size = 18}) =>
      style(size: size, color: color, weight: 600);

  static TextStyle tab(Color color, {bool selected = false}) =>
      style(size: 17, color: color, weight: selected ? 500 : 400);

  /// Clue numbers. Weight goes up a step for small sizes.
  static TextStyle clue(Color color, double size) =>
      style(size: size, color: color, weight: size < 12 ? 650 : 600, height: 1);
}
