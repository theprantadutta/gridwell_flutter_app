# Performance

Target: 60 fps (16.7 ms per frame) on a low-end Android device, measured on hardware, never assumed.

## How to measure

```
flutter drive --profile --no-dds -d <device> \
  --driver=test_driver/perf_driver.dart \
  --target=integration_test/board_perf_test.dart
```

The test drives sustained drag-painting (full rows and columns, fill then erase) on the densest
20x20 board and writes engine FrameTiming summaries to `build/board_perf.json`.

## Results

### 2026-11-02, Samsung Galaxy Tab A9 (SM-X115), Helio G99, 4 GB RAM, Android 16, profile build

2,297 frames of 20x20 drag-painting:

| | Average | p90 | p99 | Worst |
|---|---|---|---|---|
| Build (ms) | 3.04 | 9.22 | 12.75 | 20.52 |
| Raster (ms) | 8.99 | 11.07 | 12.52 | 26.69 |

- Frames over budget: 3 build and 1 raster (0.17%).
- GC: 166 young-generation and 8 old-generation collections.

Verdict: p99 is within the 16.7 ms budget for both build and raster. Rerun this on an iPhone from
the Mac and on any new low-end Android device before release.
