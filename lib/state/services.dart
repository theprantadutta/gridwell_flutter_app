import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads/ad_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/crash/crash_reporter.dart';
import '../services/feedback/feedback_service.dart';
import 'providers.dart';

/// Swapped for the Firebase implementation in main().
final analyticsProvider = Provider<AnalyticsService>((ref) => MemoryAnalytics());

/// Swapped for Crashlytics in main() (release builds only).
final crashReporterProvider = Provider<CrashReporter>((ref) => const NoopCrashReporter());

/// Swapped for the haptics + audio implementation in main().
final feedbackProvider = Provider<FeedbackService>((ref) => SilentFeedback());

/// What the player has bought. Local cache first; verified by the server
/// when online.
class Entitlements {
  const Entitlements({this.removeAds = false, this.premium = false, this.themes = const {}});

  /// One-time purchase: no interstitials.
  final bool removeAds;

  /// Monthly or yearly subscription: everything.
  final bool premium;

  /// Themes bought one by one, by theme key. "bundle" is the All themes
  /// product (every paid theme, now and later).
  final Set<String> themes;

  bool get noInterstitials => removeAds || premium;

  /// Whether the paid theme [key] is unlocked: bought on its own, bought in
  /// the bundle, or included with Premium.
  bool ownsTheme(String key) => premium || themes.contains(key) || themes.contains('bundle');

  Entitlements copyWith({bool? removeAds, bool? premium, Set<String>? themes}) => Entitlements(
        removeAds: removeAds ?? this.removeAds,
        premium: premium ?? this.premium,
        themes: themes ?? this.themes,
      );

  /// Stored as a sorted, comma-separated list (`ent_themes`).
  static String encodeThemes(Set<String> themes) => (themes.toList()..sort()).join(',');
  static Set<String> decodeThemes(String? raw) =>
      raw == null || raw.isEmpty ? const {} : raw.split(',').where((t) => t.isNotEmpty).toSet();
}

/// Overridden in main() with the entitlements saved on this device.
final initialEntitlementsProvider = Provider<Entitlements>((ref) => const Entitlements());

class EntitlementsNotifier extends Notifier<Entitlements> {
  @override
  Entitlements build() => ref.watch(initialEntitlementsProvider);

  /// Updates and saves, so purchases hold across restarts with no network.
  void set(Entitlements value) {
    final themes = Entitlements.encodeThemes(value.themes);
    if (value.removeAds == state.removeAds &&
        value.premium == state.premium &&
        themes == Entitlements.encodeThemes(state.themes)) {
      return;
    }
    state = value;
    final repo = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    repo.put('ent_remove_ads', '${value.removeAds}', now);
    repo.put('ent_premium', '${value.premium}', now);
    repo.put('ent_themes', themes, now);
  }
}

final entitlementsProvider =
    NotifierProvider<EntitlementsNotifier, Entitlements>(EntitlementsNotifier.new);

/// Swapped for the Google Mobile Ads implementation in main().
final adServiceProvider = Provider<AdService>((ref) => InstantRewardAds());
