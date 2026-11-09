# Gridwell logo kit · v2.0 (Tally, L6 "Wordmark Cells")

The dot of the i in "Gridwell" is a single filled cell in lime. The app icon is that cell in context: a 2 × 2 grid with one square inked and one square solved.
Open `05-brand-sheet/gridwell-brand-sheet.png` first.

```
01-mark/
  svg/  gridwell-mark-{dark,light,mono-ink,mono-white}.svg   vector, use these first
  png/  same four at 256 and 1024 px, transparent
02-lockups/
  svg/  gridwell-lockup-{horizontal,stacked}-{dark,light}.svg, gridwell-wordmark-{dark,light}.svg   text converted to outlines
  png/  the same at 2x, transparent
03-app-icon-ios/
  AppIcon.appiconset/   drop-in Xcode asset: default, dark and tinted, 1024 px
  AppIcon-1024(.svg, -dark.svg)   vector masters
04-app-icon-android/
  res/                  drop-in Android resources (adaptive + monochrome + legacy mipmaps)
  png-layers-432/       adaptive layers as PNG
  play-store-512.png    Google Play hi-res icon
05-brand-sheet/
  gridwell-brand-sheet.png
```

"dark" variants are for dark backgrounds, "light" variants for light backgrounds. Mono versions: filled cells solid, empty cells outlined, one color.

## Install: iOS (Xcode 15+)
1. Open `Assets.xcassets`, delete the existing `AppIcon`, drag in `03-app-icon-ios/AppIcon.appiconset`.
2. It contains the default (opaque, Tally green), dark (transparent background) and tinted (grayscale) appearances.

## Install: Android
1. Copy `04-app-icon-android/res/` into `app/src/main/res/`, overwriting `ic_launcher*`.
2. Manifest: `android:icon="@mipmap/ic_launcher"`, `android:roundIcon="@mipmap/ic_launcher_round"`.
3. Adaptive icon: vector foreground (mark 48 dp in the 108 dp canvas, inside the 66 dp safe zone) on `#071A13`. Android 13+ themed icons use the monochrome layer.
4. Upload `play-store-512.png` as the Play Console hi-res icon.

## Colors
| Name | Hex | Used for |
|---|---|---|
| Tally green | #071A13 | App icon background, dark theme page |
| Chalk | #F0F3E8 | Inked cell and wordmark on dark |
| Track (dark) | #1C3329 | Empty cells of the mark on dark |
| Lime | #C1EE66 | The solved cell and the i dot. Always lime |
| Paper | #F6F8F0 | Light theme page |
| Ink | #0D1F16 | Inked cell and wordmark on light |
| Track (light) | #D2DBCE | Empty cells of the mark on light |

## Rules
- Clear space: one cell on every side (10/21.5 of the mark's width). Minimum: mark 16 px, wordmark 18 px cap height.
- Lime cell always bottom-right and always lime. Never rotate, recolor, outline the color mark, or add gradients, glows or shadows.
- On photos or busy backgrounds use the mono mark.
