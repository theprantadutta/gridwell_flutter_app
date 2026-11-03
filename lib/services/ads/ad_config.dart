import 'package:flutter/foundation.dart';

/// AdMob ad unit ids. Not secrets: they ship in the binary. Fill the real ids
/// from ADMOB_IDS_TEMPLATE.txt.
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
  static const _testRewardedInterstitialAndroid = 'ca-app-pub-3940256099942544/5354046379';
  static const _testRewardedInterstitialIos = 'ca-app-pub-3940256099942544/6978759866';

  // Real units, from ADMOB_IDS_TEMPLATE.txt.
  static const _rewardedAndroid = 'ca-app-pub-9242904787767394/3986947003';
  static const _rewardedIos = 'ca-app-pub-9242904787767394/5339110017';
  static const _interstitialAndroid = 'ca-app-pub-9242904787767394/3718694550';
  static const _interstitialIos = 'ca-app-pub-9242904787767394/9577525894';
  static const _rewardedInterstitialAndroid = 'ca-app-pub-9242904787767394/6421538657';
  static const _rewardedInterstitialIos = 'ca-app-pub-9242904787767394/5108456984';

  static String? _pick(String test, String real) =>
      kDebugMode ? test : (real.isEmpty ? null : real);

  /// Null when no real id is configured for a release build.
  static String? get rewardedUnitId =>
      _ios ? _pick(_testRewardedIos, _rewardedIos) : _pick(_testRewardedAndroid, _rewardedAndroid);

  static String? get rewardedInterstitialUnitId => _ios
      ? _pick(_testRewardedInterstitialIos, _rewardedInterstitialIos)
      : _pick(_testRewardedInterstitialAndroid, _rewardedInterstitialAndroid);

  static String? get interstitialUnitId => _ios
      ? _pick(_testInterstitialIos, _interstitialIos)
      : _pick(_testInterstitialAndroid, _interstitialAndroid);
}
