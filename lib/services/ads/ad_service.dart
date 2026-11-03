/// Where an ad is shown, for frequency rules and analytics.
enum AdPlacement { hint, revealLine, missedDaily, afterCompletion }

/// What happened with a rewarded interstitial.
enum RewardedInterstitialOutcome { earned, notEarned, unavailable }

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

  /// Rewarded interstitial: offered between puzzles behind an intro screen
  /// (shown by the caller, as Google requires). Never shown without one.
  bool get rewardedInterstitialReady;

  Future<RewardedInterstitialOutcome> showRewardedInterstitial(AdPlacement placement);

  /// True where the player must be able to revisit their ad consent (EEA/UK).
  Future<bool> privacyOptionsRequired();

  /// Reopens the consent form.
  Future<void> showPrivacyOptions();
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

  @override
  bool get rewardedInterstitialReady => false;

  @override
  Future<RewardedInterstitialOutcome> showRewardedInterstitial(AdPlacement placement) async =>
      RewardedInterstitialOutcome.unavailable;

  @override
  Future<bool> privacyOptionsRequired() async => false;

  @override
  Future<void> showPrivacyOptions() async {}
}
