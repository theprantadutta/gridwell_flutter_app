# Mac checklist (iOS)

Everything iOS-specific that has to be done on the Mac. Work top to bottom; tick each box. Commands run
from the repo root (`gridwell_flutter_app/`) unless a step says otherwise.

What the repo already has (checked on Windows, 2026-11-03):
- Bundle ID `com.pranta.gridwell` (Runner target, Debug/Release/Profile).
- `IPHONEOS_DEPLOYMENT_TARGET = 15.0` in `ios/Runner.xcodeproj/project.pbxproj`.
- `ios/Runner/Info.plist` with display name "Gridwell", iPhone and iPad orientations, and a `SceneDelegate`.
- `Info.plist` already has the real `GADApplicationIdentifier`, `SKAdNetworkItems` (copied 2026-11-03) and
  `NSUserTrackingUsageDescription`. Re-check them in step 4 rather than adding them again.
- Google and email/password sign-in are built and tested on Android. Apple sign-in is not built yet
  (step 4a).
- **Not yet present:** any `.entitlements` file, a `Podfile`, and a StoreKit configuration file. This checklist adds them.

Never commit `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`, `firebase.json` or any
`.p8` key. The main session (on Windows) does the commits; on the Mac, only commit if you mean to, and
check `git status` first.

---

## 0. Tools

- [ ] Latest stable Xcode from the App Store, opened once to install components.
- [ ] Command line tools selected:
  ```
  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
  sudo xcodebuild -runFirstLaunch
  ```
- [ ] Flutter on the same channel and version as Windows (compare `flutter --version` on both machines).
- [ ] CocoaPods (Firebase and Google Mobile Ads still install through it):
  ```
  brew install cocoapods
  ```
- [ ] Check everything:
  ```
  flutter doctor -v
  ```
- [ ] Get the code and packages:
  ```
  git pull
  flutter pub get
  ```

## 1. Firebase iOS config (`flutterfire configure`)

- [ ] Install the CLIs and sign in:
  ```
  npm install -g firebase-tools
  firebase login
  dart pub global activate flutterfire_cli
  export PATH="$PATH:$HOME/.pub-cache/bin"
  ```
- [ ] Find the project ID (the same Firebase project the Android app uses):
  ```
  firebase projects:list
  ```
- [ ] Configure **both** platforms, so the regenerated `lib/firebase_options.dart` still contains Android:
  ```
  flutterfire configure --project=<firebase-project-id> --platforms=android,ios --ios-bundle-id=com.pranta.gridwell --android-package-name=com.pranta.gridwell
  ```
  If it asks whether to add the Crashlytics dSYM upload build phase, answer **yes** (see step 9).
- [ ] Confirm `ios/Runner/GoogleService-Info.plist` exists and is added to the Runner target in Xcode
  (select the file; "Target Membership: Runner" ticked).
- [ ] Confirm the generated files are ignored and not staged:
  ```
  git check-ignore -v ios/Runner/GoogleService-Info.plist lib/firebase_options.dart firebase.json
  git status --short
  ```
  Each of the three paths must be printed by `check-ignore`, and none may appear in `git status`.
  `flutterfire configure` may also edit `ios/Runner.xcodeproj/project.pbxproj` (file reference and build
  phase); that change is fine to keep.

## 2. APNs key for FCM

FCM delivers to iPhones through Apple Push Notification service, so Firebase needs an APNs key.

- [ ] Apple Developer > Certificates, Identifiers & Profiles > **Keys** > **+**. Name it "Gridwell APNs",
  tick **Apple Push Notifications service (APNs)**, continue, register, **download the `.p8`** (one chance
  only). Note the **Key ID** and your **Team ID** (top right of the developer site).
  One APNs key works for every app in the team and for both sandbox and production.
- [ ] Firebase console > Project settings > **Cloud Messaging** > Apple app configuration (the
  `com.pranta.gridwell` app) > **APNs Authentication Key** > Upload: the `.p8`, Key ID and Team ID.
- [ ] Store the `.p8` in a password manager. Never put it in either repo.

This is a different key from the **In-App Purchase** key the API needs (`APPLE_KEY_ID` etc. in
`MONETIZATION_IDS.md` section 4). Create that one separately in App Store Connect > Users and Access >
Integrations > In-App Purchase.

## 3. App ID and capabilities

- [ ] Apple Developer > Identifiers: register App ID `com.pranta.gridwell` (explicit), with
  **Push Notifications** and **In-App Purchase** enabled. (Xcode's automatic signing can create it, but
  check the capabilities are on.)
- [ ] Open the workspace (always the workspace, never the `.xcodeproj`):
  ```
  open ios/Runner.xcworkspace
  ```
