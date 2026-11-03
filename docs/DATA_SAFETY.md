# Data safety (Google Play) and App Privacy (App Store)

Answers for the two store privacy forms, consistent with `assets/legal/PRIVACY.md`. Where the policy changes,
change this file too, and the other way round.

Ground rules used throughout:

- **Declare what the third-party SDKs collect, not just our own code.** Both stores hold the developer
  responsible for Firebase and AdMob. Check the SDK pages before submitting, because Google updates them:
  - AdMob, Android: https://developers.google.com/admob/android/privacy/play-data-disclosure
  - AdMob, iOS: https://developers.google.com/admob/ios/privacy/data-disclosure
  - Firebase, both: https://firebase.google.com/docs/android/play-data-disclosure and
    https://firebase.google.com/docs/ios/app-store-data-collection
- **When in doubt, declare.** Over-declaring a data type costs little; under-declaring can get the app
  removed. Items marked **[CONFIRM]** are judgment calls the owner should settle against the current SDK pages.
- **Things that are not collected:** name (real), email, phone, address, precise location, contacts,
  photos or videos, audio, files, calendar, health and fitness, messages, web browsing history,
  payment card details (Google and Apple handle payment), and anything from other apps.

What the app actually sends (from `lib/data/remote/api_client.dart` and the backend entities):

| Sent to our server | Stored as |
|---|---|
| Firebase ID token, timezone offset | `User`: Firebase UID, pen name, timezone offset, notification opt-in, last seen |
| Progress rows, settings JSON, achievement progress | `PuzzleProgress`, `UserSettings`, `UserAchievement` |
| Daily completion: date, time, client local date | `DailyCompletion` (time, eligible time, ineligible reason) |
| Pen name, notifications on/off | `User` |
| FCM token, platform, timezone offset | `FcmToken` |
| Purchase token / signed transaction, product ID | `Purchase` (store, product, transaction and order IDs, status, expiry, trial, auto-renew, refund date, raw store response), `UserEntitlement` |

---

## Part 1: Google Play Data safety form

### Data collection and security

| Question | Answer | Why |
|---|---|---|
| Does your app collect or share any of the required user data types? | **Yes** | Firebase, AdMob and our own sync. |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | The API is HTTPS only; Firebase and AdMob use TLS. |
| Which of the following methods of account creation does your app support? | **[CONFIRM]** Recommended: **"My app does not allow users to create an account"** | Players never create an account. Anonymous Firebase sign-in happens automatically, with no username, password or email. If the owner prefers to be conservative, answer that it does allow accounts, then the account-deletion URL below becomes required. |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In-app deletion (`DELETE /api/v1/users/me`) plus email. |
| Delete-data URL (web link) | **[CONFIRM]** a public page explaining how to delete data, for example a section of the hosted privacy policy | Play asks for a web link even when deletion is in-app. Section 8 of the privacy policy works if it is hosted at a stable URL. |
| Has your app been independently validated against a global security standard? | **No** (unless a MASA review is done) | |
| Families policy / target audience | Target audience **13+** (see `LAUNCH_CHECKLIST.md`) | Keeps the app out of the Families program, whose ad SDK rules AdMob in its default setup does not meet. |

### Data types

"Shared" in Play's sense means transferred to a third party. Transfers to a **service provider processing
on our behalf** (Firebase for analytics, crash reports, auth and messaging) are **not** sharing. AdMob uses
data for its own advertising purposes as well, so its data is declared as **shared**.

"Optional" means the user can choose not to provide it. Most of these are collected automatically, so
they are declared **required** unless noted.

#### Location

| Type | Collected | Shared | Optional | Purposes | Ephemeral | Notes |
|---|---|---|---|---|---|---|
| Approximate location | **Yes** | **Yes** | Required | Advertising or marketing, Analytics, Fraud prevention | No | Not from GPS. AdMob and Firebase Analytics derive a coarse region from the IP address. The app has no location permission. **[CONFIRM]** against the AdMob page; Google's guidance has listed IP-derived approximate location for the Mobile Ads SDK. The timezone offset we store is coarser than "approximate location" and is not declared separately. |
| Precise location | No | | | | | |

