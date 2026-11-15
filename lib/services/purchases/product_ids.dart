import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;

/// Store product ids. Google Play uses the short ids; the App Store needs ids
/// that are unique across the whole developer account, so iOS uses the
/// bundle-prefixed ones. Keep the API's PRODUCT_* and PRODUCT_IOS_* env values
/// in step (docs/MONETIZATION_IDS.md).
abstract final class ProductIds {
  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;
  static String _id(String id) => _ios ? 'com.pranta.gridwell.$id' : id;

  /// One-time purchase: removes interstitials.
  static String get removeAds => _id('remove_ads');

  /// Auto-renewing subscriptions: everything.
  static String get premiumMonthly => _id('premium_monthly');
  static String get premiumYearly => _id('premium_yearly');

  /// One-time purchase of one theme: `theme_<key>` (the API matches this
  /// rule, so a new theme needs only a new store product).
  static String theme(String key) => _id('theme_$key');

  /// One-time purchase of every paid theme, now and later.
  static String get themeBundle => theme(themeBundleKey);
  static const themeBundleKey = 'bundle';

  /// The theme key of a theme product id ("midnight", or "bundle"), or null.
  static String? themeKeyOf(String productId) {
    final m = RegExp(r'(?:^|\.)theme_([a-z0-9_]+)$').firstMatch(productId);
    return m?.group(1);
  }

  static List<String> get all => [removeAds, premiumMonthly, premiumYearly];
  static List<String> get subscriptions => [premiumMonthly, premiumYearly];
}
