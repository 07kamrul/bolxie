import 'dart:math';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/line_clear.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/revive.dart';
import 'package:bloxie/game/logic/scoring.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:bloxie/game/logic/shapes_catalog.dart';
import 'package:bloxie/game/logic/spawner.dart';
import 'package:flutter/foundation.dart';

@immutable
class GameState {
  const GameState({
    required this.board,
    required this.tray,
    required this.score,
    required this.combo,
    required this.linesCleared,
    required this.moves,
    required this.isGameOver,
    required this.reviveUsed,
    this.movesLeft,
    this.colorCellsCleared = 0,
  });

  final BoardState board;
  final List<ShapeDef?> tray;
  final int score;
  final int combo;
  final int linesCleared;
  final int moves;
  final bool isGameOver;
  final bool reviveUsed;

  /// Placements remaining in level mode; null in classic mode.
  final int? movesLeft;

  /// Cells of the level goal's color cleared so far (level mode only).
  final int colorCellsCleared;

  GameState copyWith({
    BoardState? board,
    List<ShapeDef?>? tray,
    int? score,
    int? combo,
    int? linesCleared,
    int? moves,
    bool? isGameOver,
    bool? reviveUsed,
    Object? movesLeft = _unset,
    int? colorCellsCleared,
  }) => GameState(
    board: board ?? this.board,
    tray: tray ?? this.tray,
    score: score ?? this.score,
    combo: combo ?? this.combo,
    linesCleared: linesCleared ?? this.linesCleared,
    moves: moves ?? this.moves,
    isGameOver: isGameOver ?? this.isGameOver,
    reviveUsed: reviveUsed ?? this.reviveUsed,
    movesLeft: movesLeft == _unset ? this.movesLeft : movesLeft as int?,
    colorCellsCleared: colorCellsCleared ?? this.colorCellsCleared,
  );

  static const _unset = Object();
}

/// Everything the view layer needs to animate a successful move.
@immutable
class PlaceOutcome {
  const PlaceOutcome({
    required this.slot,
    required this.shape,
    required this.row,
    required this.col,
    required this.cleared,
    required this.clearedColors,
    required this.score,
    required this.trayRefilled,
    this.levelResult,
  });

  final int slot;
  final ShapeDef shape;
  final int row;
  final int col;
  final LineClearResult cleared;

  /// Cell values (color index + 1) at each `cleared.cellIndices` entry,
  /// captured before clearing so effects can tint particles.
  final List<int> clearedColors;
  final ScoreResult score;
  final bool trayRefilled;

  /// Set exactly once per level run, on the move that wins or loses it.
  final LevelResult? levelResult;
}

/// Owns the authoritative game state. State objects are immutable; each move
/// swaps in a new [GameState].
class GameSession {
  GameSession({required Spawner spawner})
    : _spawner = spawner,
      _level = null,
      _initialBlockers = 0;

  /// Level mode: goals, move limits and prefills come from [spec].
  GameSession.level(LevelSpec spec, {Random? random})
    : _spawner = Spawner(
        random: random,
        catalog: _catalogFor(spec),
        bigShapeBias: spec.bigShapeBias,
      ),
      _level = spec,
      _initialBlockers = spec.buildBoard().blockerCount;

  static List<ShapeDef>? _catalogFor(LevelSpec spec) {
    final ids = spec.allowedShapeIds;
    if (ids == null) return null;
    return [for (final id in ids) ShapesCatalog.byId(id)];
  }

  final Spawner _spawner;
  final LevelSpec? _level;
  final int _initialBlockers;
  GameState _state = GameState(
    board: BoardState.empty(),
    tray: const [null, null, null],
    score: 0,
    combo: 0,
    linesCleared: 0,
    moves: 0,
    isGameOver: false,
    reviveUsed: false,
  );
  GameState? _undoSnapshot;

  LevelSpec? get level => _level;

  GameState get state => _state;
  bool get canUndo => _undoSnapshot != null && !_state.isGameOver;

  void start() {
    final board = _level?.buildBoard() ?? BoardState.empty();
    _undoSnapshot = null;
    _state = GameState(
      board: board,
      tray: List.unmodifiable(_spawner.nextTray(board)),
      score: 0,
      combo: 0,
      linesCleared: 0,
      moves: 0,
      isGameOver: false,
      reviveUsed: false,
      movesLeft: _level?.moveLimit,
    );
  }

