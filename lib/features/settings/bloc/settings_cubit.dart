import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._prefs)
    : super(
        SettingsState(
          soundOn: _prefs.soundOn,
          hapticsOn: _prefs.hapticsOn,
          reduceMotion: _prefs.reduceMotion,
        ),
      );

  final PrefsRepository _prefs;

  Future<void> toggleSound() async {
    final next = !state.soundOn;
    emit(state.copyWith(soundOn: next));
    await _prefs.setSoundOn(next);
  }

  Future<void> toggleHaptics() async {
    final next = !state.hapticsOn;
    emit(state.copyWith(hapticsOn: next));
    await _prefs.setHapticsOn(next);
  }

  Future<void> toggleReduceMotion() async {
    final next = !state.reduceMotion;
    emit(state.copyWith(reduceMotion: next));
    await _prefs.setReduceMotion(next);
  }
}