- [ ] Runner target > **Signing & Capabilities** > **+ Capability**:
  - [ ] **Push Notifications.** This creates `ios/Runner/Runner.entitlements` with `aps-environment`.
  - [ ] **Background Modes** > tick **Remote notifications** only. Needed for FCM data messages and for
    `firebase_messaging` background handling. Do not tick Audio: the game's sound is ambient and must not
    keep playing in the background.
  - [ ] **In-App Purchase** (if Xcode lists it; recent Xcode versions add it implicitly).
- [ ] Notification delegate: `flutter_local_notifications` (daily 7 pm reminder) and `firebase_messaging`
  need the `UNUserNotificationCenter` delegate set so notifications show while the app is in the
  foreground. Check `ios/Runner/AppDelegate.swift` against the current iOS setup section of the
  `flutter_local_notifications` README for the version in `pubspec.yaml` (22.x). The project uses the newer
  `SceneDelegate` setup, so follow the README's instructions for that, not an old snippet.

## 4. Info.plist: AdMob, SKAdNetwork, tracking, export compliance

Edit `ios/Runner/Info.plist` (in Xcode or a text editor). Add inside the top-level `<dict>`:

- [ ] **AdMob app ID.** Already set to the real iOS app ID `ca-app-pub-9242904787767394~6672160958`
  (`MONETIZATION_IDS.md` section 1). Just confirm it is there. The app crashes at launch if this key is
  missing once the Mobile Ads SDK is linked.
- [ ] **SKAdNetwork identifiers.** Already present (copied 2026-11-03). Before each release, compare with
  the current list on Google's page and add any new entries:
  https://developers.google.com/admob/ios/quick-start#update_your_infoplist
  It starts with Google's own `cstr6suwn9.skadnetwork` and continues with the partner networks. Paste the
  whole list. Refresh it before each release; Google adds entries.
- [ ] **Tracking prompt text** (already present; from `MONETIZATION_IDS.md` section 5):
  ```xml
  <key>NSUserTrackingUsageDescription</key>
  <string>Your choice lets Gridwell show ads that are less random. The game works the same either way.</string>
  ```
- [ ] **Export compliance.** The app uses only standard HTTPS, which is exempt, so declare it once here and
  TestFlight stops asking on every upload:
  ```xml
  <key>ITSAppUsesNonExemptEncryption</key>
  <false/>
  ```
- [ ] Orientations: phones are portrait-only by design, but `UISupportedInterfaceOrientations` currently
  lists portrait plus both landscapes for iPhone. Check on a phone that the app stays in portrait when
  rotated. If Dart code does not lock it, remove the two landscape entries from the iPhone list (keep all
  four in the `~ipad` list, which iPad multitasking requires).
- [ ] Validate the plist:
  ```
  plutil -lint ios/Runner/Info.plist
  ```

## 4a. Sign-in: Google (finish) and Apple (build)

Google and email/password sign-in already work on Android (`lib/services/auth/auth_service.dart`,
`lib/ui/screens/account_screen.dart`). Email/password needs nothing more on iOS. Google needs URL setup,
and Apple has to be built and tested here, because it needs a real Apple device and an Apple developer account.

**Google on iOS**
- [ ] After `flutterfire configure` (step 1), open `ios/Runner/GoogleService-Info.plist` and copy
  `CLIENT_ID` and `REVERSED_CLIENT_ID`. If they are missing, enable Google in Firebase > Authentication >
  Sign-in method first, then run `flutterfire configure` again.
- [ ] Add to `ios/Runner/Info.plist` (google_sign_in 7.x reads these):
  ```xml
  <key>GIDClientID</key>
  <string>CLIENT_ID value</string>
  <key>GIDServerClientID</key>
  <string>GOOGLE_WEB_CLIENT_ID from .env</string>
  <key>CFBundleURLTypes</key>
  <array>
    <dict>
      <key>CFBundleTypeRole</key><string>Editor</string>
      <key>CFBundleURLSchemes</key>
      <array><string>REVERSED_CLIENT_ID value</string></array>
    </dict>
  </array>
  ```
  If `CFBundleURLTypes` already exists, add the scheme to it rather than adding a second key.
- [ ] Run on an iPhone: Settings > Account > Continue with Google. Check that the Settings row then shows the email.

**Apple (new code, do it here)**
- [ ] Apple Developer > Identifiers > `com.pranta.gridwell`: enable **Sign in with Apple**. In Xcode, Runner >
  Signing & Capabilities > **+ Capability > Sign in with Apple** (adds it to `Runner.entitlements`).
