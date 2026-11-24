import 'dart:math';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:bloxie/game/logic/shapes_catalog.dart';

/// Deals trays of shapes with a fairness guarantee: if any shape can still be
/// placed on the board, at least one tray entry is placeable.
class Spawner {
  Spawner({Random? random, List<ShapeDef>? catalog, this.bigShapeBias = 0})
    : _random = random ?? Random(),
      _catalog = catalog ?? ShapesCatalog.all;

  /// 0.0–1.0 extra weight factor for big shapes, independent of score.
  /// Level mode sets this from the level spec; classic mode uses 0.
  final double bigShapeBias;

  final Random _random;
  final List<ShapeDef> _catalog;

  /// Score at which large shapes reach their maximum extra weight.
  static const int _difficultyScoreCap = 3000;
  static const int _bigShapeCells = 5;

  List<ShapeDef?> nextTray(BoardState board, {int score = 0}) {
    final weights = _weightsFor(score);
    final total = weights.fold<int>(0, (a, b) => a + b);

    List<ShapeDef> draw() => List.generate(
      GameConstants.trayCapacity,
      (_) => _pickWeighted(weights, total),
    );

    for (var i = 0; i < GameConstants.spawnRetries; i++) {
      final tray = draw();
      if (tray.any((s) => Placement.anyFit(board, s))) return tray;
    }

    // Forced fairness: swap one slot for a shape known to fit.
    final tray = draw();
    final fitting = _catalog.where((s) => Placement.anyFit(board, s)).toList();
    if (fitting.isNotEmpty) {
      tray[_random.nextInt(tray.length)] =
          fitting[_random.nextInt(fitting.length)];
    }
    return tray;
  }

  /// Big shapes get slightly heavier as the score grows, plus any constant
  /// [bigShapeBias] configured for level mode.
  List<int> _weightsFor(int score) {
    final scoreBonus = min(score, _difficultyScoreCap) * 100 ~/ _difficultyScoreCap;
    final bonus = scoreBonus + (bigShapeBias * 100).round();
    return [
      for (final s in _catalog)
        s.cellCount >= _bigShapeCells
            ? s.weight * (100 + bonus) ~/ 100
            : s.weight,
    ];
  }

  ShapeDef _pickWeighted(List<int> weights, int total) {
    var roll = _random.nextInt(total);
    for (var i = 0; i < weights.length; i++) {
      roll -= weights[i];
      if (roll < 0) return _catalog[i];
    }
    return _catalog.last;
  }
}
