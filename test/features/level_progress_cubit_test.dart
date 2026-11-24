import 'package:bloxie/features/levels/bloc/level_progress_cubit.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

Future<LevelProgressCubit> makeCubit() async =>
    LevelProgressCubit(await makePrefs());

LevelResult win(int id, int stars) => LevelResult(
  levelId: id,
  won: true,
  stars: stars,
  score: 100,
  linesCleared: 2,
  movesUsed: 10,
);

LevelResult loss(int id) => LevelResult(
  levelId: id,
  won: false,
  stars: 0,
  score: 50,
  linesCleared: 1,
  movesUsed: 10,
);

void main() {
  test('level 1 unlocked by default', () async {
    final cubit = await makeCubit();
    expect(cubit.state.isUnlocked(1), isTrue);
    expect(cubit.state.isUnlocked(2), isFalse);
  });

  test('winning a level unlocks the next one', () async {
    final cubit = await makeCubit();
    await cubit.completeLevel(win(1, 2));
    expect(cubit.state.isUnlocked(2), isTrue);
    expect(cubit.state.starsFor(1), 2);
  });

  test('losing records nothing', () async {
    final cubit = await makeCubit();
    final improved = await cubit.completeLevel(loss(1));
    expect(improved, isFalse);
    expect(cubit.state.isUnlocked(2), isFalse);
  });

  test('best stars are kept across re-wins', () async {
    final prefs = await makePrefs();
    final cubit = LevelProgressCubit(prefs);
    await cubit.completeLevel(win(1, 3));
    final improved = await cubit.completeLevel(win(1, 1));
    expect(improved, isFalse);
    expect(cubit.state.starsFor(1), 3);
    // Fresh cubit over the same prefs keeps the stored state.
    final reloaded = LevelProgressCubit(prefs);
    expect(reloaded.state.starsFor(1), 3);
    expect(reloaded.state.isUnlocked(2), isTrue);
  });

  test('unlocks never regress', () async {
    final prefs = await makePrefs();
    final cubit = LevelProgressCubit(prefs);
    await cubit.completeLevel(win(3, 1));
    await cubit.completeLevel(win(1, 1));
    expect(cubit.state.highestUnlocked, 4);
  });
}
