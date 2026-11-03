import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ads/ad_service.dart';
import '../services/analytics/analytics_service.dart';
import '../services/purchases/product_ids.dart';
import '../services/purchases/store_service.dart';
import 'online.dart';
import 'providers.dart';
import 'services.dart';

export '../services/purchases/product_ids.dart' show ProductIds;

/// Overridden in main() with the initialized store connection.
final storeServiceProvider = Provider<StoreService>((ref) => StoreService());

/// What the store screen shows.
class StoreState {
  const StoreState({this.prices = const {}, this.busy, this.message});

  /// Product id -> localized price. Empty until the products exist in the
  /// stores (after approval).
  final Map<String, String> prices;

  /// Product id currently being bought.
  final String? busy;
  final String? message;

  bool get available => prices.isNotEmpty;

  StoreState copyWith({Map<String, String>? prices, String? Function()? busy, String? Function()? message}) =>
      StoreState(
        prices: prices ?? this.prices,
        busy: busy == null ? this.busy : busy(),
        message: message == null ? this.message : message(),
      );
}

/// Purchases: grant locally the moment the store says "purchased", verify
/// with the server when online, then finish the transaction. Owned purchases
/// are re-read from the store at launch, so entitlements survive reinstalls
/// and work offline.
class PurchaseController extends Notifier<StoreState> {
  StreamSubscription<StorePurchase>? _sub;

  @override
  StoreState build() {
    final store = ref.read(storeServiceProvider);
    _sub = store.purchases.listen(_onPurchase);
    ref.onDispose(() => _sub?.cancel());
    unawaited(_reconcileOwned());
    return StoreState(prices: Map.of(store.products));
  }

  Future<void> _onPurchase(StorePurchase p) async {
    _grantLocally(p.productId);
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.iapPurchased, {'product_id': p.productId}));
    await _verify(p);
    await ref.read(storeServiceProvider).finish(p);
    state = state.copyWith(busy: () => null, message: () => 'Thank you. It is yours.');
  }

  void _grantLocally(String productId) {
    final current = ref.read(entitlementsProvider);
    ref.read(entitlementsProvider.notifier).set(Entitlements(
          removeAds: current.removeAds || productId == ProductIds.removeAds,
          premium: current.premium || ProductIds.subscriptions.contains(productId),
        ));
  }

  Future<void> _verify(StorePurchase p) async {
    final online = ref.read(onlineSessionProvider);
    if (!await online.ensureSignedIn()) return; // re-verified on the next restore
    final res = await ref.read(apiClientProvider).verifyPurchase(
          platform: p.platform,
          productId: p.productId,
          purchaseToken: p.platform == 'android' ? p.token : null,
          signedTransaction: p.platform == 'ios' ? p.token : null,
        );
    final ent = res?['entitlements'];
    if (ent is Map<String, Object?>) online.applyEntitlements(ent);
  }

  Future<void> _reconcileOwned() async {
    final owned = await ref.read(storeServiceProvider).owned();
    if (owned == null) return; // store unreachable: keep what we have
    final ids = owned.map((p) => p.productId).toSet();
    final current = ref.read(entitlementsProvider);
    ref.read(entitlementsProvider.notifier).set(Entitlements(
          // Non-consumables are always listed while owned; keep a server grant too.
          removeAds: current.removeAds || ids.contains(ProductIds.removeAds),
          // A lapsed subscription is no longer listed, so premium follows the store.
          premium: ids.any(ProductIds.subscriptions.contains),
        ));
    for (final p in owned) {
      await _verify(p);
      await ref.read(storeServiceProvider).finish(p);
    }
  }

  Future<void> buy(String productId) async {
    unawaited(ref.read(analyticsProvider).log(AnalyticsEvents.iapViewed, {'product_id': productId}));
    state = state.copyWith(busy: () => productId, message: () => null);
    final started = await ref.read(storeServiceProvider).buy(productId);
    if (!started) {
      state = state.copyWith(
        busy: () => null,
        message: () => 'Purchases are not available right now. Nothing was charged.',
      );
    }
  }

  Future<void> restore() async {
    state = state.copyWith(busy: () => 'restore', message: () => null);
    await _reconcileOwned();
    final e = ref.read(entitlementsProvider);
    state = state.copyWith(
      busy: () => null,
      message: () => e.premium || e.removeAds ? 'Your purchases are restored.' : 'No purchases were found for this account.',
    );
  }
}

final purchaseControllerProvider = NotifierProvider<PurchaseController, StoreState>(PurchaseController.new);

/// When an interstitial may appear: only after a completed puzzle, only from
/// "Next puzzle", never before the player has solved a few, at most every
/// third completion and never within four minutes of the last one. Never for
/// Remove Ads or Premium. Never on restart or resume (it is only ever asked
/// from the completion page).
class InterstitialPolicy {
  InterstitialPolicy(this._ref);

  final Ref _ref;
  static const minSolvesBeforeFirst = 6;
  static const everyNthCompletion = 3;
  static const cooldown = Duration(minutes: 4);

  int _completionsSinceLast = 0;
  DateTime? _lastShown;

  void recordCompletion() => _completionsSinceLast++;

  Future<void> maybeShow() async {
    if (_ref.read(entitlementsProvider).noInterstitials) return;
    final solved = (_ref.read(progressProvider).value ?? const {}).values.where((p) => p.isSolved).length;
    if (solved < minSolvesBeforeFirst) return;
    if (_completionsSinceLast < everyNthCompletion) return;
    final last = _lastShown;
    if (last != null && DateTime.now().difference(last) < cooldown) return;
    final analytics = _ref.read(analyticsProvider);
    final shown = await _ref.read(adServiceProvider).showInterstitial(AdPlacement.afterCompletion);
    if (shown) {
      _completionsSinceLast = 0;
      _lastShown = DateTime.now();
      unawaited(analytics.log(AnalyticsEvents.adShown, {'placement': 'after_completion'}));
      unawaited(analytics.log(AnalyticsEvents.adCompleted, {'placement': 'after_completion'}));
    }
  }
}

final interstitialPolicyProvider = Provider((ref) => InterstitialPolicy(ref));
