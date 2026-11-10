# Gridwell: Nonogram Picross (Flutter app)

Commercial nonogram/picross game for **Android and iOS from day one**. Pure Flutter, no game engine.
Sister repo: `gridwell-dotnet-api` (private; ASP.NET Core API + Svelte 5 admin dashboard). The two are
independent git repos. Never create a repo in the parent `Gridwell/` folder.

Work on `master`, commit small meaningful units, push to `origin` (public GitHub repo).
Commit messages: no co-author/attribution trailers, and no mention of AI tools or model names.

## Non-negotiables

- **Fully offline.** No network call may ever block gameplay. The backend is optional enrichment
  (sync, daily puzzle, leaderboards, purchase verification).
- **No puzzle ever needs guessing.** Every shipped puzzle (campaign and daily) is line-solvable to completion
  AND has exactly one solution (independent backtracking oracle). Enforced by `tool/` at bake time.
- **Small download** (target < 30 MB per ABI). Fonts and assets are bundled; nothing is fetched at runtime.
- **US English everywhere** (code, copy, identifiers): "color", not "colour". Check before committing:
  ```
  git grep -nIiE "colour|favourite|behaviour|centre|honour|licence|analys(e|ing)|organis|initialis|optimis|normalis|serialis|recognis|catalogue|greyscale|\bgrey\b" -- . ':!*.lock' ':!CLAUDE.md'
  ```
  Must print nothing (except quoted third-party names, which need a comment explaining why).

## Architecture and layering

State management is **Riverpod with hand-written providers only**. No riverpod_generator, no
`@riverpod` annotations. Riverpod is the DI container; no get_it.
`build_runner` is allowed **only for drift** (local database).

| Folder | May import | Contents |
|---|---|---|
| `lib/engine/` | `dart:core`, `dart:math` only | Puzzle/board/clue value types, line solver, fixpoint propagation, uniqueness oracle, difficulty, hints, proven mistakes |
| `lib/content/` | `engine/`, `dart:typed_data`, `dart:io`, `dart:convert` | Decoder for the baked puzzle asset |
| `lib/data/` | `engine/`, `content/`, drift, http | Local DB (drift), API client, sync outbox |
| `lib/services/` | platform plugins | Interfaces + implementations: analytics, ads, purchases, audio, haptics, notifications, auth, crash |
| `lib/state/` | `engine/`, `content/`, `data/`, `services/` | Riverpod providers and notifiers |
| `lib/ui/` | `state/`, engine **value types only** (`engine/model/`) | Theme tokens, widgets, screens |

`dart run tool/check_layers.dart` enforces this and exits non-zero on any violation. Planted
violation fixtures in `test/layering/fixtures/` prove that the check catches each rule.

## Game rules and decisions

- Cell states: `empty` (untouched), `filled`, `crossed`. **Win = every solution cell is filled**. Crosses are
  bookkeeping and never affect the win check. Extra filled cells outside the solution do block the win.
- **Proven mistakes** (setting, default ON): flag a cell only if (a) its own row or column, given the player's
  other marks, rules it out, AND (b) it truly contradicts the solution. Never flags a correct cell.
- **Hints**: 3 free per puzzle, then rewarded video. A hint reveals the next cell pure line logic forces,
  with the reasoning. Reward is granted only if the hint resolves a cell (enforced in the type).
  "Undo hint" removes the cell but the hint stays spent.
- **Undo**: unlimited, always free. One drag = one undo step.
- **Timer**: visible by default, can be hidden, always recorded. Best time stored per puzzle; completion
  screen also celebrates a new best for that size.
- **Progression**: all free collections and plates are open; the next unsolved plate is suggested.
  Premium-only collections are locked for free users.
- **Daily**: rollover at local midnight. App caches upcoming dailies when online. Missed days are locked;
  one rewarded ad unlocks a day (free for premium); late solves never count for the leaderboard.
- **Leaderboard names**: generated pen name, editable, profanity-filtered.
- **Notifications**: permission asked after the first solve. The daily reminder is a local scheduled
  notification at 19:00 local time, skipped if today's daily is solved. Server push is for re-engagement and announcements only.
- **Monetization**: rewarded video (hints, reveal line, missed dailies); between puzzles an optional rewarded interstitial (bonus hint, skippable intro) or an interstitial, only after completion,
  frequency-capped, never early, never on restart or resume; **no banners**. $1.99 one-time Remove Ads
  (interstitials only). Premium subscription $2.99/mo and $14.99/yr with trials on both, unlocking everything.
  Store products are created only after store approval; until then use placeholder IDs and test products.
