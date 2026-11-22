import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StatsState extends Equatable {
  const StatsState({
    required this.gamesPlayed,
    required this.bestScore,
    required this.totalLines,
  });

  final int gamesPlayed;
  final int bestScore;
  final int totalLines;

  @override
  List<Object?> get props => [gamesPlayed, bestScore, totalLines];
}

class StatsCubit extends Cubit<StatsState> {
  StatsCubit(this._prefs)
    : super(
        StatsState(
          gamesPlayed: _prefs.gamesPlayed,
          bestScore: _prefs.bestScore,
          totalLines: _prefs.totalLines,
        ),
      );

  final PrefsRepository _prefs;

  /// Records a finished game. Returns true if [score] is a new best.
  Future<bool> recordGame({required int score, required int lines}) async {
    final isBest = score > state.bestScore;
    final next = StatsState(
      gamesPlayed: state.gamesPlayed + 1,
      bestScore: isBest ? score : state.bestScore,
      totalLines: state.totalLines + lines,
    );
    emit(next);
    await _prefs.setGamesPlayed(next.gamesPlayed);
    await _prefs.setTotalLines(next.totalLines);
    if (isBest) await _prefs.setBestScore(score);
    return isBest;
  }
}
