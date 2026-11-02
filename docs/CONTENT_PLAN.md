# Content plan (v1)

Every puzzle is a pixel-art picture. The reveal is the reward, so each picture must read
clearly at its size. Every picture is authored in this repo; see `content/PROVENANCE.md`.

## Collections

All four v1 collections are free and open from the start. Premium early access starts with
collection V (Night Garden, post-launch).

| # | Id | Name | Plates | 5x5 | 10x10 | 15x15 | 20x20 | Theme |
|---|---|---|---|---|---|---|---|---|
| I | `coastline` | Coastline | 30 | 6 | 12 | 8 | 4 | Harbor and shore: boats, shells, gulls, lighthouses |
| II | `botanica` | Botanica | 36 | 5 | 13 | 11 | 7 | Leaves, flowers, fruit, garden things |
| III | `bestiary` | Bestiary | 40 | 4 | 12 | 14 | 10 | Animals, from a snail to a whale |
| IV | `small-hours` | Small Hours | 44 | 3 | 11 | 16 | 14 | Night and home: lamps, teacups, moons, owls |
| | | **Total** | **150** | 18 | 48 | 49 | 35 | |

Size columns count square-ish plates. Rectangles (for example 10x15 for a tall lighthouse)
are allowed; they count toward the nearest size by cell count.

Each collection ramps on its own from easy to hard. All collections are open from the start,
so each has to be a fair place to begin. Later collections start a little higher and reach higher.

## Daily pool

90 pictures, separate from the campaign and never repeated in it. Sizes: 40 at 10x10, 45 at
15x15, 5 at 20x20. Difficulty is capped at the campaign's 80th percentile, because quitting a
daily is worse than quitting a campaign puzzle. Exported to the API repo as `daily_pool.json`.

## Picture format

`content/campaign/<collection>/<slug>.txt` and `content/daily/<slug>.txt`:

```
name: Lighthouse
source: original
---
.....r.....
....rrr....
...........
```

- Header lines are `key: value` up to `---`. `name` is required. `source` is required:
  `original` for in-house art, otherwise a CC0 reference recorded in PROVENANCE.md.
- Grid characters: `.` background (empty in the solution), `k` ink, `r` red, `o` ochre,
  `s` stone, `i` indigo. These are the Folio picture palette (art-b, art-a, art-c, art-d, art-e).
- The solution is every non-background cell. Color is shown only in the revealed picture,
  since the puzzle itself is monochrome.
- The id is `<collection>-<slug>` (campaign) or `daily-<slug>`.

## Pipeline

picture → clues → line-solvable? → unique? → difficulty → order → validate → bake.

- A picture that fails line-solvability or uniqueness is rejected. `tool/gridwell.dart nudge`
  suggests the fewest single-pixel changes that fix it. A nudge is applied by editing the
  art by hand, never automatically, so a changed picture always gets a human look.
- Plate numbers are assigned by the tool, not by file names: plates are sorted by difficulty
  within each collection, then size gates and breathers are applied.

## Curve rules (validator)

Applied to every collection:

1. **Gentle start:** the first 5 plates score at most 20 (out of 100).
2. **No early cliffs:** within the first 20 plates, no plate scores more than 10 above the previous
   non-breather plate. Climbing back to the curve after a breather is not a cliff.
3. **Monotonic within tolerance:** apart from breathers, each plate scores at least the running maximum minus 4.
4. **Breathers:** from plate 10 on, every 6th plate (10, 16, 22, 28, ...) is a breather. It must score
   between 15% and 35% below the mean of the 4 plates before it. Breathers are excluded from the running maximum.
5. **Size gates:** no 15x15-class plate before plate 6, and no 20x20-class plate before plate 12.
6. Every plate is line-solvable and unique (oracle complete, count 1).
7. No two pictures share a solution grid (across campaign and daily).

Daily pool: every puzzle line-solvable and unique, no duplicates, score ≤ campaign p80.

## Determinism and versioning

- `--seed` (default 20261102) drives every tie-break: ordering ties, breather selection, nudge
  candidate order, daily pool order.
- `assets/puzzles/set.bin` is committed, and a test rebuilds it and compares it byte for byte.
- The asset header carries `puzzleSetVersion`. Bump it whenever any shipped puzzle changes.
  Progress rows store the version they were earned against.
- The asset is bit-packed (3 bits per cell) and stored uncompressed, which keeps the bytes
  identical across SDK and zlib versions. The APK and IPA zip it anyway.