- **Audio**: ambient / mix-with-others on both platforms. Never pauses other audio, honors the iOS silent switch.
- **Layout**: phones portrait-only; tablets adaptive, both orientations; iPad first-class. 20x20 on narrow
  phones uses pinch-zoom with pinned clues.

## Design: Tally

Bold, numeric, edge to edge (kit v2.0, replaces Folio). Square corners everywhere, huge tabular numbers,
full-width slabs separated by 1 pt `--sunk` gaps, and **one** accent: lime, which always means "press
this" or "you are here". No gradients, glows or shadows.
Source kit: `C:\Users\pranta\Downloads\gridwell-tally-kit` (start with `04-design-system/DESIGN-SPEC.md`;
screens in `01-app-screens/`). Logo: the "Clue G" icon kit (`C:\Users\pranta\Downloads\gridwell-icons-clue-g`:
a solved 5 × 5 nonogram drawing a G, top-right cell lime), copied into `brand/` with the store assets; the
wordmark keeps its lime-dot ı.
Typeface: **Schibsted Grotesk only** (bundled static weights 500/700/800/900 in `assets/fonts/`), tabular
figures for every number. Tokens: `lib/ui/theme/palette.dart` (dark, light, high contrast); type:
`lib/ui/theme/typography.dart`; shared components: `lib/ui/widgets/tally.dart`.
The theme follows the system by default (System / Light / Dark in Settings). The three cell states differ
by shape (solid square / short dash / empty), never by color alone. The CVD + legibility harness in
`test/legibility/` must pass before palette changes are committed.
The kit's copy is British in places ("colour"); the app is always US English.

## Content pipeline (`tool/`)

picture (text art in `content/plates/`) → clue derivation → line-solvability → uniqueness → difficulty → bake.
- `--seed` is explicit (fixed default). `assets/puzzles/set.bin` is committed and must regenerate byte-for-byte (tested).
- The asset carries `puzzleSetVersion`. Progress rows store the version they were earned against.
- The curve report and validator gate every bake (line-solvable, unique, no duplicates, no early cliffs, breathers in window).
- Art is authored in-house; third-party art is CC0 only, with every source recorded in `content/PROVENANCE.md`.
- The daily pool is a separate seed and set. It is exported as JSON into the API repo's seed folder.

## Environment (`.env`) and accounts

- `.env` (gitignored, a bundled asset, so public values only) holds `GOOGLE_WEB_CLIENT_ID`,
  `DEV_API_BACKEND_URL` and `PROD_API_BACKEND_URL`. The template is `.env.example`. There are **no fallbacks**:
  a missing file fails the build, and a missing value throws at startup (`lib/services/config/app_env.dart`).
- Debug and profile builds use DEV, release builds use PROD. `--dart-define=API_ENV=prod` points a debug
  build at production without editing `.env`.
- Accounts: everyone starts as an anonymous Firebase guest. Google and email/password sign-in are optional
  (Settings > Account, plus a one-time offer on the completion screen after 3 book plates). **Never ask
  at first launch.** A guest who signs up is linked in place (same UID). Signing in to an existing account
  pulls cloud progress, merges it monotonically (`ProgressRepository.mergeRemote`) and uploads the
  device's solves. Sign-out keeps local progress. Apple sign-in: `docs/MAC_CHECKLIST.md` step 4a.
- Firebase console must have the Anonymous, Email/Password and Google providers enabled. The SHA-1
  fingerprints of the debug key, upload key and Play app-signing key must be registered for Google sign-in.

## Test accounts

- Google Play review accounts, created by `dotnet run manage-test-users.cs` in the API repo:
  `test.user@gridwell.app` (free) and `test.user.premium@gridwell.app` (premium).
- `dotnet run grant-premium-to-user.cs -- grant <email>` in the API repo gives one existing user premium.
  `realjohndoe276@gmail.com` is the premium test account on the A24 and the tablet, used for store shots.
- `--dart-define=GW_SEED=true` (debug builds only, `lib/state/dev_seeder.dart`) solves plates for a signed-in
  test account so screens look lived in. Only ever seed test accounts.

## Firebase and platform notes

- Firebase client config (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`,
  `firebase.json`) is gitignored. Regenerate with `flutterfire configure`.
- iOS builds and `GoogleService-Info.plist` live on the Mac. Mac-side checklist: `docs/MAC_CHECKLIST.md`.
- Some packages (go_router 18+, etc.) pull in `package:material_ui`. Keep `material_ui` as a direct
  dependency and register `material_ui.GlobalMaterialLocalizations.delegates` next to Flutter's
  delegates on every MaterialApp.

## Commands

```
flutter test                      # all tests
flutter test test/engine          # engine only
dart run tool/check_layers.dart   # layering check
```
