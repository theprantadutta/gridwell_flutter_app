# Splash images

`splash/` holds the native splash images, drawn by `make_splash.py` from the mark's geometry:

- `splash.png`: the transparent cream mark at 512 px (4x, renders at 128 dp)
- `android12.png`: the same 512 px mark centered on a 1152 px transparent canvas, inside
  Android 12's 768 px crop circle

The ground is ink (`#201914`) in both themes, set in `flutter_native_splash.yaml` and in
`SplashScreen.ground`. Keep the two the same.

To regenerate after changing the mark: from the app root, run `python brand/make_splash.py`, then
`dart run flutter_native_splash:create`.

After regenerating, check that `windowDrawsSystemBarBackgrounds` is still `true` in
`android/app/src/main/res/values*/styles.xml` (the generator has been known to flip it).
