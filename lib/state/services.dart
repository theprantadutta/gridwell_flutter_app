import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads/ad_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/feedback/feedback_service.dart';
import 'providers.dart';

/// Swapped for the Firebase implementation in main().
final analyticsProvider = Provider<AnalyticsService>((ref) => MemoryAnalytics());

/// Swapped for the haptics + audio implementation in main().
final feedbackProvider = Provider<FeedbackService>((ref) => SilentFeedback());

/// What the player has bought. Local cache first; verified by the server
/// when online.
class Entitlements {
  const Entitlements({this.removeAds = false, this.premium = false});

  /// One-time purchase: no interstitials.
  final bool removeAds;

  /// Monthly or yearly subscription: everything.
  final bool premium;

  bool get noInterstitials => removeAds || premium;
}

/// Overridden in main() with the entitlements saved on this device.
final initialEntitlementsProvider = Provider<Entitlements>((ref) => const Entitlements());

class EntitlementsNotifier extends Notifier<Entitlements> {
  @override
  Entitlements build() => ref.watch(initialEntitlementsProvider);

  /// Updates and saves, so purchases hold across restarts with no network.
  void set(Entitlements value) {
    if (value.removeAds == state.removeAds && value.premium == state.premium) return;
    state = value;
    final repo = ref.read(settingsRepositoryProvider);
    final now = DateTime.now();
    repo.put('ent_remove_ads', '${value.removeAds}', now);
    repo.put('ent_premium', '${value.premium}', now);
  }
}

final entitlementsProvider =
    NotifierProvider<EntitlementsNotifier, Entitlements>(EntitlementsNotifier.new);

/// Swapped for the Google Mobile Ads implementation in main().
final adServiceProvider = Provider<AdService>((ref) => InstantRewardAds());