- [ ] Firebase console > Authentication > Sign-in method > **Apple**: enable it. For iOS-only native sign-in
  the Services ID and key fields can stay empty.
- [ ] Code: follow Snake Classic's `signInWithApple` / `linkAnonymousToApple` in
  `snake-classic/snake_classic/lib/services/unified_user_service.dart`, which uses firebase_auth's native
  `AppleAuthProvider` and needs no extra plugin. Add `signInWithApple()` to `AuthService`, routed through
  the existing `_linkOrSignIn` so a guest is upgraded in place. Add it to `AccountActions`
  (`lib/state/account.dart`). Add a "Continue with Apple" button to `AccountScreen` as the **first** button,
  on iOS only, styled per Apple's guidelines. Remove the `TODO(mac)` there. `AccountKind.apple` and the
  backend's `apple.com` mapping already exist.
- [ ] App Store rule 4.8: an app that offers Google sign-in must also offer Sign in with Apple on iOS.
  Do not submit to App Review without it.
- [ ] Test on an iPhone in three cases: a fresh guest links Apple (progress kept), a second device signs in to
  the same Apple ID (progress restored), and "Hide my email" (the relay address appears as the email).
- [ ] Update `assets/legal/PRIVACY.md` (section 1, "Account (optional)") to mention Apple, and mirror it to
  `privacy-project/Projects/gridwell/privacy.md`.

## 5. Minimum iOS version

- [ ] The Xcode project targets **iOS 15.0**. After the first `pod install` (step 6), check that
  `ios/Podfile` was generated and set its platform line to match:
  ```ruby
  platform :ios, '15.0'
  ```
- [ ] If `pod install` reports that a pod requires a higher version (Firebase and Google Mobile Ads raise
  their minimums over time), raise **both** the Podfile line and `IPHONEOS_DEPLOYMENT_TARGET` (Runner target,
  Build Settings, all configurations) to the version the error names. Do not guess a number ahead of the error.
- [ ] Record the final minimum in the App Store Connect notes and in `CLAUDE.md` if it changes.

## 6. Pods and a first debug run

- [ ] ```
  cd ios && pod install --repo-update && cd ..
  ```
- [ ] Run on a real iPhone (the simulator cannot test push, ATT on a real ad ID, or the silent switch):
  ```
  flutter devices
  flutter run -d <iphone-id>
  ```
