import 'package:flutter/foundation.dart';

/// AdMob ad unit ids. Not secrets: they ship in the binary. Fill the real ids
/// from docs/MONETIZATION_IDS.md.
///
/// Debug builds always use Google's official test units (serving your own
/// real ads in development breaks AdMob policy). In a release build an empty
/// real id means that ad is simply not shown, never a test ad.
///
/// App ids live in the native manifests, not here.
abstract final class AdConfig {
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  // Google's official test units.
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';
  static const _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  // Real units: fill from docs/MONETIZATION_IDS.md.
  static const _rewardedAndroid = '';
  static const _rewardedIos = '';
  static const _interstitialAndroid = '';
  static const _interstitialIos = '';

  static String? _pick(String test, String real) =>
      kDebugMode ? test : (real.isEmpty ? null : real);

  /// Null when no real id is configured for a release build.
  static String? get rewardedUnitId =>
      _ios ? _pick(_testRewardedIos, _rewardedIos) : _pick(_testRewardedAndroid, _rewardedAndroid);

  static String? get interstitialUnitId => _ios
      ? _pick(_testInterstitialIos, _interstitialIos)
      : _pick(_testInterstitialAndroid, _interstitialAndroid);
}
