/// Where an ad is shown, for frequency rules and analytics.
enum AdPlacement { hint, revealLine, missedDaily, afterCompletion }

/// Swappable ad abstraction: networks or mediation can change without
/// touching game code. Implementations must fail quietly (an ad that cannot
/// load is simply not shown).
abstract interface class AdService {
  Future<void> initialize();

  /// Shows a rewarded video. Returns true only if the reward was earned.
  Future<bool> showRewarded(AdPlacement placement);

  /// Shows an interstitial if one is loaded. Frequency rules live in the
  /// caller (state layer), not here.
  Future<bool> showInterstitial(AdPlacement placement);

  bool get rewardedReady;
}

/// Grants every reward instantly. Used in tests and debug builds before the
/// ad SDK is configured.
class InstantRewardAds implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Future<bool> showRewarded(AdPlacement placement) async => true;

  @override
  Future<bool> showInterstitial(AdPlacement placement) async => false;

  @override
  bool get rewardedReady => true;
}