#### Personal info

| Type | Collected | Shared | Optional | Purposes | Notes |
|---|---|---|---|---|---|
| Name | **Yes** | No | Optional | App functionality | The leaderboard **pen name** is a nickname, which Play counts as "Name". It is generated, not entered, but the player can change it to anything (filtered), and it is shown publicly. Marked optional because the player never has to provide one. **[CONFIRM]** if the owner prefers not to declare a generated name. |
| Email address | No | | | | Never asked for. |
| User IDs | **Yes** | No | Required | App functionality, Account management | Anonymous Firebase UID and our internal user ID. |
| Address, Phone, Race and ethnicity, Political or religious beliefs, Sexual orientation, Other info | No | | | | |

#### Financial info

| Type | Collected | Shared | Optional | Purposes | Notes |
|---|---|---|---|---|---|
| Purchase history | **Yes** | No | Optional | App functionality, Fraud prevention, security, and compliance | Our server stores verified purchases to grant entitlements. Only players who buy something have this. Payment is done by Google Play; we receive no card data. |
| User payment info, Credit score, Other financial info | No | | | | |

#### App activity

| Type | Collected | Shared | Optional | Purposes | Notes |
|---|---|---|---|---|---|
| App interactions | **Yes** | **Yes** | Required | Analytics, App functionality, Advertising or marketing | Firebase Analytics events (`puzzle_start`, `puzzle_complete`, `hint_used`, ...), puzzle progress and times synced to our server, and ad interactions collected by AdMob (the "shared" part). |
| Other user-generated content | No | | | | The pen name is declared under Name. **[CONFIRM]** some developers declare it here instead; one place is enough. |
| Other actions | **Yes** | No | Required | App functionality | Daily completions, achievement progress and settings synced for backup and the leaderboard. **[CONFIRM]** this can be folded into App interactions; declaring it separately is harmless. |
| In-app search history, Installed apps, Web browsing | No | | | | |

#### App info and performance

| Type | Collected | Shared | Optional | Purposes | Notes |
|---|---|---|---|---|---|
| Crash logs | **Yes** | No | Required | App functionality, Analytics | Firebase Crashlytics (release builds). |
| Diagnostics | **Yes** | **Yes** | Required | Analytics, Advertising or marketing, Fraud prevention | AdMob collects SDK performance and diagnostic data; Firebase collects app-level diagnostics. |
| Other app performance data | No | | | | No Firebase Performance Monitoring in the app. |

#### Device or other IDs

| Type | Collected | Shared | Optional | Purposes | Notes |
|---|---|---|---|---|---|
| Device or other IDs | **Yes** | **Yes** | Required | Advertising or marketing, Analytics, Fraud prevention, App functionality | Android advertising ID and app set ID (AdMob, shared), Firebase app instance and installation IDs (Analytics, Crashlytics), and the FCM token (push notifications). |

#### Not collected

Messages, Photos and videos, Audio files, Health and fitness, Contacts, Calendar, Files and docs: **No**.

### Play Console "Ads" and related declarations

- **Contains ads:** Yes.
- **Advertising ID declaration:** Yes, the app uses the advertising ID, for **Advertising or marketing** and
  **Analytics**. The `com.google.android.gms.permission.AD_ID` permission is merged into the manifest by the
  Google Mobile Ads SDK. **[CONFIRM]** that the merged release manifest contains it
  (`build/app/intermediates/merged_manifests/release/AndroidManifest.xml`).

---

## Part 2: Apple App Privacy ("nutrition label")