- [ ] Check in the run log: Firebase initializes (no "Firebase unavailable" line), the consent form logic
  runs, and test ads load (debug builds always use Google's test units).

## 7. Signing

- [ ] Xcode > Settings > Accounts: your Apple ID is signed in and the team is listed.
- [ ] Runner target > Signing & Capabilities: **Automatically manage signing** on, **Team** set, bundle ID
  `com.pranta.gridwell`, for Debug, Profile and Release. No red errors.
- [ ] RunnerTests target: same team (its bundle ID is `com.pranta.gridwell.RunnerTests`).
- [ ] The Team ID ends up in `project.pbxproj` as `DEVELOPMENT_TEAM`. That value is not secret; commit it so
  future Mac builds sign without fiddling.

## 8. StoreKit configuration file for local IAP testing

Lets you buy the three products in Xcode runs without App Store Connect products existing (they are
created only after approval).

- [ ] Xcode > File > New > File > **StoreKit Configuration File**, name `Gridwell.storekit`, save in
  `ios/` and add to the Runner project (not to the app target's resources). Leave "Sync this file with an
  app in App Store Connect" unticked.
- [ ] Add, using the product IDs currently in `lib/services/purchases/product_ids.dart`
  (`remove_ads`, `premium_monthly`, `premium_yearly` as of today; if real IDs from `MONETIZATION_IDS.md` are
  in that file by now, use those):
  - [ ] **Non-Consumable** `remove_ads`, reference name "Remove Ads", price **1.99**.
  - [ ] A **subscription group** "Gridwell Premium" containing:
    - [ ] **Auto-Renewable** `premium_monthly`, "Premium monthly", price **2.99**, duration **1 month**,
      introductory offer **Free**, duration = the trial length from `MONETIZATION_IDS.md`
      **[CONFIRM: trial length]**.
    - [ ] **Auto-Renewable** `premium_yearly`, "Premium yearly", price **14.99**, duration **1 year**,
      introductory offer **Free**, same trial question.
- [ ] Product > Scheme > Edit Scheme > **Run** > Options > **StoreKit Configuration** = `Gridwell.storekit`.
- [ ] Run from **Xcode** (the StoreKit file applies to Xcode-launched runs, not `flutter run` from a
  terminal). Test: buy each product, restore purchases, cancel and expire a subscription in
  Debug > StoreKit > Manage Transactions, refund, and the trial-to-paid transition (speed up renewal in
  Editor > Time Rate).
- [ ] Expected: the app unlocks locally. **Server verification fails** for these transactions, because they
  are signed by Xcode's local certificate, not Apple's. That is normal. End-to-end verification against
  `https://gridwell.pranta.dev` needs Sandbox testers (App Store Connect > Users and Access > Sandbox) and
  real products, after approval.

## 9. Audio session check

The game's sound must be **ambient, mixing with other audio**: it never pauses other apps and it obeys
the silent switch.

- [ ] Start music in Spotify (or Apple Music), then open Gridwell and play a puzzle with sound on:
  - [ ] the music **keeps playing**, uninterrupted and not ducked to silence;
  - [ ] the game's sounds play over it.
- [ ] Flip the **silent switch** (or Action button silent mode) on: the game makes **no sound**. Haptics may
  still play. Flip it off: the game's sound returns.
- [ ] Lock the phone mid-puzzle with music playing: the music continues, and the game makes no sound in the
  background.
- [ ] Take a phone call or trigger Siri mid-puzzle, then return: the game's sound resumes or stays quiet
  correctly, no crash.
- [ ] If any of these fail, check the `audio_session` configuration in the app (it must be the
  `ambient` category with mix-with-others), not iOS settings.

## 10. Performance test on an iPhone

From `docs/PERFORMANCE.md`. Profile mode needs a physical device.

- [ ] ```
  flutter devices
  flutter drive --profile --no-dds -d <iphone-id> \
    --driver=test_driver/perf_driver.dart \
    --target=integration_test/board_perf_test.dart
  ```
- [ ] Results land in `build/board_perf.json`. Add a dated section to `docs/PERFORMANCE.md` in the same
  format as the Android one (device, chip, iOS version, the build and raster table, frames over budget,
  verdict). Use the oldest iPhone available; on ProMotion devices, note that the budget is still judged
  against 16.7 ms.

## 11. Crashlytics symbols

- [ ] Runner target > **Build Phases**: there is a FlutterFire Crashlytics script phase (added by
  `flutterfire configure` in step 1) that uploads dSYMs. If missing, rerun `flutterfire configure` and
  accept the Crashlytics prompt.
- [ ] Build Settings > **Debug Information Format** = "DWARF with dSYM File" for Release.
- [ ] If release builds use `--obfuscate --split-debug-info`, also upload the Dart symbols after each build:
  ```
  flutterfire upload-crashlytics-symbols --upload-symbols-script-path=ios/Pods/FirebaseCrashlytics/upload-symbols --debug-symbols-path=build/symbols --platform=ios
  ```
  **[CONFIRM]** whether release builds are obfuscated; if not, skip this.

## 12. Build and upload to TestFlight

- [ ] Set the version in `pubspec.yaml` (`version: x.y.z+build`). The build number must increase on every
  upload.
- [ ] Before a **store** build, check: real `GADApplicationIdentifier` (step 4), real ad unit and product IDs
  from `MONETIZATION_IDS.md` (once they exist), `daily_start_date` final (see `LAUNCH_CHECKLIST.md`).
- [ ] App Store Connect > Apps > **+** > New App: platform iOS, name (see `STORE_LISTING.md`), primary
  language English (U.S.), bundle ID `com.pranta.gridwell`, SKU `gridwell-ios`.
- [ ] Build the archive and IPA:
  ```
  flutter clean
  flutter pub get
  cd ios && pod install && cd ..
  flutter build ipa --release
  ```
  Output: `build/ios/archive/Runner.xcarchive` and `build/ios/ipa/*.ipa`.
- [ ] Upload, either way:
  - Xcode Organizer: `open build/ios/archive/Runner.xcarchive`, then **Distribute App** > App Store Connect
    > Upload; or
  - Apple's **Transporter** app: drag in `build/ios/ipa/*.ipa`.
- [ ] Generate the privacy report from the archive (Organizer > right-click archive > Generate Privacy
  Report) and compare it with `docs/DATA_SAFETY.md` Part 2.
- [ ] App Store Connect > TestFlight: wait for processing, answer any compliance question (should be skipped
  thanks to `ITSAppUsesNonExemptEncryption`), add yourself as an **internal tester**, install via the
  TestFlight app.
- [ ] On the TestFlight build, verify: first launch fully offline (airplane mode) plays a campaign plate and
  today's daily; ATT prompt shows with the right text; notification permission is asked after the first
  solve; a push sent from the admin dashboard arrives; the 7 pm local reminder fires (temporarily set the
  device clock if needed); account deletion works.
- [ ] For external testers, submit the build for **Beta App Review** with a short "What to test" note.
