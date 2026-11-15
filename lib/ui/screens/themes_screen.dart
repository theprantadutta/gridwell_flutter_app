import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../engine/model/board.dart';
import '../../engine/model/cell_state.dart';
import '../../engine/model/puzzle.dart';
import '../../state/monetization.dart';
import '../../state/providers.dart';
import '../../state/services.dart';
import '../../state/settings.dart';
import '../../state/themes.dart';
import '../board/board_geometry.dart';
import '../board/board_painter.dart';
import '../theme/gridwell_theme.dart';
import '../theme/palette.dart';
import '../theme/typography.dart';
import '../widgets/gridwell_mark.dart';
import '../widgets/plate_thumb.dart';
import '../widgets/tally.dart';

/// The palette a theme card or preview is drawn in. The standard theme shows
/// the light or dark look the Light or dark setting would give it now, even
/// while another theme is on screen.
GridwellPalette _paletteFor(BuildContext context, ThemeInfo theme, ThemeMode mode) {
  final fixed = GridwellPalette.themes[theme.id];
  if (fixed != null) return fixed;
  final dark = switch (mode) {
    ThemeMode.dark => true,
    ThemeMode.light => false,
    ThemeMode.system => MediaQuery.platformBrightnessOf(context) == Brightness.dark,
  };
  return GridwellPalette.of(dark ? Brightness.dark : Brightness.light);
}

/// Purchases and restores say how they went at the foot of the screen.
void _toastStoreMessages(BuildContext context, WidgetRef ref) {
  ref.listen(purchaseControllerProvider.select((s) => s.message), (previous, message) {
    if (message != null && message != previous) tallyToast(context, message);
  });
}

/// Settings > Look > Theme: every theme as a slab drawn in its own colors.
/// Tapping one the player has switches to it; tapping a paid theme they do
/// not have opens its preview, where it can be bought.
class ThemesScreen extends ConsumerWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final active = ref.watch(activeThemeProvider);
    final ent = ref.watch(entitlementsProvider);
    final store = ref.watch(purchaseControllerProvider);
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    _toastStoreMessages(context, ref);
    final locked = [for (final t in appThemes) if (!canUseTheme(t, ent)) t];
    final bundlePrice = store.prices[ProductIds.themeBundle];
    final buyingBundle = store.busy == ProductIds.themeBundle;

    void pick(ThemeInfo theme) {
      if (!canUseTheme(theme, ent)) {
        context.push('/themes/preview/${theme.id}');
        return;
      }
      if (theme.id == active.id) return;
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(themeId: theme.id));
      tallyToast(context, '${theme.name} is on.');
    }

    return Scaffold(
      body: TallyBody(
        bottom: locked.isEmpty,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const TallyTopBar(title: 'Theme'),
          Expanded(
            child: ListView(padding: const EdgeInsets.only(bottom: 16), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 18),
                child: Text(
                  locked.isEmpty
                      ? 'Every theme is yours. The board, the clues and the pictures all change with it.'
                      : 'The board, the clues and the pictures all change with the theme. '
                          'Tap one to try it on before you buy it.',
                  style: TallyType.prose(p.ink2, size: 15),
                ),
              ),
              ColoredBox(
                color: p.sunk,
                child: Column(children: [
                  for (final (i, theme) in appThemes.indexed) ...[
                    if (i > 0) const SizedBox(height: tallyDivider),
                    _ThemeCard(
                      theme: theme,
                      palette: _paletteFor(context, theme, mode),
                      active: theme.id == active.id,
                      status: theme.id == active.id
                          ? 'In use'
                          : !canUseTheme(theme, ent)
                              ? (store.prices[ProductIds.theme(theme.id)] ?? 'Locked')
                              : !theme.paid && locked.isNotEmpty
                                  ? 'Free'
                                  : null,
                      onTap: () => pick(theme),
                    ),
                  ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(tallyMargin, 16, tallyMargin, 0),
                child: Text(
                  active.id == standardThemeId
                      ? 'Gridwell follows the Light and Dark setting. Other themes have one look each.'
                      : '${active.name} has one look. Pick Gridwell to follow Light and Dark again.',
                  style: TallyType.label(p.ink2).copyWith(fontSize: 13, height: 1.35),
                ),
              ),
              if (locked.isNotEmpty && bundlePrice != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: _TextLink(
                    label: 'Or get every theme with Premium',
                    onTap: () => context.push('/store'),
                  ),
                ),
            ]),
          ),
          if (locked.isNotEmpty)
            bundlePrice != null
                ? PrimarySlab(
                    label: buyingBundle ? 'Opening the store…' : 'All themes · $bundlePrice',
                    sublabel: 'Every theme, now and later. Yours to keep',
                    height: 88,
                    onPressed: store.busy == null
                        ? () => ref.read(purchaseControllerProvider.notifier).buy(ProductIds.themeBundle)
                        : null,
                  )
                : PrimarySlab(
                    label: 'Unlock every theme',
                    sublabel: 'Included with Gridwell Premium',
                    height: 88,
                    onPressed: () => context.push('/store'),
                  ),
        ]),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 14),
          child: Text(
            label,
            style: TallyType.label(p.ink2).copyWith(fontSize: 14, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }
}

