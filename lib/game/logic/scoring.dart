import 'package:bloxie/core/constants/game_constants.dart';
import 'package:flutter/foundation.dart';

@immutable
class ScoreResult {
  const ScoreResult({
    required this.points,
    required this.combo,
    required this.streakBonus,
  });

  final int points;

  /// Consecutive clearing moves after this move (0 if the chain broke).
  final int combo;
  final int streakBonus;
}

abstract final class Scoring {
  /// Points: 1 per cell placed; clears add `10 * lines^2`, multiplied by
  /// `1 + 0.5 * (combo - 1)` for consecutive clearing moves, plus a flat
  /// streak bonus every [GameConstants.streakInterval] consecutive clears.
  /// Integer math: multiplier = (combo + 1) / 2.
  static ScoreResult score({
    required int cellsPlaced,
    required int linesCleared,
    required int combo,
  }) {
    if (linesCleared == 0) {
      return ScoreResult(points: cellsPlaced, combo: 0, streakBonus: 0);
    }
    final newCombo = combo + 1;
    final lineBonus = GameConstants.lineBonusBase * linesCleared * linesCleared;
    final multiplied = (lineBonus * (newCombo + 1)) ~/ 2;
    final streak = newCombo % GameConstants.streakInterval == 0
        ? GameConstants.streakBonus
        : 0;
    return ScoreResult(
      points: cellsPlaced + multiplied + streak,
      combo: newCombo,
      streakBonus: streak,
    );
  }

  static bool isBigCombo(int linesCleared) =>
      linesCleared >= GameConstants.bigComboLines;
}
