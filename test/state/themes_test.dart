import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gridwell_flutter_app/data/local/app_database.dart';
import 'package:gridwell_flutter_app/state/monetization.dart';
import 'package:gridwell_flutter_app/state/online.dart';
import 'package:gridwell_flutter_app/state/providers.dart';
import 'package:gridwell_flutter_app/state/services.dart';
import 'package:gridwell_flutter_app/state/settings.dart';
import 'package:gridwell_flutter_app/state/themes.dart';
import 'package:gridwell_flutter_app/ui/theme/palette.dart';
import 'package:material_ui/material_ui.dart' show Brightness;

ProviderContainer _container({required String themeId, bool premium = false, Set<String> themes = const {}}) {
  final db = AppDatabase(NativeDatabase.memory());
  final c = ProviderContainer(overrides: [
    databaseProvider.overrideWithValue(db),
    initialSettingsProvider.overrideWithValue(Settings(themeId: themeId)),
    initialEntitlementsProvider.overrideWithValue(Entitlements(premium: premium, themes: themes)),
  ]);
  addTearDown(() async {
    c.dispose();
    await db.close();
  });
  return c;
}

void main() {
  group('catalog', () {
    test('the standard theme comes first and is free', () {
      expect(appThemes.first.id, standardThemeId);
      expect(appThemes.first.paid, isFalse);
    });

    test('ids are unique', () {
      final ids = appThemes.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every theme but the standard one has its own palette, and no palette is orphaned', () {
      final themed = appThemes.where((t) => t.id != standardThemeId).map((t) => t.id).toSet();
      expect(GridwellPalette.themes.keys.toSet(), themed);
    });

    test('Gridwell and Paper are free; the rest are sold', () {
      expect(themeById(standardThemeId).paid, isFalse);
      expect(themeById('paper').paid, isFalse);
      for (final id in ['midnight', 'blossom', 'ink', 'sky', 'ember', 'violet']) {
        expect(themeById(id).paid, isTrue, reason: id);
      }
      expect(paidThemeKeys, ['midnight', 'blossom', 'ink', 'sky', 'ember', 'violet']);
    });

    test('an unknown id falls back to the standard theme', () {
      expect(themeById('neon-from-a-newer-version').id, standardThemeId);
      expect(GridwellPalette.forTheme('neon-from-a-newer-version', Brightness.dark), GridwellPalette.dark);
    });

    test('the standard theme follows the brightness, other themes ignore it', () {
      expect(GridwellPalette.forTheme(standardThemeId, Brightness.light), GridwellPalette.light);
      expect(GridwellPalette.forTheme(standardThemeId, Brightness.dark), GridwellPalette.dark);
      expect(GridwellPalette.forTheme('midnight', Brightness.light), GridwellPalette.themeMidnight);
      expect(GridwellPalette.forTheme('paper', Brightness.dark), GridwellPalette.themePaper);
    });

    test('high contrast applies to themes too', () {
      final hc = GridwellPalette.forTheme('ember', Brightness.light, highContrast: true);
      expect(hc.ink3, GridwellPalette.themeEmber.ink2);
      expect(hc.majorRuleWidth, 2);
    });
  });

  group('store products', () {
    test('every theme has a product id, matched both ways (Play ids are bare)', () {
      for (final key in [...paidThemeKeys, ProductIds.themeBundleKey]) {
        expect(ProductIds.themeKeyOf(ProductIds.theme(key)), key);
      }
      expect(ProductIds.theme('midnight'), 'theme_midnight');
      expect(ProductIds.themeBundle, 'theme_bundle');
    });

    test('App Store ids (bundle-prefixed) map to themes too', () {
      expect(ProductIds.themeKeyOf('com.pranta.gridwell.theme_ember'), 'ember');
      expect(ProductIds.themeKeyOf('com.pranta.gridwell.theme_bundle'), 'bundle');
    });

    test('other products are not themes', () {
      for (final id in ['remove_ads', 'premium_monthly', 'com.pranta.gridwell.premium_yearly', 'theme_', 'atheme_x']) {
        expect(ProductIds.themeKeyOf(id), isNull, reason: id);
      }
    });

    test("the server's list replaces the device's (it sees refunds)", () {
      final c = _container(themeId: 'ink', themes: {'ink', 'ember'});
      c.read(onlineSessionProvider).applyEntitlements({
        'remove_ads': false,
        'premium': {'active': false},
        'themes': ['ember'],
      });
      expect(c.read(entitlementsProvider).themes, {'ember'});
      expect(c.read(activeThemeProvider).id, standardThemeId);
    });

    test('an older server that sends no themes leaves the device list alone', () {
      final c = _container(themeId: 'ink', themes: {'ink'});
      c.read(onlineSessionProvider).applyEntitlements({'remove_ads': true, 'premium': {'active': false}});
      expect(c.read(entitlementsProvider).themes, {'ink'});
      expect(c.read(entitlementsProvider).removeAds, isTrue);
    });

    test('owned themes are stored as a sorted list and read back', () {
      expect(Entitlements.encodeThemes({'midnight', 'ember'}), 'ember,midnight');
      expect(Entitlements.decodeThemes('ember,midnight'), {'ember', 'midnight'});
      expect(Entitlements.decodeThemes(''), isEmpty);
      expect(Entitlements.decodeThemes(null), isEmpty);
    });
  });

  group('settings', () {
    test('theme_id round-trips and defaults to standard', () {
      expect(const Settings().themeId, standardThemeId);
      expect(Settings.fromMap(const {}).themeId, standardThemeId);
      final s = const Settings().copyWith(themeId: 'ink');
      expect(Settings.fromMap(s.toMap()).themeId, 'ink');
    });

    test('theme_id follows the account and is logged as a player choice', () {
      expect(syncedSettingKeys, contains('theme_id'));
      expect(playerSettingKeys, contains('theme_id'));
    });
  });

  group('who sees which theme', () {
    test('anyone can use a free theme', () {
      expect(_container(themeId: 'paper', premium: false).read(activeThemeProvider).id, 'paper');
    });

    test('Premium players see their Premium theme', () {
      expect(_container(themeId: 'midnight', premium: true).read(activeThemeProvider).id, 'midnight');
    });

    test('without Premium a Premium pick shows the standard theme, and the pick is kept', () {
      final c = _container(themeId: 'midnight', premium: false);
      expect(c.read(activeThemeProvider).id, standardThemeId);
      expect(c.read(settingsProvider).themeId, 'midnight');
    });

    test('the theme comes back when Premium does, and goes when it lapses', () {
      final c = _container(themeId: 'blossom', premium: false);
      expect(c.read(activeThemeProvider).id, standardThemeId);
      c.read(entitlementsProvider.notifier).set(const Entitlements(premium: true));
      expect(c.read(activeThemeProvider).id, 'blossom');
      c.read(entitlementsProvider.notifier).set(const Entitlements());
      expect(c.read(activeThemeProvider).id, standardThemeId);
    });

    test('a paid theme is unlocked by buying it, the bundle, or Premium', () {
      final ink = themeById('ink');
      expect(canUseTheme(ink, const Entitlements()), isFalse);
      expect(canUseTheme(ink, const Entitlements(themes: {'ink'})), isTrue);
      expect(canUseTheme(ink, const Entitlements(themes: {'midnight'})), isFalse);
      expect(canUseTheme(ink, const Entitlements(themes: {'bundle'})), isTrue);
      expect(canUseTheme(ink, const Entitlements(premium: true)), isTrue);
      expect(canUseTheme(ink, const Entitlements(removeAds: true)), isFalse);
      expect(canUseTheme(themeById('paper'), const Entitlements()), isTrue);
    });

    test('a theme bought on its own stays when Premium lapses', () {
      final c = _container(themeId: 'ember', premium: true, themes: {'ember'});
      c.read(entitlementsProvider.notifier).set(const Entitlements(themes: {'ember'}));
      expect(c.read(activeThemeProvider).id, 'ember');
    });

    test('a refunded theme goes, and comes back if bought again', () {
      final c = _container(themeId: 'ink', themes: {'ink'});
      expect(c.read(activeThemeProvider).id, 'ink');
      c.read(entitlementsProvider.notifier).set(const Entitlements());
      expect(c.read(activeThemeProvider).id, standardThemeId);
      c.read(entitlementsProvider.notifier).set(const Entitlements(themes: {'bundle'}));
      expect(c.read(activeThemeProvider).id, 'ink');
    });
  });
}