/// One theme, drawn in its own palette: the mark, the name, a strip of its
/// picture colors and its status (in use, its price, or free).
class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.theme,
    required this.palette,
    required this.active,
    required this.status,
    required this.onTap,
  });

  final ThemeInfo theme;
  final GridwellPalette palette;
  final bool active;
  final String? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: GridwellTheme.themeData(palette),
      child: Builder(builder: (context) {
        final p = context.palette;
        return Pressable(
          color: p.bg,
          onTap: onTap,
          selected: active,
          semanticLabel: [theme.name, theme.tagline, ?status].join('. '),
          child: Container(
            constraints: const BoxConstraints(minHeight: 108),
            padding: const EdgeInsets.fromLTRB(tallyMargin, 18, tallyMargin, 18),
            child: Row(children: [
              // The card's own label names the theme; the mark would only
              // repeat "Gridwell" on every card.
              const ExcludeSemantics(child: GridwellMark(size: 52)),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(theme.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TallyType.titleS(p.ink)),
                  const SizedBox(height: 4),
                  Text(theme.tagline, style: TallyType.label(p.ink2).copyWith(fontSize: 13, height: 1.25)),
                  const SizedBox(height: 10),
                  _ArtStrip(palette: p),
                ]),
              ),
              if (status case final status?) ...[const SizedBox(width: 12), _StatusChip(label: status, filled: active)],
            ]),
          ),
        );
      }),
    );
  }
}

/// The theme's picture colors as a row of small squares.
class _ArtStrip extends StatelessWidget {
  const _ArtStrip({required this.palette});

  final GridwellPalette palette;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Row(children: [
          for (final c in palette.art.skip(1)) ...[
            Container(width: 12, height: 12, color: c),
            const SizedBox(width: 4),
          ],
          Container(width: 12, height: 12, color: palette.lime),
        ]),
      );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.filled});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? p.lime : null,
        border: filled ? null : Border.all(color: p.outline, width: 1.5),
      ),
      child: Text(
        label.toUpperCase(),
        style: TallyType.overline(filled ? p.onLime : p.ink2).copyWith(fontSize: 11, height: 1),
      ),
    );
  }
}

/// A theme tried on before buying: a board mid-solve, a few solved pictures
/// and the controls, all in the theme's colors. Nothing changes until the
/// player buys it (or uses one they have); a purchase made here switches to
/// the theme as soon as it goes through.
class ThemePreviewScreen extends ConsumerWidget {
  const ThemePreviewScreen({super.key, required this.themeId});

  final String themeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = themeById(themeId);
    final palette = _paletteFor(context, theme, ref.watch(settingsProvider.select((s) => s.themeMode)));
    final ent = ref.watch(entitlementsProvider);
    final usable = canUseTheme(theme, ent);
    final store = ref.watch(purchaseControllerProvider);
    final buy = ref.read(purchaseControllerProvider.notifier).buy;
    final themePrice = store.prices[ProductIds.theme(theme.id)];
    final bundlePrice = store.prices[ProductIds.themeBundle];
    final idle = store.busy == null;
    _toastStoreMessages(context, ref);

