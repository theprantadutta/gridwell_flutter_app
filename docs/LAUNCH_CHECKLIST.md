# Launch checklist

Everything that blocks the 1.0 launch on Google Play and the App Store, in the order it should start.
Some items have long lead times (the Play closed test takes at least 14 days), so start those first.

Related docs: `MONETIZATION_IDS.md` (IDs to fill in), `STORE_LISTING.md`, `assets/legal/PRIVACY.md`,
`DATA_SAFETY.md`, `MAC_CHECKLIST.md` (all iOS work), `PERFORMANCE.md`, and the API repo's `CLAUDE.md`.

---

## 1. Start now: Google Play closed testing (14-day clock)

New personal Play developer accounts must run a **closed test with at least 12 testers who stay opted in
for 14 continuous days** before they can apply for production access. Nothing else on this list is
blocked by it, but it gates the Android launch date, so start the clock as early as possible, even with a
build whose monetization IDs are still test values.

- [ ] Play Console > create the app "Gridwell" (package `com.pranta.gridwell`, game, free).
- [ ] Fill the minimum store listing and App content forms needed to publish to a testing track (privacy
  policy URL, ads declaration, Data safety, target audience, content rating; sections 7 to 9 below).
- [ ] Upload a signed release **AAB** to **Testing > Closed testing** (create a track, for example "Closed beta"):
  ```
  flutter build appbundle --release
  ```
  Output: `build/app/outputs/bundle/release/app-release.aab`. **[CONFIRM]** release signing: an upload key
  in `android/key.properties` (gitignored) and Play App Signing enrolled.
- [ ] Add **at least 12 testers** (an email list or a Google Group). Recruit 15 to 20, because the count
  that matters is testers **still opted in** on every one of the 14 days.
- [ ] Each tester opens the opt-in link, accepts, and installs from Play. Ask them to keep it installed and
  open it now and then. Google also looks for real engagement and feedback during the test.
- [ ] Note the start date: ____________. Earliest date to apply for production: start + 14 days.
- [ ] After 14 days: Play Console > Dashboard > **Apply for production**, answer the questions about the
  test (how testers were recruited, what feedback changed). Review can take about a week.
- [ ] Keep shipping updated builds to the closed track during the test; that does not reset the clock.

## 2. Product blockers in the app

- [ ] **In-app privacy screen.** Settings has a "Privacy" row that pushes `/privacy`, but no `/privacy`
  route exists yet (checked 2026-11-03). It must show or link the privacy policy and offer the consent
  options below.
- [ ] **In-app account deletion.** The API has `DELETE /api/v1/users/me` (deletes the user, all their data
  by cascade, and their Firebase account), but the app has no button that calls it yet. Add
  "Delete my data" with a confirmation, then clear local sync state and sign out of Firebase. Both stores
  expect this, and the privacy policy promises it. **[CONFIRM]** the final menu path, and update
  `assets/legal/PRIVACY.md` section 8 to match.
