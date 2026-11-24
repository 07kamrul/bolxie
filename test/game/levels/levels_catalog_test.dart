import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/levels/levels_catalog.dart';
import 'package:bloxie/game/logic/shapes_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog holds 50 levels in 5 worlds of 10', () {
    expect(LevelsCatalog.count, 50);
    for (var w = 1; w <= 5; w++) {
      final inWorld = LevelsCatalog.all.where((l) => l.world == w);
      expect(inWorld.length, 10, reason: 'world $w');
    }
  });

  test('ids are 1..50 without gaps or duplicates', () {
    final ids = LevelsCatalog.all.map((l) => l.id).toList();
    expect(ids, List.generate(50, (i) => i + 1));
  });

  test('every level is structurally valid', () {
    for (final level in LevelsCatalog.all) {
      expect(level.goal.target, greaterThan(0), reason: 'level ${level.id}');
      expect(level.title, isNotEmpty, reason: 'level ${level.id}');
      final t = level.starThresholds;
      expect(t[0], lessThanOrEqualTo(t[1]), reason: 'level ${level.id}');
      expect(t[1], lessThanOrEqualTo(t[2]), reason: 'level ${level.id}');
      final moves = level.moveLimit;
      if (moves != null) {
        expect(moves, greaterThan(0), reason: 'level ${level.id}');
      }
      expect(
        level.bigShapeBias,
        inInclusiveRange(0, 1),
        reason: 'level ${level.id}',
      );
    }
  });

  test('prefills are 8x8 grids with legal chars', () {
    for (final level in LevelsCatalog.all) {
      for (final row in level.prefill) {
        expect(row.length, GameConstants.gridSize, reason: 'level ${level.id}');
        expect(row, matches(RegExp(r'^[.XB]+$')), reason: 'level ${level.id}');
      }
    }
  });

  test('buildBoard produces filled and blocker cells from prefill', () {
    final level = LevelsCatalog.byId(31);
    final board = level.buildBoard();
    expect(board.blockerCount, greaterThan(0));
    expect(board.filledCount, greaterThanOrEqualTo(board.blockerCount));
  });

  test('stone goals never exceed the stones on the board', () {
    for (final level in LevelsCatalog.all) {
      if (level.goal.type != LevelGoalType.clearBlockers) continue;
      expect(
        level.goal.target,
        lessThan(level.buildBoard().blockerCount),
        reason: 'level ${level.id} needs more stones than it has',
      );
    }
  });

  test('allowedShapeIds reference real shapes', () {
    for (final level in LevelsCatalog.all) {
      for (final id in level.allowedShapeIds ?? const <String>[]) {
        expect(
          () => ShapesCatalog.byId(id),
          returnsNormally,
          reason: 'level ${level.id}',
        );
      }
    }
  });

  test('move limits never increase within a world', () {
    for (var w = 1; w <= 5; w++) {
      final limits = LevelsCatalog.all
          .where((l) => l.world == w)
          .map((l) => l.moveLimit ?? 1 << 30)
          .toList();
      for (var i = 1; i < limits.length; i++) {
        expect(
          limits[i],
          lessThanOrEqualTo(limits[i - 1]),
          reason: 'world $w level ${i + 1}',
        );
      }
    }
  });

  test('later worlds end on tighter move limits than earlier ones', () {
    int endLimit(int w) {
      final levels = LevelsCatalog.all.where((l) => l.world == w).toList();
      return levels.last.moveLimit ?? 1 << 30;
    }

    for (var w = 2; w <= 5; w++) {
      expect(endLimit(w), lessThan(endLimit(w - 1)), reason: 'world $w');
    }
  });

  test('starsFor maps scores to 1..3 stars', () {
    final level = LevelsCatalog.byId(1);
    expect(starsFor(level, level.starThresholds[0] - 1), 1);
    expect(starsFor(level, level.starThresholds[1]), 2);
    expect(starsFor(level, level.starThresholds[2]), 3);
  });
}