    void use() {
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(themeId: theme.id));
      Navigator.of(context).maybePop();
    }

    // Bought here (alone, in the bundle or with Premium): put it on.
    ref.listen(entitlementsProvider, (before, after) {
      if (before != null && !canUseTheme(theme, before) && canUseTheme(theme, after)) {
        tallyToast(context, '${theme.name} is yours, and it is on.');
        use();
      }
    });

    final set = ref.watch(puzzleSetProvider);
    PuzzleRecord? find(String id) {
      for (final p in set.puzzles) {
        if (p.id == id) return p;
      }
      return null;
    }

    final board = find('coastline-rowboat') ?? set.puzzles.firstWhere((p) => p.width == 10);
    final pictures = [
      for (final id in ['coastline-lighthouse', 'coastline-umbrella', 'coastline-fishing-boat'])
        ?find(id),
    ];

    return Theme(
      data: GridwellTheme.themeData(palette),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: tallyOverlay(palette.isDark),
        child: Builder(builder: (context) {
          final p = context.palette;
          return Scaffold(
            backgroundColor: p.bg,
            body: TallyBody(
              bottom: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                TallyTopBar(title: theme.name, chip: 'Preview'),
                Expanded(
                  child: ListView(padding: const EdgeInsets.only(bottom: 20), children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(tallyMargin, 14, tallyMargin, 18),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Overline(
                          !theme.paid
                              ? 'Free theme'
                              : usable
                                  ? 'Yours'
                                  : 'Buy once, keep it',
                          color: p.accent,
                        ),
                        const SizedBox(height: 8),
                        Text(theme.tagline, style: TallyType.prose(p.ink2, size: 16)),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                      child: _SampleBoard(puzzle: board),
                    ),
                    const SizedBox(height: 22),
                    if (pictures.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                        child: Row(children: [
                          for (final (i, picture) in pictures.indexed) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: PlateThumb(puzzle: picture, state: PlateState.solved, background: p.tile),
                              ),
                            ),
                          ],
                        ]),
                      ),
                    const SizedBox(height: 22),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                      child: Row(children: [
                        Text('Coastline', style: TallyType.body(p.accent).copyWith(fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('18/30', style: TallyType.body(p.ink).copyWith(fontWeight: FontWeight.w800)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: tallyMargin),
                      child: ProgressTicks(total: 30, done: {for (var i = 0; i < 18; i++) i}),
                    ),
                  ]),
                ),
                if (!usable)
                  // The other ways in: every theme at once, or Premium.
                  SlabRow(height: 54, children: [
                    if (bundlePrice != null)
                      SlabButton(
                        label: 'All themes · $bundlePrice',
                        onPressed: idle ? () => buy(ProductIds.themeBundle) : null,
                        enabled: idle,
                      ),
                    SlabButton(label: 'Get Premium', onPressed: () => context.push('/store')),
                  ]),
                if (usable)
                  PrimarySlab(label: 'Use ${theme.name}', onPressed: use)
                else if (themePrice != null)
                  PrimarySlab(
                    label: store.busy == ProductIds.theme(theme.id) ? 'Opening the store…' : 'Buy ${theme.name}',
                    sublabel: '$themePrice once. Yours to keep',
                    onPressed: idle ? () => buy(ProductIds.theme(theme.id)) : null,
                  )
                else
                  PrimarySlab(
                    label: 'Get Premium',
                    sublabel: 'Every theme, unlimited hints, no ads',
                    onPressed: () => context.push('/store'),
                  ),
              ]),
            ),
          );
        }),
      ),
    );
  }
}

/// A board part way through: the top rows solved (filled and crossed), the
/// rest untouched, with the cursor's row and column lit.
class _SampleBoard extends StatelessWidget {
  const _SampleBoard({required this.puzzle});

  final PuzzleRecord puzzle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final w = puzzle.width, h = puzzle.height;
    final solvedRows = (h * 0.6).round();
    final cells = [
      for (var i = 0; i < puzzle.solution.cellCount; i++)
        i ~/ w < solvedRows
            ? (puzzle.solution.cells[i] ? CellState.filled : CellState.crossed)
            : CellState.empty,
    ];
    final board = Board(w, h, cells);
    final none = [for (var i = 0; i < h; i++) <int>{}];
    final noneCols = [for (var i = 0; i < w; i++) <int>{}];
    return LayoutBuilder(builder: (context, c) {
      final g = BoardGeometry.fit(puzzle.clues, Size(c.maxWidth, c.maxWidth));
      return ExcludeSemantics(
        child: Center(
          child: SizedBox.fromSize(
            size: g.totalSize,
            child: CustomPaint(
              painter: GridPainter(
                geometry: g,
                board: board,
                palette: p,
                mistakes: const {},
                cursorRow: solvedRows,
                cursorCol: w ~/ 2,
              ),
              foregroundPainter: CluePainter(
                geometry: g,
                clues: puzzle.clues,
                palette: p,
                rowRetired: none,
                colRetired: noneCols,
              ),
            ),
          ),
        ),
      );
    });
  }
}
