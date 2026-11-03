# Gridwell Privacy Policy

**Effective date:** [CONFIRM: date of publication]

This policy explains what information **Gridwell: Nonogram Picross** ("Gridwell", "the app", "we", "us")
collects, why, who it is shared with, how long it is kept, and the choices you have. It applies to the
Gridwell app on Android and iOS and to the Gridwell server that the app talks to
(`https://gridwell.pranta.dev`).

**Who is responsible for your data.** Gridwell is made by [CONFIRM: developer's full legal name, or
business name if one is registered], [CONFIRM: country and postal address, required by GDPR for the
data controller]. Contact: **prantadutta1997@gmail.com**.

## The short version

- Gridwell plays fully offline. You never need an internet connection, and nothing you do in a puzzle
  waits on our server.
- There are no accounts to create. We never ask for your name, email address or phone number, and we
  never collect your precise location.
- When you are online, the app signs in anonymously, backs up your puzzle progress, and takes part in
  the daily leaderboard under a made-up pen name.
- We use Google Firebase to understand how the game is played and to fix crashes, and Google AdMob to
  show ads. Ads are personalized only where you allow it.
- You can delete everything we hold about you from inside the app, or by emailing us.

## 1. Information we collect

### 1.1 Anonymous user ID

When the app first goes online it signs in to **Firebase Authentication** anonymously. Firebase creates
a random user ID that is not tied to your name, email or phone. Our server receives this ID, links it to
a random internal account ID, and uses it to keep your backup and leaderboard entries together.
It is not shown to other players.

If you uninstall the app without deleting your data first, the anonymous ID is lost with it, and a new
install starts a new anonymous account. See section 8 for how to delete data in that case.

### 1.2 Pen name

Each player gets a randomly generated **pen name**, used only on daily
leaderboards. You can change it in the app. Pen names are filtered for offensive words. **Your pen name
is public:** other players see it next to your daily time. Please do not use your real name or anything
that identifies you.

### 1.3 Puzzle progress, times and settings

When you are online, the app syncs to our server:

- for each puzzle you play: its ID, whether you solved it, your best time, when you solved it, when you
  last played it, and the puzzle set version it was played on;
- for each daily puzzle you finish: the date, your time, your device's local date, and whether the time
  counts for the leaderboard (and if not, why, for example a late solve);
- achievement progress;
- your in-app settings (for example theme, sound and timer preferences), so they can be restored.

This lets us back up your progress and run the daily leaderboard. The same information is also kept on
your device, where the game works without the server.

### 1.4 Timezone offset

The app sends your device's **timezone offset** (the number of minutes your clock is ahead of or behind
UTC, for example +330). We use it to work out which daily puzzle is "today" for you and to send any
re-engagement notification at a sensible local hour. It is not your location: an offset is shared by
everyone in that time zone.

### 1.5 Push notification token

If you allow notifications, the app registers a **Firebase Cloud Messaging (FCM) token** with our server,
together with your platform (Android or iOS) and the time it was last used. The token lets us send
occasional notifications, such as news about a new collection or a reminder if you have not played in a
while. You can turn these off in the app or in your device settings.

The **daily reminder** (7 pm local time) is a local notification scheduled on your device. It does not
involve our server or the FCM token.

### 1.6 Purchases

If you buy Remove Ads or subscribe to Gridwell Premium, the payment is handled entirely by **Google Play**
or the **Apple App Store**. We never see your card or bank details, your name, or your billing address.

To confirm the purchase and unlock it, the app sends our server the store's purchase token (Google Play)
or signed transaction (Apple). Our server checks it directly with Google or Apple and stores:

- the store, product ID and product type;
- the store's transaction ID and order ID;
- the purchase status, expiry date, whether it is a free trial, and whether it renews automatically;
- the date of any refund or cancellation;
- the store's latest raw verification response, kept for customer support.

From this we work out what you are entitled to (no ads, Premium and its expiry). Google and Apple also
notify our server when a subscription renews, lapses or is refunded, so your entitlements stay correct.

### 1.7 Analytics events

We use **Google Analytics for Firebase** to learn how the game is played, so we can make puzzles fairer
and the app better. The app logs gameplay events such as starting, finishing or leaving a puzzle,
opening a puzzle without making a move, using a hint or undo, making a mistake, finishing a collection,
starting and finishing the daily puzzle, an ad being shown or watched to the end, viewing or completing a
purchase, and changing a setting. Events carry details about the game, such as the puzzle, its size and
the time taken.

Firebase also collects some information automatically, including an app instance ID, device model,
operating system and version, app version, language, session information, and an approximate country or
region derived from your IP address. See Google's documentation:
https://support.google.com/analytics/answer/6318039

