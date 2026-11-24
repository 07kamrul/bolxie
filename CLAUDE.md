# CLAUDE.md — Bloxie

@AGENTS.md
Read AGENTS.md first — it defines the project, stack, commands, layout,
architecture conventions, testing rules and agent workflow for this repo.

## Claude-specific notes

- Run `flutter analyze` and `flutter test` after any Dart change before
  declaring work done; report real results, not assumptions.
- Respect the Flame boundary: keep game rules pure Dart in `lib/game/logic`
  (immutable `GameState`, no Flame imports). Rendering belongs in
  `lib/game/components`.
- Wire new services through `core/services/service_locator.dart` (`sl`) with a
  Noop variant for non-mobile and a fake in `test/helpers/` for tests.
- All constants go to `lib/core/constants/`; all persistence through
  `PrefsRepository`.
- Windows/Android gotchas (JDK 17, `lintVital`, Kotlin incremental cache) are
  documented in AGENTS.md — existing workarounds are deliberate, don't "fix"
  them.
