import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';
import 'ad_service.dart';
import '../crash/crash_reporter.dart';

/// AdMob behind [AdService]: rewarded and interstitial only (no banners).
///
/// Consent is asked just before the first ad, never at launch: Google's UMP
/// form for EEA/UK players, then (iOS) App Tracking Transparency. Ads are
/// preloaded once consent allows it.
///
/// If no rewarded ad can be shown (offline, no fill, no id configured), the
/// reward is granted anyway: the game must stay fully playable without a
/// connection. [onUnavailableGrant] reports how often that happens.
class GoogleAdService implements AdService {
  GoogleAdService({this.onUnavailableGrant});

  final void Function(AdPlacement)? onUnavailableGrant;

  RewardedAd? _rewarded;
  RewardedInterstitialAd? _rewardedInterstitial;
  InterstitialAd? _interstitial;
  bool _sdkReady = false;
  bool _consentDone = false;
  bool _canRequestAds = false;
  Future<void>? _consentFlow;

  @override
  Future<void> initialize() async {
    try {
      // Refresh consent status quietly; the form itself waits for the first ad.
      final c = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () => c.complete(),
        (_) => c.complete(),
      );
      await c.future.timeout(const Duration(seconds: 6), onTimeout: () {});
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
      if (_canRequestAds) await _startSdk();
    } catch (e, st) {
      CrashReports.instance.recordError(e, st, reason: 'ads init');
      debugPrint('ads init failed: $e');
    }
  }

  Future<void> _startSdk() async {
    if (_sdkReady) return;
    await MobileAds.instance.initialize();
    _sdkReady = true;
    _loadRewarded();
    _loadRewardedInterstitial();
    _loadInterstitial();
  }

  void _loadRewardedInterstitial() {
    final id = AdConfig.rewardedInterstitialUnitId;
    if (id == null || !_sdkReady || _rewardedInterstitial != null) return;
    RewardedInterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewardedInterstitial = ad,
        onAdFailedToLoad: (_) => _rewardedInterstitial = null,
      ),
    );
  }

  /// UMP form if required (EEA/UK), then ATT on iOS. Runs once per session.
  Future<void> _ensureConsent() => _consentFlow ??= () async {
        try {
          final c = Completer<void>();
          ConsentForm.loadAndShowConsentFormIfRequired((_) => c.complete());
          await c.future.timeout(const Duration(seconds: 30), onTimeout: () {});
          _canRequestAds = await ConsentInformation.instance.canRequestAds();
          if (defaultTargetPlatform == TargetPlatform.iOS &&
              await AppTrackingTransparency.trackingAuthorizationStatus == TrackingStatus.notDetermined) {
            await AppTrackingTransparency.requestTrackingAuthorization();
          }
          if (_canRequestAds) await _startSdk();
        } catch (e) {
          debugPrint('consent flow failed: $e');
        } finally {
          _consentDone = true;
        }
      }();

  void _loadRewarded() {
    final id = AdConfig.rewardedUnitId;
    if (id == null || !_sdkReady || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: id,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (_) => _rewarded = null,
      ),
    );
  }

  void _loadInterstitial() {
    final id = AdConfig.interstitialUnitId;
    if (id == null || !_sdkReady || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: id,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (_) => _interstitial = null,
      ),
    );
  }

  /// Waits up to [timeout] for a rewarded ad that is still loading.
  Future<RewardedAd?> _awaitRewarded(Duration timeout) async {
    _loadRewarded();
    final end = DateTime.now().add(timeout);
    while (_rewarded == null && DateTime.now().isBefore(end)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return _rewarded;
  }

  @override
  bool get rewardedReady => _rewarded != null;

  int _freeGrants = 0;

  @override
  int get freeGrants => _freeGrants;

  @override
  bool get rewardedInterstitialReady => _rewardedInterstitial != null;

  @override
  Future<RewardedInterstitialOutcome> showRewardedInterstitial(AdPlacement placement) async {
    final ad = _rewardedInterstitial;
    if (ad == null) {
      _loadRewardedInterstitial();
      return RewardedInterstitialOutcome.unavailable;
    }
    _rewardedInterstitial = null;
    final done = Completer<RewardedInterstitialOutcome>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) {
          done.complete(earned ? RewardedInterstitialOutcome.earned : RewardedInterstitialOutcome.notEarned);
        }
        _loadRewardedInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!done.isCompleted) done.complete(RewardedInterstitialOutcome.unavailable);
        _loadRewardedInterstitial();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  @override
  Future<bool> privacyOptionsRequired() async {
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showPrivacyOptions() async {
    final c = Completer<void>();
    try {
      ConsentForm.showPrivacyOptionsForm((_) => c.complete());
      await c.future.timeout(const Duration(seconds: 60), onTimeout: () {});
      _canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (e) {
      debugPrint('privacy options failed: $e');
    }
  }

  @override
  Future<bool> showRewarded(AdPlacement placement) async {
    if (!_consentDone) await _ensureConsent();
    final ad = _canRequestAds ? await _awaitRewarded(const Duration(seconds: 5)) : null;
    if (ad == null) {
      // Offline or no fill: never block the player.
      _freeGrants++;
      onUnavailableGrant?.call(placement);
      return true;
    }
    _rewarded = null;
    final done = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete(earned);
        _loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        _freeGrants++;
        onUnavailableGrant?.call(placement);
        if (!done.isCompleted) done.complete(true);
        _loadRewarded();
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  @override
  Future<bool> showInterstitial(AdPlacement placement) async {
    if (!_consentDone) await _ensureConsent();
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        if (!done.isCompleted) done.complete(true);
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        a.dispose();
        if (!done.isCompleted) done.complete(false);
        _loadInterstitial();
      },
    );
    await ad.show();
    return done.future;
  }
}
