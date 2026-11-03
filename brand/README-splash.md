# Splash images

`splash/` holds the native splash images, derived from the logo kit:

- `splash-{light,dark}.png`: the mark at 512 px (4x, renders at 128 dp)
- `android12-{light,dark}.png`: the same 512 px mark centered on a 1152 px transparent canvas,
  inside Android 12's 768 px crop circle

To regenerate after changing the mark: resize `01-mark/png/gridwell-mark-{theme}-1024.png` to
512 px (Lanczos), paste it centered on a 1152 px transparent canvas for the Android 12 variant, then run
`dart run flutter_native_splash:create`.

After regenerating, check that `windowDrawsSystemBarBackgrounds` is still `true` in
`android/app/src/main/res/values*/styles.xml` (the generator has been known to flip it).
