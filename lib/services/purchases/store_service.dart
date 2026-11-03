import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_inapp_purchase/flutter_inapp_purchase.dart';

import 'product_ids.dart';

/// A completed store purchase, ready for server verification.
class StorePurchase {
  const StorePurchase({required this.productId, required this.platform, required this.token, required this.raw});

  final String productId;

  /// `android` or `ios`.
  final String platform;

  /// Android purchase token, or the iOS StoreKit 2 signed transaction (JWS).
  final String? token;
  final Purchase raw;
}

/// Google Play / App Store billing behind a small surface.
///
/// Until the products exist in the stores (they are created after approval),
/// [products] stays empty and the store screen says purchases are not
/// available yet. Nothing here throws to callers.
class StoreService {
  final _iap = FlutterInappPurchase.instance;
  final _purchases = StreamController<StorePurchase>.broadcast();
  StreamSubscription<Purchase>? _sub;
  bool _connected = false;

  /// Product id -> localized price ("$1.99").
  final products = <String, String>{};

  Stream<StorePurchase> get purchases => _purchases.stream;

  bool get available => _connected && products.isNotEmpty;

  String get _platform => defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> initialize() async {
    try {
      _sub = _iap.purchaseUpdatedListener.listen((p) {
        if (p.purchaseState != PurchaseState.Purchased) return;
        _purchases.add(StorePurchase(productId: p.productId, platform: _platform, token: p.purchaseToken, raw: p));
      });
      _connected = await _iap.initConnection().timeout(const Duration(seconds: 8), onTimeout: () => false);
      if (_connected) await loadProducts();
    } catch (e) {
      debugPrint('store unavailable: $e');
    }
  }

  Future<void> loadProducts() async {
    try {
      final oneTime = await _iap.fetchProducts<Product>(
        skus: const [ProductIds.removeAds],
        type: ProductQueryType.InApp,
      );
      final subs = await _iap.fetchProducts<ProductSubscription>(
        skus: ProductIds.subscriptions,
        type: ProductQueryType.Subs,
      );
      for (final p in [...oneTime, ...subs]) {
        products[p.id] = p.displayPrice;
      }
    } catch (e) {
      debugPrint('products unavailable (expected until store setup): $e');
    }
  }

  /// Starts a purchase. The result arrives on [purchases]. Returns false if
  /// the purchase could not even start (store or product unavailable).
  Future<bool> buy(String productId) async {
    if (!products.containsKey(productId)) return false;
    try {
      final isSub = ProductIds.subscriptions.contains(productId);
      await _iap.requestPurchase(isSub
          ? RequestPurchaseProps.subs((
              apple: RequestSubscriptionIosProps(sku: productId),
              google: RequestSubscriptionAndroidProps(skus: [productId]),
            ))
          : RequestPurchaseProps.inApp((
              apple: RequestPurchaseIosProps(sku: productId),
              google: RequestPurchaseAndroidProps(skus: [productId]),
            )));
      return true;
    } catch (e) {
      debugPrint('purchase failed to start: $e');
      return false;
    }
  }

  /// Acknowledges/finishes a purchase after it has been granted.
  Future<void> finish(StorePurchase p) async {
    try {
      await _iap.finishTransaction(purchase: p.raw, isConsumable: false);
    } catch (e) {
      debugPrint('finishTransaction failed (retried on next restore): $e');
    }
  }

  /// Purchases the store says this account owns right now (Android answers
  /// from its cache offline). Null when the store could not be asked, so a
  /// failed lookup never revokes anything.
  Future<List<StorePurchase>?> owned() async {
    if (!_connected) return null;
    try {
      final list = await _iap.getAvailablePurchases();
      return [
        for (final p in list)
          StorePurchase(productId: p.productId, platform: _platform, token: p.purchaseToken, raw: p),
      ];
    } catch (e) {
      debugPrint('owned purchases unavailable: $e');
      return null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _purchases.close();
  }
}
