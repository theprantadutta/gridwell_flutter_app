# Gridwell icons · L1 "Clue G"

The icon is a solved 5 × 5 nonogram that draws a G. The top-right cell is lime: the square you just solved.
This pack replaces every icon from the earlier L6 kit. It has icons only, no screens or design docs.

```
01-mark/                 the G mark alone: svg + png (256, 1024), transparent
  dark        for dark backgrounds (chalk cells, lime cell, faint empty cells)
  light       for light backgrounds
  mono-ink / mono-white   one color, empty cells dropped
02-app-icon-ios/
  AppIcon.appiconset/    drop into Assets.xcassets: default, dark and tinted (iOS 18), 1024 px
  AppIcon-1024*.svg      vector masters
03-app-icon-android/
  res/                   copy into app/src/main/res/ (adaptive + monochrome + legacy mipmaps, square and round)
  png-layers-432/        adaptive layers as PNG
04-store-icons/
  play-store-512.png     Play Console hi-res icon
  app-store-1024.png     App Store icon (no alpha)
05-extras/
  gridwell-icon-clued-dark / clued-lime   the G with its row and column clues (512, 1024): for marketing, social, press
  gridwell-icon-lime                      the G on lime (512, 1024)
flutter_launcher_icons.yaml   optional config if you generate sizes with flutter_launcher_icons
```

The launcher and store icons use the clean G **without** clue numbers on purpose: the clues turn to noise at
home-screen size (48 dp). The clued version is in 05-extras for places where the icon is shown large.

## Install: iOS
In Xcode, open Assets.xcassets, delete AppIcon, and drag in `02-app-icon-ios/AppIcon.appiconset`.

## Install: Android
Copy `03-app-icon-android/res/` into `app/src/main/res/`, overwriting the `ic_launcher*` files. The manifest keeps
`android:icon="@mipmap/ic_launcher"` and `android:roundIcon="@mipmap/ic_launcher_round"`.
The adaptive icon is a vector foreground (G mark 46 dp in the 108 dp canvas, inside the circular 66 dp safe zone) on #071A13.
Android 13+ themed icons use the monochrome layer.

## Install: stores
Play Console → Main store listing → App icon: `04-store-icons/play-store-512.png`.
App Store Connect takes the icon from the app build (the 1024 in the asset catalog); `app-store-1024.png` is the same image.

## Colors
| Name | Hex |
|---|---|
| Background (Tally green) | #071A13 |
| Filled cells (chalk) | #F0F3E8 |
| Solved cell (lime) | #C1EE66 |
| Empty cells on dark | #12271E |
| Filled cells on light | #0D1F16 |
| Empty cells on light | #D2DBCE |

## Geometry
5 × 5 grid of 10-unit cells with 1.5-unit gaps (56 units across). Filled rows: `####L`, `#....`, `#.###`, `#...#`, `#####`
(L = the lime cell). App icons: the mark is 60% of the canvas, centered.