[CONFIRM: whether the Android advertising ID is collected by Firebase Analytics, or disabled with
`google_analytics_adid_collection_enabled = false` in AndroidManifest.xml. On iOS, Firebase Analytics
can read the advertising identifier only if you allow tracking (section 1.9).]

[CONFIRM: in the EEA/UK, whether analytics collection waits for consent (Firebase consent mode) or
runs on legitimate interest. Section 3 must match the choice.]

### 1.8 Crash reports

We use **Firebase Crashlytics** to find and fix crashes. When the app crashes, Crashlytics sends a crash
report containing the technical details of the error (stack trace), device model, operating system
version, app version, the time of the crash, and a random installation ID. Crash reports are collected
only from release builds. We do not attach your user ID, pen name or any other identity to crash reports.

### 1.9 Advertising ID and ad personalization

Gridwell is free to play and shows ads through **Google AdMob**: rewarded videos you choose to watch
(for example for an extra hint) and occasional full-screen ads after you finish a puzzle. There are no
banner ads. Players with Remove Ads do not see ads between puzzles, and Premium players see no ads.

To serve and measure ads and to prevent ad fraud, the Google Mobile Ads SDK collects your device's
**advertising ID** (Android advertising ID, or Apple's IDFA when permitted), your IP address, device and
app information, and how you interact with ads. Google's description:
https://developers.google.com/admob/android/privacy/play-data-disclosure and
https://developers.google.com/admob/ios/privacy/data-disclosure

Your choices:

- **EEA, UK (and Switzerland):** before any ad is requested, the app shows Google's consent form (Google
  User Messaging Platform). Ads are personalized only if you consent. You can change your choice at any
  time from the app's settings. [CONFIRM: the in-app "Privacy options" entry that reopens the consent form
  exists before launch.]
- **iOS:** the app asks permission through Apple's App Tracking Transparency prompt. If you choose
  "Ask App Not to Track", the IDFA is not available to the app or to AdMob, and ads are not personalized
  using it. You can change this any time in Settings > Privacy & Security > Tracking.
- **Android:** you can reset or delete your advertising ID, or opt out of ad personalization, in your
  device's Settings > Privacy > Ads (wording varies by device).
- **United States:** [CONFIRM: whether a US state regulations message (for "Do Not Sell or Share") is
  enabled in AdMob Privacy & messaging. If not, state here that California and other state residents can
  opt out through the device ad settings above.]

If you do not consent, you may still see ads, but they are not based on your personal data.

### 1.10 Information we do not collect

We do **not** collect your name, email address, phone number, postal address, precise (GPS)
location, contacts, photos, microphone or camera data, or payment card details. We do not ask you to
create an account.

### 1.11 Technical data on our server

Like any internet service, our server sees your IP address when the app connects. We do not store IP
addresses in our database. Our server logs record requests (such as the address requested, the result
and how long it took) and errors, and are deleted after 30 days. [CONFIRM: that production request logs
do not include IP addresses; the current logging setup does not add them.]

## 2. How we use information

- To provide the game's online features: backup of your progress, the daily puzzle calendar, the daily
  leaderboard, and your pen name.
- To verify purchases and keep your entitlements (Remove Ads, Premium) correct, including renewals and
  refunds.
- To send notifications you have allowed.
- To understand how the game is played and improve puzzles and features (analytics).
- To find and fix crashes and bugs (crash reports).
- To show ads, personalized only where you allow it, and to prevent ad fraud.
- To keep the service secure and prevent abuse, for example to reject implausibly fast leaderboard times.

We do not sell your personal information for money. We do not use your data to make decisions that have
legal or similarly significant effects on you.

## 3. Legal bases (EEA and UK)

- **Performance of our contract with you** (providing the game you asked for): anonymous sign-in, sync of
  progress and settings, the daily leaderboard and pen name, purchase verification and entitlements.
- **Consent:** personalized ads, and on iOS, tracking through App Tracking Transparency; push
  notifications. You can withdraw consent at any time, without affecting earlier processing.
- **Legitimate interests** (keeping the app stable, secure and improving): crash reports, fraud and abuse
  prevention, non-personalized ads that fund a free game, and [CONFIRM: analytics, or move analytics to
  "Consent" if it is gated on the consent form].
- **Legal obligation:** keeping records where the law requires it.

## 4. Who we share information with

We share information only with the service providers that run parts of Gridwell, under their terms:

