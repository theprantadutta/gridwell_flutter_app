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
- **Monetization**: rewarded video (hints, reveal line, missed dailies); interstitial only after completion,
  frequency-capped, never early, never on restart or resume; **no banners**. $1.99 one-time Remove Ads
  (interstitials only). Premium subscription $2.99/mo and $14.99/yr with trials on both, unlocking everything.
  Store products are created only after store approval; until then use placeholder IDs and test products.
- **Audio**: ambient / mix-with-others on both platforms. Never pauses other audio, honors the iOS silent switch.
- **Layout**: phones portrait-only; tablets adaptive, both orientations; iPad first-class. 20x20 on narrow
  phones uses pinch-zoom with pinned clues.

## Design: Folio

Puzzle-book look: cream paper, ink, hairline rules, numbered plates, a "Contents" home.
Source mocks: `C:\Users\pranta\Downloads\Gridwell design directions exploration\export\gridwell-folio-screens`.
Typeface: **Literata only** (bundled variable font), tabular lining figures for every number.
Palette is semantic tokens with light, dark, and high-contrast variants. The three cell states differ
by shape (solid fill / × mark / empty), never by color alone. The CVD + legibility harness in
`test/legibility/` must pass before palette changes are committed.

## Content pipeline (`tool/`)

picture (text art in `content/plates/`) → clue derivation → line-solvability → uniqueness → difficulty → bake.
- `--seed` is explicit (fixed default). `assets/puzzles/set.bin` is committed and must regenerate byte-for-byte (tested).
- The asset carries `puzzleSetVersion`. Progress rows store the version they were earned against.
- The curve report and validator gate every bake (line-solvable, unique, no duplicates, no early cliffs, breathers in window).
- Art is authored in-house; third-party art is CC0 only, with every source recorded in `content/PROVENANCE.md`.
- The daily pool is a separate seed and set. It is exported as JSON into the API repo's seed folder.

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
