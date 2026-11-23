# Bloxie

An 8×8 block-puzzle game for Android and iOS built with Flutter and Flame.
Drag pieces onto the grid, clear rows and columns, and chain clears for combos.

## Features

- 23 fixed-orientation shapes (single, 1×2 to 1×5, 2×2, 3×3, L, T, Z, S).
- Fair spawner: whenever any shape can still fit, the tray always contains one.
- Scoring: 1 point per cell, `10 × lines²` per clear, combo multiplier
  `(combo + 1) / 2`, and +50 every 5th consecutive clear.
- Ghost preview with snapping, a finger offset so the piece stays visible,
  placement bounce, line-clear flash and particles, combo popups, screen shake.
- Rewarded ads for **Revive** (clears the best 3×3 area) and **Undo**.
  Interstitials every 3–4 game overs, 120 s cooldown, only between games.
- **Remove Ads** one-time purchase with Restore. Rewarded ads stay available.
- 7-day daily reward streak, 5 themes (1 free and 4 bought with coins),
  and a stats screen.
- No backend: all data (scores, coins, themes, settings) is stored on the
  device with `shared_preferences`. No analytics or crash-reporting service.

## Project layout

```
lib/
  core/        constants (game, ads, IAP, economy), theme and skins, service locator
  game/        logic/ (pure Dart rules) · components/ (Flame rendering) · block_game.dart
  features/    home, game_screen, shop, daily_reward, settings, stats, wallet (BLoC)
  services/    ads, iap, analytics, storage, audio
test/          logic, cubit and ad-policy unit tests
tool/          gen_sfx.py (regenerates the placeholder sounds)
```

The game rules in `lib/game/logic` don't depend on Flame and use immutable
state. `GameSession` swaps in a new `GameState` on every move, which is what
makes undo simple.

## Run

```bash
flutter pub get
flutter run            # on a connected device or emulator
flutter test           # unit tests
flutter test --coverage
flutter analyze
```

### Sounds

`assets/audio/{place,clear,combo,game_over}.wav` are generated placeholders.
Replace them with your own files under the same names, or regenerate them with
`python3 tool/gen_sfx.py`.

## Release build (AAB)

1. Create an upload key (once):
   ```bash
   keytool -genkey -v -keystore ~/bloxie-upload.jks -keyalg RSA -keysize 2048 \
     -validity 10000 -alias upload
   ```
2. Create `android/key.properties` (already gitignored):
   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/bloxie-upload.jks
   ```
3. Bump `version:` in `pubspec.yaml`, then build:
   ```bash
   flutter build appbundle --release
   # -> build/app/outputs/bundle/release/app-release.aab
   ```

## Play Store launch checklist

**Identity**
- [ ] Change the application id `com.example.bloxie` (`android/app/build.gradle.kts`
      `namespace` and `applicationId`, plus the Kotlin package path) and the iOS bundle id.
- [ ] Replace the launcher icons (`flutter_launcher_icons` is the easiest route).

**Ads (AdMob)**
- [ ] Create the app in AdMob, plus one rewarded and one interstitial unit.
- [ ] Put the real unit IDs in `lib/core/constants/ad_config.dart`.
- [ ] Put the real App ID in `AndroidManifest.xml` and `ios/Runner/Info.plist`.
- [ ] Set up a GDPR consent message in AdMob → Privacy & messaging (the UMP flow is already in the code).
- [ ] Add `app-ads.txt` to your developer website.

**In-app purchase**
- [ ] Create the managed product `remove_ads` (non-consumable) in Play Console → Monetize.
- [ ] Add license testers, then test buy and restore on the internal testing track.

**Store listing and policy**
- [ ] Data safety form: device/advertising ID, shared with Google (AdMob). The app itself collects nothing.
- [ ] Declare "Contains ads", complete the content rating questionnaire, and choose the target audience (not "children" if using personalized ads).
- [ ] Publish a privacy policy URL.
- [ ] Prepare screenshots (phone and 7"/10" tablet), the feature graphic (1024×500) and short and long descriptions.

**Quality**
- [ ] `flutter analyze` is clean and `flutter test` passes.
- [ ] Profile on a low-end device with `flutter run --profile` and confirm a steady 60 fps.
- [ ] Release through internal → closed → production tracks.

## Defaults chosen

- App name "Bloxie" and storage via `shared_preferences`.
- Revive is limited to once per game. Undo goes back one move and costs one rewarded ad.
- Coins: score ÷ 100 per game, 25 per rewarded ad, and a daily streak of 20 → 200.
