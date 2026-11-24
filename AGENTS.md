# AGENTS.md — Bloxie

Guidance for AI coding agents working on this repository.

## Project

Bloxie is an 8×8 block-puzzle game for Android and iOS built with Flutter and
Flame. No backend: scores, coins, themes and settings live on-device in
`shared_preferences`. Package name is `bloxie` (see `pubspec.yaml`).

**Stack:** Flutter (Dart ^3.14), Flame + flame_audio (game), flutter_bloc +
equatable (state), get_it (DI), shared_preferences, google_mobile_ads,
in_app_purchase. Lints: `very_good_analysis`. Tests: `flutter_test` with
`bloc_test` and `mocktail`.

## Commands

```bash
flutter pub get          # install dependencies
flutter analyze          # lint (must be clean before finishing)
flutter test             # unit tests (must pass before finishing)
flutter test --coverage
flutter run              # on a connected device/emulator
flutter build appbundle --release   # release AAB (needs android/key.properties)
```

Branding/assets:
```bash
python tool/generate_branding.py       # app icon + splash logo (Pillow)
dart run flutter_launcher_icons        # apply icons per flutter_launcher_icons.yaml
dart run flutter_native_splash:create  # apply splash per flutter_native_splash.yaml
python tool/gen_sfx.py                 # regenerate placeholder sounds
```

## Layout

```
lib/
  main.dart, bootstrap.dart, app.dart   entry point → bootstrap() → BloxieApp
  core/
    constants/    ad_config, iap_config, economy_constants, game_constants
    services/     service_locator.dart (GetIt `sl`, setupServices())
    theme/        app_theme, skins (5 themes)
  game/
    logic/        pure-Dart rules, immutable state, no Flame dependency
    components/   Flame rendering components
    block_game.dart, game_layout.dart, levels/
  features/       home, game_screen, shop, daily_reward, settings, stats,
                  wallet, levels, common — each feature has bloc/ + screens
  services/       ads, iap, analytics, audio, storage (prefs_repository)
test/             mirrors lib/ : features, game, services, widgets, helpers/
tool/             Python asset generators
android/ ios/     platform shells     store/    Play Store assets
```

## Architecture conventions

- **Game logic vs rendering:** rules live in `lib/game/logic` as pure Dart with
  immutable state (`GameSession` swaps in a new `GameState` per move — this is
  what makes undo trivial). Never import Flame there.
- **State:** Cubits (flutter_bloc). App-level cubits are created in
  `service_locator.dart` and exposed via `MultiBlocProvider` in `app.dart`.
  Use `equatable` for state classes.
- **DI:** register everything in `core/services/service_locator.dart`, access
  via `sl<T>()`. Platform services get a Noop implementation for non-mobile
  (`_isMobile` guard) and for tests (`test/helpers/fakes.dart`, `fake_iap.dart`,
  `prefs.dart`).
- **Constants:** magic numbers (ads, IAP, economy, game rules) go in
  `lib/core/constants/`, not inline.
- **Persistence:** all storage goes through `PrefsRepository`. No other file
  touches `SharedPreferences` directly.
- **Ads:** test unit IDs only in `ad_config.dart` debug paths; never hardcode
  real AdMob IDs outside that file. No secrets in source — signing keys live in
  gitignored `android/key.properties`.

## Testing

- Tests mirror `lib/` structure under `test/`. Use `bloc_test` for cubits,
  `mocktail` for mocks, shared fakes from `test/helpers/`.
- Write/update tests for behavior changes; run `flutter test` and
  `flutter analyze` before considering work done.
- AAA pattern, descriptive test names.

## Platform notes (Windows)

- Android builds use JDK 17 with `lintVital` disabled (Kotlin/Windows cache
  quirks; see git history). If the Kotlin incremental cache fails to close,
  the existing workaround handles it — don't remove it.
- `android/.kotlin/` is untracked noise; don't commit it.

## Agent workflow

1. Read the relevant feature folder before changing it; mirror existing
   patterns rather than inventing new ones.
2. Keep diffs minimal and focused; many small files over few large ones.
3. Verify with `flutter analyze` + `flutter test`. Report failures honestly.
4. Don't commit: `build/`, `.dart_tool/`, `android/.kotlin/`, keystores,
   `key.properties`, or any secrets.
