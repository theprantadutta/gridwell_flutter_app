# Splash images

`splash/` holds the native splash images, drawn by `make_splash.py` from the Clue G mark's geometry
(a solved 5 × 5 nonogram that draws a G, icon kit "Clue G"):

- `splash-light.png`, `splash-dark.png`: the transparent mark at 416 px (4x, renders at 104 dp) in
  each theme's colors (filled and empty cells differ; the lime cell is the same)
- `android12-light.png`, `android12-dark.png`: the same mark centered on a 1152 px transparent canvas,
  inside Android 12's 768 px crop circle

The ground is each theme's page color (`--bg`): `#F6F8F0` light, `#071A13` dark, set in
`flutter_native_splash.yaml`. The Flutter splash (`lib/ui/screens/splash_screen.dart`) paints the same
mark at the same size and position, so the hand-off is invisible. Keep them in step.

To regenerate after changing the mark: from the app root, run `python brand/make_splash.py`, then
`dart run flutter_native_splash:create`.

After regenerating:

- check that `windowDrawsSystemBarBackgrounds` is still `true` in
  `android/app/src/main/res/values*/styles.xml` (the generator flips it), and that the status and
  navigation bar colors in those files still match `--bg`;
- revert the generator's reformatting of `ios/Runner/Info.plist` (`git checkout ios/Runner/Info.plist`);
  it only rewrites whitespace and the status-bar key we already have.
