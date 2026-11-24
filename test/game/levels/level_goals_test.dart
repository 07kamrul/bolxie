import 'dart:math';

import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/game/logic/line_clear.dart';
import 'package:bloxie/game/logic/revive.dart';
import 'package:bloxie/game/logic/shapes_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

/// Row 0 is full except column 7; the stone sits at (0, 0).
const _stoneRow = [
  'BXXXXXX.',
  '........',
  '........',
  '........',
  '........',
  '........',
  '........',
  '........',
];

GameSession _sessionAt(LevelSpec spec, BoardState board) {
  final s = GameSession.level(spec, random: Random(1))..start();
  s.restoreForTest(
    s.state.copyWith(
      board: board,
      tray: List.unmodifiable([ShapesCatalog.byId('single'), null, null]),
    ),
  );
  return s;
}

void main() {
  test('stones count as filled and are removed when their line clears', () {
    final board = const LevelSpec(
      id: 1,
      world: 1,
      title: 't',
      goal: LevelGoal.clearBlockers(1),
      starThresholds: [1, 2, 3],
      prefill: [
        'BXXXXXXX',
        '........', '........', '........',
        '........', '........', '........', '........',
      ],
    ).buildBoard();
    final lines = LineClear.find(board);
    expect(lines.rows, [0]);
    expect(LineClear.apply(board, lines).blockerCount, 0);
  });

  test('clearBlockers goal is won by clearing the stone line', () {
    const spec = LevelSpec(
      id: 900,
      world: 4,
      title: 't',
      goal: LevelGoal.clearBlockers(1),
      starThresholds: [1, 2, 3],
      moveLimit: 5,
      prefill: _stoneRow,
    );
    final s = _sessionAt(spec, spec.buildBoard());
    expect(s.goalProgress, 0);
    final outcome = s.place(0, 0, 7);
    expect(s.goalProgress, 1);
    expect(outcome!.levelResult?.won, isTrue);
  });

  test('clearColor goal counts only cells of the goal color', () {
    // Row 0: seven blocks of color 3, then the single (color 0) fills it.
    final board = BoardState.empty().withCells(
      [for (var c = 0; c < 7; c++) BoardState.indexOf(0, c)],
      4, // colorIndex 3 + 1
    );
    const spec = LevelSpec(
      id: 901,
      world: 5,
      title: 't',
      goal: LevelGoal.clearColor(7, 3),
      starThresholds: [1, 2, 3],
      moveLimit: 5,
    );
    final s = _sessionAt(spec, board);
    final outcome = s.place(0, 0, 7);
    expect(s.state.colorCellsCleared, 7);
    expect(outcome!.levelResult?.won, isTrue);
  });

  test('revive clears the area but leaves stones in place', () {
    final board = BoardState.fromRows([
      'XXX.....',
      'XBX.....',
      'XXX.....',
      '........', '........', '........', '........', '........',
    ]).withCells([BoardState.indexOf(1, 1)], BoardState.blockerValue);
    final after = Revive.apply(board, 0, 0);
    expect(after.blockerCount, 1);
    expect(after.filledCount, 1);
  });
}