| Provider | What for | Their privacy information |
|---|---|---|
| **Google Firebase** (Google LLC): Authentication, Analytics, Crashlytics, Cloud Messaging | Anonymous sign-in, analytics, crash reports, push notifications | https://firebase.google.com/support/privacy |
| **Google AdMob** (Google LLC) | Ads, ad measurement, consent form | https://policies.google.com/technologies/ads |
| **Google Play** (Google LLC) | Purchases, subscription status and verification (Android) | https://policies.google.com/privacy |
| **Apple** (Apple Inc.) | Purchases, subscription status and verification, App Tracking Transparency (iOS) | https://www.apple.com/legal/privacy/ |
| **Hosting provider** for our server | Stores the data described in section 1 | [CONFIRM: VPS provider name and the country where the server and database are located] |

We may also disclose information if the law requires it, to protect the rights and safety of our players
or others, or as part of a sale or transfer of the app, in which case this policy continues to apply.

Your **pen name and daily times** are visible to other players on the daily leaderboard.

## 5. International transfers

Google and Apple may process data in the United States and other countries. Our server is located in
[CONFIRM: country]. Where data leaves the EEA or UK, it is protected by the safeguards these providers
offer, such as the EU-US Data Privacy Framework or the European Commission's Standard Contractual Clauses.

## 6. How long we keep information

| Data | Kept for |
|---|---|
| Server account: anonymous ID, pen name, timezone offset, progress, daily times, achievements, settings | Until you delete your data (section 8). [CONFIRM: whether inactive accounts are deleted automatically, for example after 24 months without activity. There is no automatic deletion today.] |
| Purchase records and entitlements | Until you delete your data. Google and Apple keep their own purchase records under their own policies. [CONFIRM: whether any purchase records must be kept longer for tax or accounting.] |
| FCM token | Until you delete your data, turn off notifications, or Firebase reports the token as no longer valid, whichever comes first. |
| Server logs | 30 days |
| Firebase Analytics | [CONFIRM: the data retention setting in Google Analytics, 2 or 14 months] |
| Crashlytics crash reports | [CONFIRM: currently 90 days per Firebase documentation] |
| AdMob data | Under Google's own retention policies |
| Data on your device | Until you delete it in the app or uninstall the app |

## 7. Children's privacy

Gridwell is a general-audience puzzle game. **It is not directed at children under 13**, and we do not
knowingly collect personal information from children under 13 (or the higher age of digital consent in
your country). If you believe a child under 13 has used the online features, contact us and we will
delete the data.

[CONFIRM: store settings. Recommended: Google Play target audience 13 and over, not part of the Designed
for Families program; IARC rating as calculated (expected Everyone / PEGI 3, with "In-app purchases" and
"Contains ads"); App Store age rating 4+ (content) and not in the Kids category; AdMob requests not tagged
as child-directed.]

## 8. Your rights and how to delete your data

**Delete from the app.** Open **Settings > Privacy > Delete my data** [CONFIRM: final menu path]. This
deletes your account on our server, including your pen name, progress, daily times, achievements,
settings, purchase records, entitlements and notification tokens, and then deletes your anonymous
Firebase account. It needs an internet connection. Deleting your data does not cancel a subscription:
cancel it in Google Play or in your Apple Account settings. A Remove Ads purchase or active subscription
can be restored later through the store's "Restore purchases".

**Delete by email.** Write to **prantadutta1997@gmail.com** with the subject "Delete my Gridwell data".
Because there are no accounts, we need a way to find your data: include your current pen name and
[CONFIRM: the player or support ID shown in the app, if one is added]. We will reply within 30 days.

**Your rights.** Depending on where you live, including under the EU and UK GDPR and the California
Consumer Privacy Act (CCPA/CPRA), you may have the right to:

- access the personal information we hold about you, and receive a copy in a portable format;
- correct it (you can change your pen name in the app at any time);
- delete it;
- object to or restrict certain processing, including processing based on legitimate interests;
- withdraw consent at any time (see section 1.9 for ads and tracking);
- opt out of the "sale" or "sharing" of personal information for cross-context behavioral advertising
  (see section 1.9);
- not be discriminated against for exercising these rights;
- complain to your local data protection authority.

To exercise any right, email **prantadutta1997@gmail.com**. We do not sell personal information for money.
California residents: in the past 12 months we have collected the categories of information described in
section 1 (identifiers, commercial information such as purchase records, internet or other electronic
network activity such as app interactions, and approximate region inferred from IP address), for the
purposes in section 2, and disclosed them to the providers in section 4.

## 9. Security

All traffic between the app and our server uses HTTPS. Our server and database are accessible only to the
developer, and credentials are never stored in the app. No system is perfectly secure, but we take
reasonable steps to protect your information.

## 10. Changes to this policy

If we change this policy, we will update the effective date above and, for significant changes, tell you
in the app. Previous versions are available on request.

## 11. Contact

Questions about this policy or your data: **prantadutta1997@gmail.com**
