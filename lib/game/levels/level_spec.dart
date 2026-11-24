import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:flutter/foundation.dart';

/// What the player must achieve to win a level.
enum LevelGoalType { reachScore, clearLines, clearBlockers, clearColor }

@immutable
class LevelGoal {
  const LevelGoal(this.type, this.target, {this.colorIndex});

  const LevelGoal.reachScore(int target)
    : this(LevelGoalType.reachScore, target);
  const LevelGoal.clearLines(int target)
    : this(LevelGoalType.clearLines, target);
  const LevelGoal.clearBlockers(int target)
    : this(LevelGoalType.clearBlockers, target);
  const LevelGoal.clearColor(int target, int colorIndex)
    : this(LevelGoalType.clearColor, target, colorIndex: colorIndex);

  final LevelGoalType type;
  final int target;

  /// Only used by [LevelGoalType.clearColor].
  final int? colorIndex;
}

/// Immutable definition of one level. All 50 levels live in
/// `levels_catalog.dart` as instances of this class.
@immutable
class LevelSpec {
  const LevelSpec({
    required this.id,
    required this.world,
    required this.title,
    required this.goal,
    required this.starThresholds,
    this.moveLimit,
    this.prefill = const [],
    this.allowedShapeIds,
    this.bigShapeBias = 0,
    this.undoAllowed = true,
    this.reviveAllowed = true,
  });

  final int id;
  final int world;
  final String title;
  final LevelGoal goal;

  /// Score cutoffs for 1, 2 and 3 stars.
  final List<int> starThresholds;

  /// Max placements allowed; null means unlimited.
  final int? moveLimit;

  /// 8 rows of 8 chars: '.' empty, 'X' filled, 'B' blocker (stone).
  final List<String> prefill;

  /// Shape ids the spawner may deal; null means the whole catalog.
  final List<String>? allowedShapeIds;

  /// 0.0 (no extra big shapes) to 1.0 (heavy big-shape bias).
  final double bigShapeBias;

  final bool undoAllowed;
  final bool reviveAllowed;

  static const int _size = GameConstants.gridSize;

  /// Builds the starting board from [prefill].
  BoardState buildBoard() {
    final board = BoardState.empty();
    if (prefill.isEmpty) return board;
    assert(prefill.length == _size, 'prefill must cover exactly $_size rows');
    final cells = <int>[];
    final blockers = <int>[];
    for (var r = 0; r < prefill.length && r < _size; r++) {
      final row = prefill[r];
      assert(row.length == _size, 'prefill row must be $_size chars');
      for (var c = 0; c < row.length && c < _size; c++) {
        final ch = row[c];
        if (ch == 'B') {
          blockers.add(BoardState.indexOf(r, c));
        } else if (ch != '.') {
          cells.add(BoardState.indexOf(r, c));
        }
      }
    }
    var next = board.withCells(cells, 1);
    if (blockers.isNotEmpty) {
      next = next.withCells(blockers, BoardState.blockerValue);
    }
    return next;
  }

  /// Human-readable goal line for HUD and start cards.
  String get goalText => switch (goal.type) {
    LevelGoalType.reachScore => 'Score ${goal.target}',
    LevelGoalType.clearLines => 'Clear ${goal.target} lines',
    LevelGoalType.clearBlockers => 'Destroy ${goal.target} stones',
    LevelGoalType.clearColor =>
      'Clear ${goal.target} ${_colorName(goal.colorIndex)} blocks',
  };

  static String _colorName(int? index) => switch (index) {
    0 => 'pink',
    1 => 'blue',
    2 => 'green',
    3 => 'orange',
    4 => 'purple',
    5 => 'teal',
    _ => 'yellow',
  };
}

/// Minimal read-only view of the live game state used for goal tracking.
@immutable
class GameStateSnapshot {
  const GameStateSnapshot({
    required this.score,
    required this.linesCleared,
    required this.blockersRemaining,
    required this.colorCellsCleared,
  });

  final int score;
  final int linesCleared;
  final int blockersRemaining;
  final int colorCellsCleared;

  int progressForGoal(LevelGoal goal) => switch (goal.type) {
    LevelGoalType.reachScore => score,
    LevelGoalType.clearLines => linesCleared,
    LevelGoalType.clearBlockers => blockersRemaining,
    LevelGoalType.clearColor => colorCellsCleared,
  };
}

/// Computes stars from the final score once a level is won.
int starsFor(LevelSpec spec, int score) {
  final t = spec.starThresholds;
  if (score >= t[2]) return 3;
  if (score >= t[1]) return 2;
  return 1;
}

@immutable
class LevelResult {
  const LevelResult({
    required this.levelId,
    required this.won,
    required this.stars,
    required this.score,
    required this.linesCleared,
    required this.movesUsed,
  });

  final int levelId;
  final bool won;

  /// 0 when lost.
  final int stars;
  final int score;
  final int linesCleared;
  final int movesUsed;
}
