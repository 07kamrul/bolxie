part of 'settings_cubit.dart';

class SettingsState extends Equatable {
  const SettingsState({
    required this.soundOn,
    required this.hapticsOn,
    this.reduceMotion = false,
  });

  final bool soundOn;
  final bool hapticsOn;
  final bool reduceMotion;

  SettingsState copyWith({
    bool? soundOn,
    bool? hapticsOn,
    bool? reduceMotion,
  }) => SettingsState(
    soundOn: soundOn ?? this.soundOn,
    hapticsOn: hapticsOn ?? this.hapticsOn,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  @override
  List<Object?> get props => [soundOn, hapticsOn, reduceMotion];
}