- [ ] **Privacy options entry** that reopens the Google UMP consent form for EEA/UK users (required by
  Google's consent policy when consent is gathered).
- [ ] **[CONFIRM]** a player/support ID visible in the app, so email deletion requests can be matched to an
  anonymous account (the privacy policy mentions it as optional).
- [ ] **[CONFIRM]** Android advertising ID collection by Firebase Analytics: keep it, or add
  `google_analytics_adid_collection_enabled = false` to the manifest. Make `assets/legal/PRIVACY.md` 1.7 and
  `DATA_SAFETY.md` agree with the choice.

## 3. Daily start date, rebake, re-export

The daily calendar is shared: the app bundles the 90-day pool with `daily_start_date`, and the API
schedules the same pool from the exported file's `start_date`, so offline and online players see the same
daily. The current value **`2026-12-01` is a placeholder**.

- [ ] Choose the real launch date: day 1 of the daily calendar. It should be on or shortly before the
  public launch so the leaderboard starts with the launch. Date: ____________.
- [ ] Set it in `content/collections.json`:
  ```json
  "daily_start_date": "YYYY-MM-DD",
  ```
- [ ] Rebake and export the daily pool straight into the API repo's seed folder:
  ```
  dart run tool/gridwell.dart bake --api-seed-dir ../gridwell-dotnet-api/seed
  ```
- [ ] Check the bake passed (`content/curve_report.md` says `Validation: PASS`) and that
  `../gridwell-dotnet-api/seed/daily_pool.json` has the new `"start_date"`.
- [ ] Run the tests (the byte-for-byte rebuild test needs the new `assets/puzzles/set.bin`):
  ```
  flutter test
  ```
- [ ] Commit `content/collections.json`, `assets/puzzles/set.bin` and `content/curve_report.md` in the app
  repo, and `seed/daily_pool.json` in the API repo.
- [ ] In the production `.env`, leave `DAILY_START_DATE` **empty**, so the API follows the file's start date.
- [ ] **Order matters.** The API never reassigns a date once scheduled. If the API has already seeded the
  calendar from the placeholder date (any deploy with `DAILY_AUTO_SEED` on), clear the `daily_puzzles`
  table (and any `daily_completions`) before deploying the new seed. Check with
  `SELECT min(date), max(date), count(*) FROM daily_puzzles;` on the `gridwell` database.
- [ ] **[CONFIRM]** what happens after day 90: the bundled pool runs out 90 days after the start date. Plan
  the next pool (and an app update that bundles it) well before then, or confirm the app's fallback.

## 4. Real ad and product IDs

Fill in `MONETIZATION_IDS.md`, then put each value where its "Goes in" column says.

- [ ] AdMob: create the account and the two apps (Android, iOS); create one **rewarded** and one
  **interstitial** unit per platform. No banners.
- [ ] Android app ID in `android/app/src/main/AndroidManifest.xml` (replacing Google's test ID).
- [ ] iOS app ID in `ios/Runner/Info.plist` `GADApplicationIdentifier` (on the Mac, `MAC_CHECKLIST.md` step 4).
- [ ] Ad unit IDs in `lib/services/ads/ad_config.dart` (debug builds keep using Google's test units).
- [ ] AdMob > Privacy & messaging: create and publish the **GDPR** message (EEA/UK) and, if wanted, the
  **US state regulations** message. **[CONFIRM]** the US message decision; `assets/legal/PRIVACY.md` 1.9 depends on it.
- [ ] AdMob > app-ads.txt: publish `app-ads.txt` at the root of the **developer website domain** listed in
  both store listings (**[CONFIRM]** which domain, for example `pranta.dev`), then verify it in AdMob.
- [ ] Product IDs: after the products exist (section 6), set `lib/services/purchases/product_ids.dart` and the
  API's `PRODUCT_REMOVE_ADS`, `PRODUCT_PREMIUM_MONTHLY`, `PRODUCT_PREMIUM_YEARLY`. The two must match.

## 5. Backend: credentials, production `.env`, deploy

All in the API repo (`gridwell-dotnet-api`). See its `CLAUDE.md` and `.env.example`.

### Production `.env` (on the VPS, never committed)

- [ ] Copy `.env.example` to `.env` on the server and fill every value. No defaults exist for credentials.
- [ ] `ASPNETCORE_ENVIRONMENT=Production`.
- [ ] Database: `DATABASE_*` for the shared Postgres server, database name `gridwell`.
- [ ] Redis: `REDIS_*`, `HANGFIRE_REDIS_PREFIX=gridwell_hangfire:`, `HANGFIRE_SERVER_ENABLED=true` on the
  server only (false on every dev machine).
- [ ] `JWT_SECRET_KEY` and `ADMIN_JWT_SECRET_KEY`: fresh, different values:
  ```
  openssl rand -base64 64
  ```
- [ ] **Admin credentials:** `ADMIN_EMAIL` and a long random `ADMIN_PASSWORD` (store it in a password
  manager). Admin login stays disabled until both are set.
- [ ] `HANGFIRE_USERNAME` / `HANGFIRE_PASSWORD` if the `/hangfire` dashboard should be reachable in production.
- [ ] `GOOGLE_APPLICATION_CREDENTIALS` pointing at `firebase-admin-sdk.json`.
- [ ] `GOOGLE_PLAY_SERVICE_ACCOUNT_PATH`, `GOOGLE_PLAY_PACKAGE_NAME=com.pranta.gridwell`,
  `GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN` (random). In Google Cloud, create the Pub/Sub topic for Real-time
  developer notifications, a **push** subscription to
  `https://gridwell.pranta.dev/api/v1/purchases/webhook/google-play?token=<that token>`, and set the topic
  in Play Console > Monetization setup. Grant the service account access in Play Console > Users and
  permissions (view financial data, manage orders and subscriptions).
- [ ] Apple: `APPLE_BUNDLE_ID=com.pranta.gridwell`, `APPLE_KEY_ID`, `APPLE_ISSUER_ID`, `APPLE_PRIVATE_KEY`
  (In-App Purchase key), `APPLE_ENVIRONMENT` (**[CONFIRM]** the expected value in the Options class, for
  production). Paste `https://gridwell.pranta.dev/api/v1/purchases/webhook/app-store` into App Store
  Connect > App Information > App Store Server Notifications (Version 2), for both production and sandbox.
- [ ] `PRODUCT_*` (section 4).
- [ ] `DAILY_START_DATE` empty, `DAILY_AUTO_SEED=true` on the server (section 3).
- [ ] `ALLOWED_ORIGINS=https://gridwell-dashboard.pranta.dev` if the dashboard calls the API from the browser.
- [ ] Credential files at the repo root on the server: `firebase-admin-sdk.json`,
  `google-play-service-account.json` (mounted read-only by `compose.yaml`).

### Database and deploy

- [ ] Apply migrations by hand (they never run at startup), from a machine that can reach the production DB:
  ```
  cd src/Gridwell.Infrastructure
  dotnet ef database update -s ../Gridwell.Api
  ```
- [ ] Deploy the API on the VPS:
  ```
  docker compose up -d --build
  ```
- [ ] Check health and logs:
  ```
  curl -fsS https://gridwell.pranta.dev/health/ready
  docker logs --tail 100 gridwell-api
  ```
  `/health/ready` must return 200 (Postgres reachable). Confirm the daily pool seeded from the new file
  and starts on the chosen date.

### Admin dashboard

- [ ] The dashboard (Svelte 5, `dashboard/` in the API repo) does not exist in the repo yet (checked
  2026-11-03), and its service in `compose.yaml` is commented out. Build it, then uncomment the
  `gridwell-dashboard` service (port 3000, Traefik host `gridwell-dashboard.pranta.dev`) and redeploy.
  **[CONFIRM]** whether the dashboard is required for launch or can follow; the API and Hangfire jobs work
  without it, but sending admin pushes and managing the daily pool need either the dashboard or direct API calls.
- [ ] **Cloudflare DNS:** add a record for `gridwell-dashboard` in the `pranta.dev` zone pointing at the VPS,
  the same type and proxy setting as the existing `gridwell` record (**[CONFIRM]** A record to the VPS IP
  or CNAME, and proxied or DNS-only, matching how Traefik's `letsencrypt` resolver gets certificates for
  the other subdomains). Check:
  ```
  nslookup gridwell-dashboard.pranta.dev
  curl -I https://gridwell-dashboard.pranta.dev
  ```
- [ ] Log in to the dashboard with the admin credentials; confirm a wrong password is rate limited
  (5 tries per 5 minutes).

### MediatR license

- [ ] MediatR 14 (`Gridwell.Application.csproj`, version 14.1.0) is commercially licensed by Lucky Penny
  Software and logs a license warning at startup without a key. Production use needs a license.
  **[CONFIRM]** which license applies (Lucky Penny offers a free Community license for small
  organizations under a revenue threshold; check the current terms at https://luckypennysoftware.com),
  register, and get the key.
- [ ] The API does not read a MediatR license key yet (no `LicenseKey` in the source). Add it to the
  MediatR registration in `AddApplication()` from a typed Options value (for example env
  `MEDIATR_LICENSE_KEY`), add it to `.env.example`, and confirm the startup warning is gone.
  Same as Snake Classic.

## 6. Store products (after approval)

Per the project rule, products are created only **after** each store approves the app. Until then the
app uses placeholder IDs (`remove_ads`, `premium_monthly`, `premium_yearly`) and test products.

- [ ] Google Play > Monetize > Products:
  - [ ] **In-app product** (one-time): Remove Ads, **$1.99**.
  - [ ] **Subscription** "Gridwell Premium" with base plans: monthly **$2.99** and yearly **$14.99**, each
    with a **free trial offer** (**[CONFIRM]** trial lengths). Note the base plan IDs in `MONETIZATION_IDS.md`.
- [ ] App Store Connect:
  - [ ] **Non-consumable** Remove Ads, **$1.99** tier.
  - [ ] **Subscription group** "Gridwell Premium": monthly **$2.99**, yearly **$14.99**, each with a
    **free trial introductory offer**. Add the localized display name and description, and the review
    screenshot of the paywall that every IAP needs.
  - [ ] The first IAPs and subscriptions must be submitted **together with an app version**. Plan a 1.0.x
    update for this.
  - [ ] Paid Applications agreement, tax and banking completed in App Store Connect > Business (IAPs do not
    work in production without it). Google Play: payments profile and merchant account set up.
- [ ] Fill the IDs into the app and the API `.env` (section 4), redeploy the API, release the app update.
- [ ] End-to-end test with license testers (Play) and Sandbox testers (Apple): buy, restore, renew,
  cancel, refund, and confirm the server's entitlement updates through the webhooks.

## 7. Privacy policy hosting

- [ ] Fill every **[CONFIRM]** in `assets/legal/PRIVACY.md` (legal name, address, hosting location, retention
  settings, consent choices).
- [ ] Host it at a stable public HTTPS URL that needs no login. Options (**[CONFIRM]** choice):
  - a page served by the API, for example `https://gridwell.pranta.dev/privacy` (not implemented yet);
  - a static page on the developer website;
  - GitHub Pages from the public app repo.
  A raw `github.com/.../blob/...` link works but looks unofficial, and breaks if the file moves.
- [ ] Put the URL in: Play Console (App content > Privacy policy, and the store listing), App Store Connect
  (App Privacy > Privacy Policy URL), the App Store description (`STORE_LISTING.md`), the in-app privacy
  screen, and AdMob's GDPR message settings.
- [ ] Also host or link a **data deletion** page (can be section 8 of the policy) for Play's Data safety
  "delete data" URL.
- [ ] **Terms of Use:** required on iOS for auto-renewing subscriptions. Either use Apple's standard EULA
  (link it in the description) or host your own. **[CONFIRM]** which.

## 8. Data safety and App Privacy forms

- [ ] Play Console > App content > **Data safety**: enter the answers from `DATA_SAFETY.md` Part 1.
- [ ] Play Console > App content > **Ads**: contains ads = Yes. **Advertising ID**: Yes, advertising and analytics.
- [ ] App Store Connect > **App Privacy**: enter the answers from `DATA_SAFETY.md` Part 2.

## 9. Age rating questionnaires and target audience

The content is a picture puzzle with no violence, no mature themes, no gambling and no chat. Points to
answer carefully:

- [ ] **Google Play, Target audience and content:** choose **13 to 15, 16 to 17, 18 and over** (not under 13).
  "Could the app unintentionally appeal to children?" **[CONFIRM]**; answering honestly matters, since
  Google may review it. Selecting under-13 ages would put the app under the Families policy, which
  requires Families-certified ad SDK settings and child-directed ad requests.
- [ ] **Google Play, Content rating (IARC questionnaire):** category Game (puzzle). No violence, sexuality,
  language, controlled substances, or gambling. Declare **in-app purchases**. For "users can interact or
  exchange content": the only user content is the profanity-filtered pen name shown on leaderboards, with
  no chat or messaging. **[CONFIRM]** the answer; if declared, the rating gains a "Users Interact" notice
  but the age rating should stay the same. Expected result: Everyone / PEGI 3 / USK 0.
- [ ] **App Store, Age Rating:** answer "None" to all content descriptions (violence, horror, mature
  themes, gambling, contests, and so on). No unrestricted web access. For user-generated content and
  messaging: leaderboard pen names only, filtered, no chat (**[CONFIRM]**). Expected rating: **4+**. Do not
  select the Kids category.
- [ ] AdMob: do **not** tag requests as child-directed; set the max ad content rating to suit a general
  audience (**[CONFIRM]** G or PG in AdMob > Blocking controls or in code).

## 10. Store listings and assets

- [ ] Decide the store title (`STORE_LISTING.md`, **Trademark note**). "Picross" is a Nintendo trademark;
  the safer title is "Gridwell: Nonogram Puzzles".
- [ ] Paste the copy from `STORE_LISTING.md` into both consoles; re-check character counts after edits.
- [ ] Capture the eight screenshots in the plan (phone and tablet sizes for Play, iPhone and iPad sizes for
  the App Store) and make the Play feature graphic (1024 x 500).
- [ ] App icon: Play needs a 512 x 512 PNG; iOS uses the 1024 x 1024 icon in the asset catalog.
- [ ] Contact email `prantadutta1997@gmail.com` and website/support URL on both stores.

## 11. Final technical checks before submitting

- [ ] All tests pass: `flutter test` and `dart run tool/check_layers.dart`.
- [ ] US English check from `CLAUDE.md` prints nothing.
- [ ] Performance rerun on an iPhone (`MAC_CHECKLIST.md` step 10) and on any new low-end Android device.
- [ ] Download size under 30 MB per ABI (Play Console > App bundle explorer; App Store Connect > TestFlight
  build > App Store file sizes).
- [ ] Release builds: Crashlytics receives a test crash from a release build on each platform.
- [ ] Fully offline smoke test on a fresh install in airplane mode: the campaign and today's daily both play.
- [ ] Interstitials never show on launch, restart or resume, only after a completion and within the cap.
- [ ] iOS: everything in `MAC_CHECKLIST.md`, including TestFlight.
- [ ] `AppRelease` rows in the API (latest and minimum supported version per platform) set to 1.0.0, with
  store URLs once the listings are live.
