# Google Play: when production access arrives

Gridwell is in Play **closed testing**. Products can only be sold once the app has production access,
so everything below waits for that. Work through it top to bottom; each step says where the value comes
from and where it goes. Related: `MONETIZATION_IDS.md` (every id and price), `STORE_LISTING.md` (listing
text), `LAUNCH_CHECKLIST.md` (the wider launch), and the API repo's `CLAUDE.md`.

**Nothing in the app or the API needs to change for this.** The product ids below are already the ones
`lib/services/purchases/product_ids.dart` and the API's defaults (`ProductOptions`, `ThemeProducts`)
use. If any id is changed in Play Console, it must be changed in both places too.

---

## 1. Payments profile

- [ ] Play Console > Settings > **Payments profile**: merchant account set up, tax and banking details
  complete. Products cannot be activated without it.

## 2. Products to create

Play Console > Gridwell > **Monetize with Play > Products**.

### One-time products (Monetize > Products > **One-time products** > Create)

Each one: product id exactly as below, name, description, a **Buy** purchase option with the price
(US base price; let Play convert the rest), all countries, then **Activate**.

| Product id | Name | Description | Price |
|---|---|---|---|
| `remove_ads` | Remove Ads | No ads between puzzles. Yours to keep. | $1.99 |
| `theme_midnight` | Midnight theme | Deep navy and aqua for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_blossom` | Blossom theme | Soft pink and plum for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_ink` | Ink theme | True black, white and yellow for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_sky` | Sky theme | Pale sky and bright blue for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_ember` | Ember theme | Warm charcoal and orange for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_violet` | Violet theme | Deep violet and lavender for the board, clues and pictures. Yours to keep. | $0.99 |
| `theme_bundle` | All themes | Every Gridwell theme, including future ones. Yours to keep. | $2.99 |

Notes:
- All of these are **non-consumable** (bought once, kept). The app finishes them with
  `isConsumable: false`; never mark them consumable.
- Theme ids follow one rule, `theme_<key>`, which both the app and the API match. A future theme is a
  new palette in `lib/ui/theme/palette.dart`, a new entry in `lib/state/themes.dart` and one more product
  here named `theme_<key>`; the bundle covers it automatically, and the API needs no change.

### Subscription (Monetize > Products > **Subscriptions** > Create)

- [ ] Subscription id **`premium_monthly`**, name "Gridwell Premium (monthly)":
  - base plan id **`monthly`**, auto-renewing, billing period 1 month, **$2.99**.
  - offer: free trial (**[CONFIRM]** length; iOS uses 7 days), eligibility "new customers".
- [ ] Subscription id **`premium_yearly`**, name "Gridwell Premium (yearly)":
  - base plan id **`yearly`**, auto-renewing, 1 year, **$14.99**, same free trial offer.
- [ ] Benefits (shown by Play): "No ads", "Unlimited hints", "Every theme", "Missed dailies free",
  "New collections first".
- [ ] Write the base plan ids into `MONETIZATION_IDS.md` section 3.

The app asks Play for the two subscription ids (`ProductIds.subscriptions`), one base plan each, and
the API verifies whichever plan the token belongs to, so keep **one subscription per plan** as above.

## 3. Server notifications (refunds, renewals, cancellations)

The API learns about renewals, cancellations and refunds (including refunded themes and Remove Ads)
from Google's real-time developer notifications.

- [ ] Google Cloud (the project of the service account) > Pub/Sub > create topic `gridwell-play-rtdn`.
- [ ] Give `google-play-developer-notifications@system.gserviceaccount.com` the **Pub/Sub Publisher**
  role on that topic.
- [ ] Create a **push** subscription on the topic, endpoint:
  ```
  https://gridwell.pranta.dev/api/v1/purchases/webhook/google-play?token=<GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN>
  ```
  The token is the value already in the API's production `.env` (never paste it anywhere public).
- [ ] Play Console > Monetize with Play > **Monetization setup** > Real-time developer notifications:
  topic name `projects/<project-id>/topics/gridwell-play-rtdn`, notification content **All**, then
  **Send test notification** and check the API log shows it received.

## 4. Verification access for the API

- [ ] Play Console > **Users and permissions**: the service account in the API's
  `google-play-service-account.json` has access to Gridwell with **View financial data** and **Manage
  orders and subscriptions**. (It may take up to a day before the Play Developer API accepts it.)
- [ ] API `.env` on the VPS: `GOOGLE_PLAY_PACKAGE_NAME=com.pranta.gridwell`,
  `GOOGLE_PLAY_SERVICE_ACCOUNT_PATH` pointing at the mounted JSON, `GOOGLE_PLAY_PUBSUB_VERIFICATION_TOKEN`
  set. The `PRODUCT_*` values can stay unset (the defaults match the ids above).
- [ ] Migrations applied on the production database (both `InitialCreate` and `AddThemeEntitlements` are
  applied as of 2026-11-15; check with `dotnet ef migrations list -s ../Gridwell.Api` from
  `src/Gridwell.Infrastructure` before any later deploy), then redeploy the API
  (`docker compose up -d --build`) and check `https://gridwell.pranta.dev/health/ready`.

## 5. Test every purchase before release

- [ ] Play Console > Settings > **License testing**: add the tester accounts (for example
  `realjohndoe276@gmail.com`, `test.user@gridwell.app`). Their purchases are free test purchases.
- [ ] Install the current build from the closed track on the A24 with a license tester account, then:
  - [ ] Remove ads screen shows real prices for Remove Ads, Premium monthly and yearly.
  - [ ] Settings > Look > Theme shows **$0.99** on each paid theme and **All themes · $2.99**.
  - [ ] Buy one theme from its preview: it switches on by itself, and stays after a reinstall plus
    **Restore purchase**.
  - [ ] Buy the bundle on a fresh tester: every paid theme opens.
  - [ ] Buy Remove Ads: no interstitials after puzzles.
  - [ ] Start Premium (test renewals are minutes long): every theme opens, hints unlimited. Let it lapse:
    themes bought one by one stay, the others fall back to the standard look.
  - [ ] Refund a theme in Play Console > Order management: after the notification arrives (or the next
    launch), the theme is gone and the standard look is back.
  - [ ] The API's `POST /api/v1/purchases/verify` responses list the bought themes under
    `entitlements.themes` (check the API log or the database's `user_entitlements.themes`).

## 6. Store listing and release

- [ ] Paste the Play description from `STORE_LISTING.md` (it lists the themes and what Premium includes).
- [ ] App content: "Contains ads" Yes; Data safety unchanged by themes (purchases were already declared
  in `DATA_SAFETY.md`; re-check it lists **Purchase history**).
- [ ] Promote the tested closed-track build to **Production**, staged rollout (for example 20%), watch
  Crashlytics and the API log, then raise to 100%.
- [ ] After launch, check AdMob's app-ads.txt status for the Play listing (the file is served at
  `https://pranta.dev/app-ads.txt` and `https://gridwell.pranta.dev/app-ads.txt`).

## 7. App Store

The iOS side (the same products, with `com.pranta.gridwell.` in front of every id) is done on the Mac:
`MAC_CHECKLIST.md` step 8 (local StoreKit testing) and step 13 (App Store Connect theme products).
