part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({required this.soundOn, required this.hapticsOn});

  final bool soundOn;
  final bool hapticsOn;

  SettingsState copyWith({bool? soundOn, bool? hapticsOn}) => SettingsState(
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
  );

  @override
  List<Object?> get props => [soundOn, hapticsOn];
}
