# Gridwell logo kit · v1.0

The Gridwell mark is a G drawn as a solved 5×5 nonogram. One red-orange (vermilion) cross marks a square proven empty.
Open `05-brand-sheet/gridwell-brand-sheet.png` first for the visual guidelines.

## What's inside

```
01-mark/
  svg/  gridwell-mark-{light,dark,mono-ink,mono-white}.svg   vector, use these first
  png/  same four variants at 256 and 1024 px, transparent background
02-lockups/
  gridwell-lockup-horizontal-{light,dark}.png   mark + wordmark + tagline (4x, transparent)
  gridwell-lockup-stacked-{light,dark}.png
  gridwell-wordmark-{light,dark}.png            wordmark only
03-app-icon-ios/
  AppIcon.appiconset/        drop-in Xcode asset (light, dark, tinted, 1024 px)
  AppIcon-1024(.svg, -dark.svg)   vector masters
04-app-icon-android/
  res/                       drop-in Android resources (adaptive + legacy)
  png-layers-432/            adaptive layers as PNG, if your tooling wants bitmaps
  play-store-512.png         Google Play listing icon
05-brand-sheet/
  gridwell-brand-sheet.png   one-page guidelines
```

"light" variants are for light backgrounds and "dark" variants are for dark backgrounds.
The mono versions are a single colour. Use them for small sizes, one-colour print, and photos or busy backgrounds.

## Install: iOS (Xcode 15+)

1. In Xcode, open `Assets.xcassets`.
2. Delete the existing `AppIcon`, then drag in `03-app-icon-ios/AppIcon.appiconset`.
3. The asset contains the light, dark and tinted (iOS 18) appearances. Xcode generates every other size from the 1024 px image.

If Xcode or App Store Connect rejects the light icon because of an alpha channel, strip the alpha channel and reimport:
`magick AppIcon-1024.png -alpha off AppIcon-1024.png` (ImageMagick), or export it from Preview with "Alpha" unchecked.

## Install: Android (Android Studio)

1. Copy the contents of `04-app-icon-android/res/` into `app/src/main/res/`, merging folders and overwriting any existing `ic_launcher*` files.
2. In `AndroidManifest.xml`, check that the app uses `android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher_round"`.
3. Android 8+ uses the adaptive icon: a vector foreground on a `#FCF9F3` background.
   Android 13+ also uses the monochrome layer for themed icons. Older devices use the PNG mipmaps.
4. Upload `play-store-512.png` as the hi-res icon in Play Console.

## Colours

| Name | Light theme | Dark theme | Used for |
|---|---|---|---|
| Ink | #201914 | #E7E1D3 | Filled cells, frame, wordmark |
| Paper | #F7F3EB | #17130F | Background behind the logo |
| Cell (empty) | #FCF9F3 | #1D1814 | Empty cells, app icon background |
| Rule (gaps) | #C9C3BA | #37322C | Hairlines between cells |
| Vermilion | #C44323 | #EB7A52 | The cross, tagline |

These are the in-app tokens `--ink`, `--paper`, `--paper-2`, `--rule` and `--accent`, converted to hex.

## Type

- Wordmark: **Literata Medium (500)**, tracking −2%.
- Tagline "NONOGRAM · PICROSS": Literata Medium, all caps, tracking +24%, in vermilion.
- Literata is free under the SIL Open Font License: https://fonts.google.com/specimen/Literata
- The lockups are supplied as PNG. If you need a vector lockup, set the wordmark in Literata next to the SVG mark and convert the text to outlines in your design tool.

## Rules

- **Clear space:** keep at least one cell's width clear on every side (1/5 of the mark's width).
- **Minimum size:** mark 20 px (6 mm in print), lockup 22 px mark height (25 mm wide). Drop the tagline when the lockup is under 160 px wide.
- **Don't:** stretch, rotate, recolour the cross or cells, add effects or shadows, remove the cross, or place the full-colour mark on mid-tone or busy backgrounds (use the mono mark instead).

## Mark geometry

- 5×5 grid: 24-unit cells with 1.5-unit gaps, and a 2.5-unit frame around the outside. The mark is 131 units square.
- Filled cells by row: `.####`, `#....`, `#..##`, `#...#`, `.###.`
- The cross sits in row 3, column 2. It is two 2.5-unit strokes crossing at 45°, each 16 units long.
- iOS icon: the mark fills 69% of the 1024 px canvas.
- Android adaptive icon: the mark is 48 dp inside the 108 dp canvas, so it fits within the 66 dp safe zone.