  /// Places tray [slot] with its top-left at ([row], [col]).
  /// Returns null if the move is invalid.
  PlaceOutcome? place(int slot, int row, int col) {
    if (_state.isGameOver || slot < 0 || slot >= _state.tray.length) {
      return null;
    }
    final shape = _state.tray[slot];
    if (shape == null || !Placement.canPlace(_state.board, shape, row, col)) {
      return null;
    }

    final placed = Placement.place(
      _state.board,
      shape,
      row,
      col,
      shape.colorIndex + 1,
    );
    final lines = LineClear.find(placed);
    final clearedIdx = lines.cellIndices;
    final colors = [
      for (final i in clearedIdx)
        placed.at(i ~/ GameConstants.gridSize, i % GameConstants.gridSize),
    ];
    final board = LineClear.apply(placed, lines);
    final result = Scoring.score(
      cellsPlaced: shape.cellCount,
      linesCleared: lines.lineCount,
      combo: _state.combo,
    );

    var tray = List<ShapeDef?>.of(_state.tray)..[slot] = null;
    final score = _state.score + result.points;
    final refilled = tray.every((s) => s == null);
    if (refilled) tray = _spawner.nextTray(board, score: score);

    final goalColor = _level?.goal.colorIndex;
    final colorCleared =
        _state.colorCellsCleared +
        (goalColor == null
            ? 0
            : [
                    for (final i in clearedIdx)
                      placed.at(
                        i ~/ GameConstants.gridSize,
                        i % GameConstants.gridSize,
                      ),
                  ]
                  .where(
                    (v) =>
                        v != BoardState.blockerValue &&
                        BoardState.colorIndexOf(v) == goalColor,
                  )
                  .length);

    final movesLeft = _state.movesLeft == null ? null : _state.movesLeft! - 1;
    final newLines = _state.linesCleared + lines.lineCount;

    _undoSnapshot = _state;
    _state = _state.copyWith(
      board: board,
      tray: List.unmodifiable(tray),
      score: score,
      combo: result.combo,
      linesCleared: newLines,
      moves: _state.moves + 1,
      isGameOver: Placement.isGameOver(board, tray),
      movesLeft: movesLeft,
      colorCellsCleared: colorCleared,
    );

    final levelResult = _evaluateLevel(board, tray);
    return PlaceOutcome(
      slot: slot,
      shape: shape,
      row: row,
      col: col,
      cleared: lines,
      clearedColors: colors,
      score: result,
      trayRefilled: refilled,
      levelResult: levelResult,
    );
  }

  /// Progress toward the level goal, clamped to the target (0 in classic).
  int get goalProgress {
    final level = _level;
    if (level == null) return 0;
    final s = _state;
    final progress = switch (level.goal.type) {
      LevelGoalType.reachScore => s.score,
      LevelGoalType.clearLines => s.linesCleared,
      LevelGoalType.clearBlockers => _initialBlockers - s.board.blockerCount,
      LevelGoalType.clearColor => s.colorCellsCleared,
    };
    return progress.clamp(0, level.goal.target);
  }

  /// Non-null only on the move that ends the level (win or loss).
  LevelResult? _evaluateLevel(BoardState board, List<ShapeDef?> tray) {
    final level = _level;
    if (level == null) return null;
    final won = goalProgress >= level.goal.target;
    final lost = !won && ((_state.movesLeft ?? 1) <= 0 || _state.isGameOver);
    if (!won && !lost) return null;
    return LevelResult(
      levelId: level.id,
      won: won,
      stars: won ? starsFor(level, _state.score) : 0,
      score: _state.score,
      linesCleared: _state.linesCleared,
      movesUsed: _state.moves,
    );
  }

  /// Reverts the last move. Returns false if there is nothing to undo.
  bool undo() {
    final snapshot = _undoSnapshot;
    if (snapshot == null) return false;
    _state = snapshot;
    _undoSnapshot = null;
    return true;
  }

  /// Clears a 3x3 area and resumes play. Single use per game.
  /// Returns the cleared area's origin, or null if unavailable.
  (int, int)? revive() {
    if (!_state.isGameOver || _state.reviveUsed) return null;
    final (r, c) = Revive.findArea(_state.board, _state.tray);
    final board = Revive.apply(_state.board, r, c);
    var tray = _state.tray;
    if (Placement.isGameOver(board, tray)) {
      tray = List.unmodifiable(_spawner.nextTray(board, score: _state.score));
    }
    _undoSnapshot = null;
    _state = _state.copyWith(
      board: board,
      tray: tray,
      isGameOver: false,
      reviveUsed: true,
    );
    return (r, c);
  }

  @visibleForTesting
  void restoreForTest(GameState state) {
    _state = state;
    _undoSnapshot = null;
  }

  @visibleForTesting
  void forceGameOverForTest() {
    _state = _state.copyWith(isGameOver: true);
  }
}
