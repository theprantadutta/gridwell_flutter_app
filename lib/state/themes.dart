import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services.dart';
import 'settings.dart';

/// One look the player can pick in Settings > Look > Theme. The colors live in
/// the UI layer (`GridwellPalette.forTheme`); this is what state needs to know:
/// the id that is stored, the name that is shown and who may use it.
class ThemeInfo {
  const ThemeInfo({
    required this.id,
    required this.name,
    required this.tagline,
    this.paid = false,
  });

  /// Stored in settings as `theme_id` and synced with the account.
  final String id;
  final String name;

  /// A few words under the name in the theme list.
  final String tagline;

  /// Sold in the stores (one by one, in the All themes bundle) and included
  /// with Premium. Anyone can preview it first.
  final bool paid;
}

/// The standard Tally look. It alone follows System / Light / Dark; every
/// other theme is one fixed look.
const standardThemeId = 'standard';

/// In the order the theme list shows them.
const appThemes = [
  ThemeInfo(id: standardThemeId, name: 'Gridwell', tagline: 'The classic. Follows light and dark'),
  ThemeInfo(id: 'paper', name: 'Paper', tagline: 'Warm cream and marigold'),
  ThemeInfo(id: 'midnight', name: 'Midnight', tagline: 'Deep navy and aqua', paid: true),
  ThemeInfo(id: 'blossom', name: 'Blossom', tagline: 'Soft pink and plum', paid: true),
  ThemeInfo(id: 'ink', name: 'Ink', tagline: 'True black, white and yellow', paid: true),
  ThemeInfo(id: 'sky', name: 'Sky', tagline: 'Pale sky and bright blue', paid: true),
  ThemeInfo(id: 'ember', name: 'Ember', tagline: 'Warm charcoal and orange', paid: true),
  ThemeInfo(id: 'violet', name: 'Violet', tagline: 'Deep violet and lavender', paid: true),
];

/// The theme for [id], or the standard one for an id this build does not know
/// (a newer version synced it, or it was retired).
ThemeInfo themeById(String id) =>
    appThemes.firstWhere((t) => t.id == id, orElse: () => appThemes.first);

/// The keys of every paid theme: the store products this build sells.
List<String> get paidThemeKeys => [for (final t in appThemes) if (t.paid) t.id];

/// Whether a player with [ent] may use [theme]: it is free, bought (alone or
/// in the bundle), or included with Premium.
bool canUseTheme(ThemeInfo theme, Entitlements ent) => !theme.paid || ent.ownsTheme(theme.id);

/// The theme on screen: the one the player picked, unless it is a paid theme
/// they no longer have (Premium lapsed, or a purchase was refunded). The pick
/// itself is kept, so the theme comes back on its own if they get it again.
final activeThemeProvider = Provider<ThemeInfo>((ref) {
  final picked = themeById(ref.watch(settingsProvider.select((s) => s.themeId)));
  final ent = ref.watch(entitlementsProvider);
  return canUseTheme(picked, ent) ? picked : appThemes.first;
});
