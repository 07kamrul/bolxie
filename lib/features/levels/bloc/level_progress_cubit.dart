import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LevelProgressState extends Equatable {
  const LevelProgressState({
    required this.highestUnlocked,
    required this.stars,
  });

  final int highestUnlocked;
  final Map<int, int> stars;

  bool isUnlocked(int levelId) => levelId <= highestUnlocked;

  int starsFor(int levelId) => stars[levelId] ?? 0;

  @override
  List<Object?> get props => [highestUnlocked, stars];
}

/// Persists level unlocks and best star counts.
class LevelProgressCubit extends Cubit<LevelProgressState> {
  LevelProgressCubit(this._prefs)
    : super(
        LevelProgressState(
          highestUnlocked: _prefs.highestUnlockedLevel,
          stars: _prefs.levelStars,
        ),
      );

  final PrefsRepository _prefs;

  /// Records a won level: unlocks the next one, keeps the best star count
  /// and returns true when this run set a new best for the level.
  Future<bool> completeLevel(LevelResult result) async {
    if (!result.won) return false;
    final previousBest = state.starsFor(result.levelId);
    final improved = result.stars > previousBest;
    final nextStars = Map<int, int>.of(state.stars);
    if (improved) nextStars[result.levelId] = result.stars;
    final nextUnlocked = result.levelId + 1 > state.highestUnlocked
        ? result.levelId + 1
        : state.highestUnlocked;
    emit(
      LevelProgressState(highestUnlocked: nextUnlocked, stars: nextStars),
    );
    await _prefs.setHighestUnlockedLevel(nextUnlocked);
    if (improved) await _prefs.setLevelStars(nextStars);
    return improved;
  }
}