Apple's three groups are: **Data Used to Track You**, **Data Linked to You**, **Data Not Linked to You**.
"Tracking" means linking data from this app with data from other companies' apps or websites for
advertising, or sharing it with a data broker. With AdMob personalization, that applies to the ad
identifiers when the player allows tracking through App Tracking Transparency.

"Linked to you" means tied to an identity: an account, a user ID or a device ID. Our anonymous Firebase
UID counts as a user ID, so everything our server stores is **linked**, even though it carries no real name.

### Data Used to Track You

| Category | Data type | Notes |
|---|---|---|
| Identifiers | **Device ID** | IDFA, only available after the player taps "Allow" on the ATT prompt. Used by AdMob for personalized ads. |
| Usage Data | **Advertising Data** | Ads seen and interacted with, collected by AdMob. **[CONFIRM]** against the AdMob iOS page. |
| Location | **Coarse Location** | AdMob derives coarse location from the IP address. **[CONFIRM]** against the AdMob iOS page. |

If the ATT prompt is declined, none of this is used for tracking, but Apple's label describes what the
app *may* do, so it is still declared.

### Data Linked to You

| Category | Data type | Purposes | Notes |
|---|---|---|---|
| Identifiers | **User ID** | App Functionality | Anonymous Firebase UID and our internal user ID. |
| Identifiers | **Device ID** | App Functionality, Analytics, Third-Party Advertising | FCM token (push), Firebase app instance ID (Analytics), IDFA/IDFV for AdMob. |
| Purchases | **Purchase History** | App Functionality | Verified purchases and entitlements stored on our server. |
| User Content | **Gameplay Content** | App Functionality | Puzzle progress, best times, daily completions and times, achievement progress, settings backup. |
| User Content | **Other User Content** | App Functionality | The editable pen name shown on leaderboards. **[CONFIRM]** Apple's "Name" type means a real first or last name; a generated pen name fits better here. |
| Usage Data | **Product Interaction** | Analytics, App Functionality | Firebase Analytics gameplay events. The app does not call `setUserId`, but the events carry the Firebase app instance ID, so they are declared as linked to be safe. |
| Location | **Coarse Location** | Analytics, Third-Party Advertising | Firebase Analytics and AdMob derive region from IP. **[CONFIRM]** |

### Data Not Linked to You

| Category | Data type | Purposes | Notes |
|---|---|---|---|
| Diagnostics | **Crash Data** | App Functionality | Firebase Crashlytics. The app sets no Crashlytics user identifier, so crash reports are tied only to a random installation ID. |
| Diagnostics | **Other Diagnostic Data** | Analytics, Third-Party Advertising | AdMob SDK diagnostics. |
| Diagnostics | **Performance Data** | Analytics | **[CONFIRM]** only if the AdMob or Firebase iOS page lists it at submission time. |

### Not collected

Contact Info (name, email, phone, address), Health and Fitness, Financial Info (payment card, credit),
Precise Location, Sensitive Info, Contacts, Emails or Text Messages, Photos or Videos, Audio Data,
Customer Support (none in the app), Browsing History, Search History, Other Data.

### Related iOS items

- **App Tracking Transparency:** the app shows the ATT prompt before personalized ads are requested.
  `NSUserTrackingUsageDescription` text (from `MONETIZATION_IDS.md`): "Your choice lets Gridwell show ads that
  are less random. The game works the same either way." Apple rejects apps that declare tracking but never
  show the prompt, or show the prompt but declare no tracking; keep the two consistent.
- **Privacy manifests:** Firebase and the Google Mobile Ads SDK ship their own `PrivacyInfo.xcprivacy`
  files. **[CONFIRM]** on the Mac that Xcode's privacy report (Product > Archive, then
  Generate Privacy Report in the Organizer) agrees with this label.
- **Account deletion:** App Store Review Guideline 5.1.1(v) requires in-app deletion for apps with
  account creation. Anonymous accounts are borderline; the in-app delete covers it either way.
