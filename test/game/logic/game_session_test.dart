import 'dart:math';

import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:bloxie/game/logic/spawner.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes.dart';

GameSession sessionWith({
  BoardState? board,
  List<ShapeDef?>? tray,
  int seed = 1,
}) {
  final s = GameSession(spawner: Spawner(random: Random(seed)));
  s.restoreForTest(
    GameState(
      board: board ?? BoardState.empty(),
      tray: List.unmodifiable(tray ?? [single, h2, v3]),
      score: 0,
      combo: 0,
      linesCleared: 0,
      moves: 0,
      isGameOver: false,
      reviveUsed: false,
    ),
  );
  return s;
}

void main() {
  test('start deals three shapes on an empty board', () {
    final s = GameSession(spawner: Spawner(random: Random(2)))..start();
    expect(s.state.tray.where((e) => e != null).length, 3);
    expect(s.state.board.isEmpty, isTrue);
    expect(s.state.score, 0);
  });

  test('placing scores one point per cell and consumes the slot', () {
    final s = sessionWith();
    final outcome = s.place(1, 0, 0);
    expect(outcome, isNotNull);
    expect(s.state.score, 2);
    expect(s.state.tray[1], isNull);
    expect(s.state.board.filledCount, 2);
  });

  test('invalid placement returns null and changes nothing', () {
    final s = sessionWith();
    expect(s.place(2, 6, 0), isNull);
    expect(s.state.board.isEmpty, isTrue);
  });

  test('completing a row clears it and awards the bonus', () {
    final board = BoardState.fromRows(['XXXXXX..']);
    final s = sessionWith(board: board, tray: [h2, null, null]);
    final outcome = s.place(0, 0, 6)!;
    expect(outcome.cleared.rows, [0]);
    expect(s.state.linesCleared, 1);
    expect(s.state.combo, 1);
    expect(s.state.score, 2 + 10);
    expect(s.state.board.isEmpty, isTrue);
  });

  test('tray refills once all three are placed', () {
    final s = sessionWith(tray: [single, null, null]);
    s.place(0, 0, 0);
    expect(s.state.tray.where((e) => e != null).length, 3);
  });

  test('game over is flagged when no remaining shape fits', () {
    final board = BoardState.fromRows([
      'X.X.X.X.',
      '.X.X.X.X',
      'X.X.X.X.',
      '.X.X.X.X',
      'X.X.X.X.',
      '.X.X.X.X',
      'X.X.X.X.',
      '.X.X.X.X',
    ]);
    final s = sessionWith(board: board, tray: [single, sq2, null]);
    s.place(0, 0, 1);
    // Checkerboard has no 2x2 hole, so sq2 can never fit.
    expect(s.state.isGameOver, isTrue);
  });

  test('undo restores the previous state once', () {
    final s = sessionWith();
    s.place(0, 0, 0);
    expect(s.canUndo, isTrue);
    expect(s.undo(), isTrue);
    expect(s.state.board.isEmpty, isTrue);
    expect(s.state.score, 0);
    expect(s.state.tray[0], isNotNull);
    expect(s.canUndo, isFalse);
    expect(s.undo(), isFalse);
  });

  test('revive clears a 3x3 area, resets game over, and is single use', () {
    final board = BoardState.fromRows(List.filled(8, 'XXXXXXXX'));
    final s = sessionWith(board: board, tray: [sq2, null, null]);
    s.forceGameOverForTest();
    expect(s.state.isGameOver, isTrue);
    final cleared = s.revive();
    expect(cleared, isNotNull);
    expect(s.state.isGameOver, isFalse);
    expect(s.state.reviveUsed, isTrue);
    expect(s.state.board.filledCount, 64 - 9);
    expect(s.revive(), isNull);
  });
}
