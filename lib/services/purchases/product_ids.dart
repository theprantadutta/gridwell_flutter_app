/// Store product ids. Placeholders until the products exist in Play Console
/// and App Store Connect (created after approval); fill from
/// docs/MONETIZATION_IDS.md and keep the API's PRODUCT_* env values in step.
abstract final class ProductIds {
  /// One-time purchase: removes interstitials.
  static const removeAds = 'remove_ads';

  /// Auto-renewing subscriptions: everything.
  static const premiumMonthly = 'premium_monthly';
  static const premiumYearly = 'premium_yearly';

  static const all = [removeAds, premiumMonthly, premiumYearly];
  static const subscriptions = [premiumMonthly, premiumYearly];
}
