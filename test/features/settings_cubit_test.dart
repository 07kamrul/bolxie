import 'package:bloc_test/bloc_test.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  late PrefsRepository prefs;
  setUp(() async => prefs = await makePrefs());

  test('loads persisted values', () async {
    final stored = await makePrefs({'sound_on': false});
    final cubit = SettingsCubit(stored);
    expect(cubit.state.soundOn, isFalse);
    expect(cubit.state.hapticsOn, isTrue);
  });

  blocTest<SettingsCubit, SettingsState>(
    'toggleSound flips and persists',
    build: () => SettingsCubit(prefs),
    act: (c) => c.toggleSound(),
    expect: () => [const SettingsState(soundOn: false, hapticsOn: true)],
    verify: (_) => expect(prefs.soundOn, isFalse),
  );

  blocTest<SettingsCubit, SettingsState>(
    'toggleHaptics flips and persists',
    build: () => SettingsCubit(prefs),
    act: (c) => c.toggleHaptics(),
    expect: () => [const SettingsState(soundOn: true, hapticsOn: false)],
    verify: (_) => expect(prefs.hapticsOn, isFalse),
  );

  blocTest<SettingsCubit, SettingsState>(
    'toggleReduceMotion flips and persists',
    build: () => SettingsCubit(prefs),
    act: (c) => c.toggleReduceMotion(),
    expect: () => [
      const SettingsState(soundOn: true, hapticsOn: true, reduceMotion: true),
    ],
    verify: (_) => expect(prefs.reduceMotion, isTrue),
  );
}
