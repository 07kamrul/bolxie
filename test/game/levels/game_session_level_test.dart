import 'dart:math';

import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/levels/levels_catalog.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/spawner.dart';
import 'package:flutter_test/flutter_test.dart';

GameSession levelSession(LevelSpec spec, {int seed = 1}) =>
    GameSession.level(spec, random: Random(seed))..start();

/// Places the first fitting tray shape anywhere legal; returns the outcome's
/// level result (or null if no shape fits or the level already ended).
LevelResult? placeAny(GameSession s) {
  final shape = s.state.tray.firstWhere(
    (sh) => sh != null && Placement.anyFit(s.state.board, sh),
    orElse: () => null,
  );
  if (shape == null) return null;
  final slot = s.state.tray.indexOf(shape);
  for (var r = 0; r < 8; r++) {
    for (var c = 0; c < 8; c++) {
      if (Placement.canPlace(s.state.board, shape, r, c)) {
        return s.place(slot, r, c)?.levelResult;
      }
    }
  }
  return null;
}

void main() {
  test('level start applies prefill and move limit', () {
    final spec = LevelsCatalog.byId(11);
    final s = levelSession(spec);
    expect(s.state.board.filledCount, greaterThan(0));
    expect(s.state.movesLeft, spec.moveLimit);
  });

  test('spawner only deals allowed shapes', () {
    final spec = LevelsCatalog.byId(1);
    final s = levelSession(spec, seed: 3);
    for (var i = 0; i < 10; i++) {
      for (final shape in s.state.tray) {
        if (shape != null) {
          expect(spec.allowedShapeIds, contains(shape.id));
        }
      }
      if (placeAny(s) != null) break;
    }
  });

  test('score goal wins the level', () {
    const spec = LevelSpec(
      id: 999,
      world: 1,
      title: 't',
      goal: LevelGoal.reachScore(3),
      starThresholds: [3, 6, 9],
    );
    final s = levelSession(spec, seed: 3);
    LevelResult? result;
    for (var i = 0; i < 20 && result == null && s.state.score < 3; i++) {
      result = placeAny(s);
    }
    expect(result, isNotNull);
    expect(result!.won, isTrue);
    expect(result.stars, inInclusiveRange(1, 3));
  });

  test('moves run out -> level lost', () {
    const spec = LevelSpec(
      id: 998,
      world: 1,
      title: 't',
      goal: LevelGoal.reachScore(100000),
      starThresholds: [100000, 100000, 100000],
      moveLimit: 2,
    );
    final s = levelSession(spec, seed: 3);
    LevelResult? result;
    for (var i = 0; i < 2 && result == null; i++) {
      result = placeAny(s);
    }
    expect(result, isNotNull);
    expect(result!.won, isFalse);
    expect(result.stars, 0);
  });

  test('clearBlockers levels start with stones on the board', () {
    final spec = LevelsCatalog.byId(31);
    final s = levelSession(spec);
    expect(s.state.board.blockerCount, greaterThan(0));
    expect(s.level, isNotNull);
  });

  test('classic sessions never emit level results and have no move limit', () {
    final s = GameSession(spawner: Spawner(random: Random(1)))..start();
    final shape = s.state.tray.first!;
    outer:
    for (var r = 0; r < 8; r++) {
      for (var c = 0; c < 8; c++) {
        if (Placement.canPlace(s.state.board, shape, r, c)) {
          expect(s.place(0, r, c)!.levelResult, isNull);
          break outer;
        }
      }
    }
    expect(s.state.movesLeft, isNull);
    expect(s.level, isNull);
  });
}
