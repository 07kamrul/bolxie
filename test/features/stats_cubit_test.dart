import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  test('records games, lines and a new best score', () async {
    final prefs = await makePrefs({'best_score': 100});
    final s = StatsCubit(prefs);
    final isBest = await s.recordGame(score: 250, lines: 7);
    expect(isBest, isTrue);
    expect(s.state.gamesPlayed, 1);
    expect(s.state.bestScore, 250);
    expect(s.state.totalLines, 7);
    expect(prefs.bestScore, 250);
  });

  test('a lower score keeps the best and still counts the game', () async {
    final prefs = await makePrefs({'best_score': 500, 'total_lines': 3});
    final s = StatsCubit(prefs);
    final isBest = await s.recordGame(score: 50, lines: 2);
    expect(isBest, isFalse);
    expect(s.state.bestScore, 500);
    expect(s.state.totalLines, 5);
    expect(s.state.gamesPlayed, 1);
  });
}
