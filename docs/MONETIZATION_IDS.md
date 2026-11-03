# Monetization IDs: fill these in

Store products are created only **after** the app is approved (Play Console → Monetize, and App
Store Connect → In-App Purchases / Subscriptions). Until then the app runs on Google's test ad units
and placeholder product ids. Fill each blank below, then hand this file back. Every value goes into
exactly one place, listed in the **Goes in** column.

None of these values are secrets: they ship inside the app binary.

> **Quickest path for ads:** fill in `ADMOB_IDS_TEMPLATE.txt` at the repo root (same format as
> Screw Out) and say "admob ids are filled". Sections 1 and 2 below explain where each value ends up.

## 1. AdMob app IDs (native config)

The format is `ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY`. It contains a **tilde** (`~`).

| Platform | Value | Goes in |
|---|---|---|
| Android app ID | `________________________________` | `android/app/src/main/AndroidManifest.xml`, `com.google.android.gms.ads.APPLICATION_ID` (currently Google's test id) |
| iOS app ID | `________________________________` | `ios/Runner/Info.plist`, `GADApplicationIdentifier` (added on the Mac) |

## 2. AdMob ad unit IDs (Dart)

The format is `ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY`. It contains a **slash** (`/`).

Gridwell uses only two formats: **rewarded** (hints, revealing a line, unlocking a missed daily)
and **interstitial** (after a completed puzzle, with a frequency cap). There are no banners.

| Unit | Android | iOS | Goes in |
|---|---|---|---|
| Rewarded | `______________________` | `______________________` | `lib/services/ads/ad_config.dart` |
| Interstitial | `______________________` | `______________________` | `lib/services/ads/ad_config.dart` |

Debug builds always use Google's official test units, whatever is filled in here. Serving your own
real ads during development is an AdMob policy violation.

## 3. In-app products (Dart + backend)

Use the same id on both stores where possible. Ids may contain only lowercase letters, digits,
underscores and dots (for example `com.pranta.gridwell.remove_ads`).

| Product | Type | Price | Play product id | App Store product id |
|---|---|---|---|---|
| Remove Ads | One-time (non-consumable) | $1.99 | `______________` | `______________` |
| Premium monthly | Auto-renewing subscription | $2.99 / month, trial: ___ days | `______________` | `______________` |
| Premium yearly | Auto-renewing subscription | $14.99 / year, trial: ___ days | `______________` | `______________` |

These go in two places:
- The app: `lib/services/purchases/product_ids.dart`
- The API's `.env`: `PRODUCT_REMOVE_ADS`, `PRODUCT_PREMIUM_MONTHLY`, `PRODUCT_PREMIUM_YEARLY`

For subscriptions on Google Play, also note the **base plan id** for each plan (for example
`monthly`, `yearly`): `______________` / `______________`

## 4. Backend store credentials (API `.env` only, never in the app)

| Value | Format | Status |
|---|---|---|
| Google Play service account JSON | file `google-play-service-account.json` | Already in place |
| Play Pub/Sub verification token | random string, also used in the push subscription URL `?token=` | In `.env`; still to configure in Google Cloud |
| Apple In-App Purchase key ID | 10 characters, e.g. `ABC123DEFG` | `____________` |
| Apple issuer ID | UUID | `____________` |
| Apple private key (.p8) | file, or its contents on one line with `\n` | `____________` |
| Apple App Store Server Notifications v2 URL | `https://gridwell.pranta.dev/api/v1/purchases/webhook/app-store` | Paste this into App Store Connect |

## 5. Consent and tracking

- **EEA/UK consent (Google UMP):** create a GDPR message in AdMob → Privacy & messaging. The app
  shows it before the first ad.
- **iOS App Tracking Transparency:** Info.plist `NSUserTrackingUsageDescription`. Proposed text:
  "Your choice lets Gridwell show ads that are less random. The game works the same either way."
