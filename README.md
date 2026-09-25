# Zikr — Offline Tasbeeh Counter

A fully offline Android dhikr counter built in Flutter. All data (counts,
presets, stats, settings) lives in Hive on-device — no accounts, no
network calls, no cloud.

## Features

- Full-screen tap counter with a 150ms debounce and light haptic feedback.
- Volume-button counting: pick Volume Up or Volume Down to count with;
  the other volume button keeps controlling media volume normally. Works
  while the screen is off/locked via a foreground service + an
  Accessibility Service that listens for the key (see **Volume-button
  counting: how it works, and its limits** below — please read this
  before relying on it).
- Reset (behind a confirmation dialog) that clears only the active
  preset's current count — daily/weekly/monthly/yearly totals only ever
  accumulate.
- Day / Week / Month / Year aggregate stats, with a history list of past
  periods.
- Daily reminder notification at a time you pick, scheduled with an exact
  alarm that survives a reboot.
- Five built-in presets (SubhanAllah, Alhamdulillah, Allahu Akbar,
  La ilaha illallah, Astaghfirullah) plus your own custom dhikr + target,
  each with its own independent count.

## Project layout

```
lib/
  models/       Plain Dart models (TasbeehPreset)
  services/      HiveService (persistence), NativeBridge (MethodChannel
               to Android), CounterProvider (app state)
  screens/       HomeScreen, SettingsScreen, StatsScreen
  widgets/       TasbeehDisplay
android/app/src/main/kotlin/com/afzal/zikr/
  MainActivity.kt                  MethodChannel handler + foreground key handling
  ForegroundCountingService.kt     Keeps the "counting active" notification up
  VolumeKeyAccessibilityService.kt Intercepts the chosen volume key screen-off
  ReminderReceiver.kt / BootReceiver.kt / ReminderScheduler.kt
  Prefs.kt / Notifications.kt      Shared SharedPreferences + notification helpers
```

## Setup / build / run

Requires the Flutter SDK (stable channel) and an Android toolchain
(JDK 17). No native build step in this repo needs internet access at
runtime — everything is offline once installed.

```bash
flutter pub get
flutter run                 # install to a connected device/emulator
flutter build apk --release # produces build/app/outputs/flutter-apk/app-release.apk
```

The included `.github/workflows/build-apk.yml` does the same in CI on
every push to `main` (and via the "Run workflow" button), and uploads the
resulting APK as a downloadable workflow artifact — no local Android
setup needed to get an installable build.

## Play Store signing

The release build type is **debug-signed by default** so it builds and
installs with zero setup, which is fine for sideloading/testing but not
for a Play Store submission. Before publishing:

1. Create a real keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
2. Add a `key.properties` file (already gitignored) next to `build.gradle` with `storePassword`, `keyPassword`, `keyAlias`, `storeFile`.
3. In `android/app/build.gradle`, read `key.properties` and add a
   `signingConfigs.release` block that uses it, then point
   `buildTypes.release.signingConfig` at it instead of `signingConfigs.debug`.
4. For CI, store the keystore and its passwords as GitHub Secrets
   (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`),
   decode the base64 secret to a file in a workflow step before
   `flutter build apk --release`, and reference that path from
   `key.properties`/`build.gradle`.

This is intentionally left as a manual step rather than built in, so no
real signing secrets ever end up committed to a shared prompt/repo.

## Volume-button counting: how it works, and its limits

There is no public Android API letting a normal app claim a volume key
system-wide the way a media app claims play/pause. Zikr's approach:

- While the app is **on screen**, `MainActivity.dispatchKeyEvent`
  intercepts the chosen key directly and consumes it (no volume UI, and
  a tick is registered instantly).
- While the app is **backgrounded or the screen is off**, an
  `AccessibilityService` (`VolumeKeyAccessibilityService`) with
  `canRequestFilterKeyEvents` is used to see and consume the same key,
  queuing the count in `SharedPreferences`. The app pulls that queue in
  the moment it's next resumed (`CounterProvider.syncPendingNativeCounts`).
- A low-priority foreground notification stays up the whole time
  counting is armed, both to satisfy Android's foreground-service rules
  and so the user always has a visible way to turn it off.

**Caveats to be upfront about:**

- The user has to grant the Accessibility permission once, manually, in
  system settings (`SettingsScreen` prompts for this and can deep-link
  there via `openAccessibilitySettings`). There is no way to grant this
  programmatically, by design of the platform.
- Whether a hardware key event actually reaches an `AccessibilityService`
  while the screen is **fully off** (not just locked-but-on) varies by
  OEM/Android skin and Android version. It's the standard mechanism
  available to a normal app for this, and works widely, but it is not
  a platform guarantee — test on your actual target devices before
  shipping. If a given device doesn't deliver the event with the screen
  fully off, counting while the screen is on/locked still works via the
  same service.
- Some OEM battery optimizers can kill the accessibility process
  aggressively; if counts seem to go missing on a specific phone, check
  that battery optimization is disabled for Zikr.

## Known simplifications

- The app icon (`android/app/src/main/res/drawable/ic_launcher.xml`) is a
  placeholder vector — swap it for real branded artwork (ideally an
  adaptive icon set of mipmap PNGs) before a Play Store listing.
- Hive stores presets/settings/aggregates as plain `Map`s rather than
  generated `TypeAdapter` classes, on purpose — it avoids a `build_runner`
  codegen step in CI and keeps the storage format simple to reason about
  and to migrate later if needed.
