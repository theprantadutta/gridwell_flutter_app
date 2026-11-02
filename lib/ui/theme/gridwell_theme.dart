import 'package:flutter/material.dart';

import 'palette.dart';
import 'typography.dart';

/// Makes the active [GridwellPalette] available to every widget.
class GridwellTheme extends ThemeExtension<GridwellTheme> {
  const GridwellTheme(this.palette);

  final GridwellPalette palette;

  @override
  GridwellTheme copyWith({GridwellPalette? palette}) =>
      GridwellTheme(palette ?? this.palette);

  @override
  GridwellTheme lerp(GridwellTheme? other, double t) =>
      t < 0.5 || other == null ? this : other;

  /// Material [ThemeData] built from a palette, so stock widgets (dialogs,
  /// text selection, scroll glow) match Folio.
  static ThemeData themeData(GridwellPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.textPrimary,
      onPrimary: p.onInk,
      secondary: p.accent,
      onSecondary: p.onInk,
      error: p.accent,
      onError: p.onInk,
      surface: p.surface,
      onSurface: p.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.surface,
      fontFamily: FolioType.family,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.highlight.withValues(alpha: 0.6),
        selectionHandleColor: p.accent,
      ),
      dividerColor: p.rule,
      extensions: [GridwellTheme(p)],
    );
  }
}

extension GridwellThemeContext on BuildContext {
  GridwellPalette get palette => Theme.of(this).extension<GridwellTheme>()!.palette;
}
