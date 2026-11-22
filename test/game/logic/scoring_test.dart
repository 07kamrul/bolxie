import 'package:bloxie/game/logic/scoring.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'placing without clearing scores one point per cell and resets combo',
    () {
      final r = Scoring.score(cellsPlaced: 4, linesCleared: 0, combo: 3);
      expect(r.points, 4);
      expect(r.combo, 0);
      expect(r.streakBonus, 0);
    },
  );

  test('a single line clear adds 10 and starts the combo', () {
    final r = Scoring.score(cellsPlaced: 3, linesCleared: 1, combo: 0);
    expect(r.combo, 1);
    expect(r.points, 3 + 10);
  });

  test('multi-line clears grow quadratically', () {
    final two = Scoring.score(cellsPlaced: 0, linesCleared: 2, combo: 0);
    final three = Scoring.score(cellsPlaced: 0, linesCleared: 3, combo: 0);
    expect(two.points, 40);
    expect(three.points, 90);
  });

  test('consecutive clears apply a 1.5x multiplier on the second clear', () {
    final r = Scoring.score(cellsPlaced: 0, linesCleared: 1, combo: 1);
    expect(r.combo, 2);
    expect(r.points, 15);
  });

  test('fifth consecutive clear awards the streak bonus', () {
    final r = Scoring.score(cellsPlaced: 0, linesCleared: 1, combo: 4);
    expect(r.combo, 5);
    expect(r.streakBonus, 50);
    // base 10 * (5+1)/2 = 30, + 50
    expect(r.points, 80);
  });

  test('non-streak combos award no streak bonus', () {
    final r = Scoring.score(cellsPlaced: 0, linesCleared: 1, combo: 2);
    expect(r.streakBonus, 0);
  });

  test('isBigCombo reflects line count', () {
    expect(Scoring.isBigCombo(2), isFalse);
    expect(Scoring.isBigCombo(3), isTrue);
  });
}
