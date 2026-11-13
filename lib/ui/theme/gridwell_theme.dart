import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'typography.dart';

/// Makes the active [GridwellPalette] available to every widget.
class GridwellTheme extends ThemeExtension<GridwellTheme> {
  const GridwellTheme(this.palette);

  final GridwellPalette palette;

  @override
  GridwellTheme copyWith({GridwellPalette? palette}) => GridwellTheme(palette ?? this.palette);

  @override
  GridwellTheme lerp(GridwellTheme? other, double t) => t < 0.5 || other == null ? this : other;

  /// Material [ThemeData] built from a palette, so stock widgets (dialogs,
  /// snack bars, text selection) match Tally: square corners, no ripples.
  static ThemeData themeData(GridwellPalette p) {
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.lime,
      onPrimary: p.onLime,
      secondary: p.accent,
      onSecondary: p.onLime,
      error: p.error,
      onError: p.onError,
      surface: p.bg,
      onSurface: p.ink,
    );
    const square = RoundedRectangleBorder();
    return ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.bg,
      fontFamily: TallyType.family,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.accent,
        selectionColor: p.lime.withValues(alpha: 0.45),
        selectionHandleColor: p.accent,
      ),
      dividerColor: p.sunk,
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: square,
        titleTextStyle: TallyType.titleS(p.ink),
        contentTextStyle: TallyType.prose(p.ink2),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.ink,
        contentTextStyle: TallyType.body(p.bg),
        actionTextColor: p.lime,
        shape: square,
        behavior: SnackBarBehavior.fixed,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        modalBackgroundColor: p.surface,
        shape: square,
        showDragHandle: false,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: p.ink, shape: square, textStyle: TallyType.body(p.ink)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cell,
        border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: p.outline, width: 1.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: p.outline, width: 1.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: p.accent, width: 2)),
        labelStyle: TallyType.label(p.ink2),
        hintStyle: TallyType.body(p.ink3),
      ),
      extensions: [GridwellTheme(p)],
    );
  }
}

extension GridwellThemeContext on BuildContext {
  GridwellPalette get palette => Theme.of(this).extension<GridwellTheme>()!.palette;
}

/// System bar style for a page: transparent bars (the app draws edge to
/// edge) with icons that read on the theme's page color.
SystemUiOverlayStyle tallyOverlay(bool dark) =>
    (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    );
