import 'dart:math';
import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/core/theme/game_skin.dart';
import 'package:bloxie/game/components/background_component.dart';
import 'package:bloxie/game/components/block_painter.dart';
import 'package:bloxie/game/components/board_component.dart';
import 'package:bloxie/game/components/particle_system.dart';
import 'package:bloxie/game/components/popup_layer.dart';
import 'package:bloxie/game/components/tray_piece.dart';
import 'package:bloxie/game/game_layout.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/game/logic/scoring.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:bloxie/game/logic/spawner.dart';
import 'package:bloxie/services/audio/audio_service.dart';
import 'package:bloxie/services/audio/haptics_service.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

/// Flame root. Owns the in-game state ([GameSession]) and the render tree;
/// the Flutter layer observes it through the exposed notifiers.
class BlockGame extends FlameGame {
  BlockGame({
    required this.skin,
    required this.audio,
    required this.haptics,
    this.onGameOver,
    this.onLevelEnd,
    this.reduceMotion = false,
    Spawner? spawner,
  }) : session = GameSession(spawner: spawner ?? Spawner());

  /// Creates a level-mode game driven by [level]'s spec.
  BlockGame.level({
    required LevelSpec level,
    required this.skin,
    required this.audio,
    required this.haptics,
    this.onGameOver,
    this.onLevelEnd,
    this.reduceMotion = false,
  }) : session = GameSession.level(level);

  final GameSkin skin;
  final AudioService audio;
  final HapticsService haptics;
  final GameSession session;

  /// Skips screen shake and thins particle bursts.
  final bool reduceMotion;

  /// Called once per game over, after the final clear animation has played.
  void Function(GameState state)? onGameOver;

  /// Called once when a level is won or lost (level mode only).
  void Function(LevelResult result)? onLevelEnd;

  final ValueNotifier<int> score = ValueNotifier(0);
  final ValueNotifier<int> combo = ValueNotifier(0);
  final ValueNotifier<bool> canUndo = ValueNotifier(false);
  final ValueNotifier<int?> movesLeft = ValueNotifier(null);
  final ValueNotifier<int> goalProgress = ValueNotifier(0);

  GameLayout layout = GameLayout(0, 0);
  late BlockPainter painter = BlockPainter(cell: 1, skin: skin);

  BoardComponent? _board;
  late final ParticleSystem _particles = ParticleSystem(palette: skin.palette);
  late final PopupLayer _popups = PopupLayer();

  static const double _gameOverDelaySeconds = 0.8;
  static const double _bigShakeAmplitude = 12;
  static const double _smallShakeAmplitude = 5;

  bool _userPaused = false;
  bool _levelFinished = false;

  /// When set, the game-over countdown fires the level-end callback with a
  /// loss instead of the classic game-over callback.
  bool _failAtCountdown = false;

  /// Win waiting for its short celebration delay; driven by update().
  LevelResult? _pendingWin;
  double _winCountdown = -1;
  static const double _levelWinDelaySeconds = 0.6;
  double _gameOverCountdown = -1;
  double _shakeLeft = 0;
  double _shakeAmplitude = 0;

  int get _particleCount => reduceMotion ? 1 : GameConstants.particlesPerCell;

  bool get isInteractive =>
      !_userPaused &&
      _gameOverCountdown < 0 &&
      !_levelFinished &&
      !session.state.isGameOver;

  @override
  Color backgroundColor() => skin.bgBottom;

  @override
  Future<void> onLoad() async {
    session.start();
    painter = BlockPainter(cell: layout.cell, skin: skin);
    final board = BoardComponent(
      skin: skin,
      painter: painter,
      layout: layout,
      boardSource: () => session.state.board,
    )..relayout(layout, painter);
    _board = board;
    await addAll([
      BackgroundComponent(skin),
      board,
      _particles,
      for (var i = 0; i < GameConstants.trayCapacity; i++) TrayPiece(i),
      _popups,
    ]);
    _syncNotifiers();
  }

  @override
  void onGameResize(Vector2 size) {
    layout = GameLayout(size.x, size.y);
    painter = BlockPainter(cell: layout.cell, skin: skin);
    _board?.relayout(layout, painter);
    _particles.unit = layout.unit;
    _popups.unit = layout.unit;
    super.onGameResize(size);
  }

  void _syncNotifiers() {
    final s = session.state;
    score.value = s.score;
    combo.value = s.combo;
    canUndo.value = session.canUndo;
    movesLeft.value = s.movesLeft;
    goalProgress.value = session.goalProgress;
  }

  void setGhost(ShapeDef? shape, int row, int col) =>
      _board?.setGhost(shape, row, col);

  /// Attempts the placement; returns false if the move was invalid.
  bool placeFromTray(int slot, int row, int col) {
    final outcome = session.place(slot, row, col);
    if (outcome == null) return false;
    _board?.onPlaced(outcome.shape, row, col);
    audio.play(Sfx.place);
    haptics.light();
    if (!outcome.cleared.isEmpty) _playClear(outcome);
    _syncNotifiers();

    final levelResult = outcome.levelResult;
    if (levelResult != null) {
      _levelFinished = true;
      if (levelResult.won) {
        audio.play(Sfx.combo);
        haptics.heavy();
        // Fired from update() so pausing also holds the win screen.
        _pendingWin = levelResult;
        _winCountdown = _levelWinDelaySeconds;
      } else {
        // Failed (out of moves or no fits): reuse the game-over flow.
        _gameOverCountdown = outcome.cleared.isEmpty
            ? 0.35
            : _gameOverDelaySeconds;
        _failAtCountdown = true;
      }
      return true;
    }
    if (session.state.isGameOver) {
      _gameOverCountdown = outcome.cleared.isEmpty
          ? 0.35
          : _gameOverDelaySeconds;
    }
    return true;
  }

  void _playClear(PlaceOutcome outcome) {
    final indices = outcome.cleared.cellIndices;
    final colors = outcome.clearedColors;
    _board?.onCleared(indices, colors);
    for (var k = 0; k < indices.length; k++) {
      final i = indices[k];
      _particles.burst(
        layout.cellX(i % GameConstants.gridSize) + layout.cell / 2,
        layout.cellY(i ~/ GameConstants.gridSize) + layout.cell / 2,
        colors[k] - 1,
        count: _particleCount,
      );
    }

    final lines = outcome.cleared.lineCount;
    final isBig = Scoring.isBigCombo(lines) || outcome.score.combo >= 3;
    audio.play(lines >= 2 || outcome.score.combo >= 2 ? Sfx.combo : Sfx.clear);
    if (isBig) {
      haptics.heavy();
      _shake(_bigShakeAmplitude);
    } else {
      haptics.medium();
      if (lines >= 2) _shake(_smallShakeAmplitude);
    }

    final u = layout.unit;
    final cx = layout.boardCenterX;
    final cy = layout.boardCenterY;
    final title = switch (lines) {
      1 => null,
      2 => 'DOUBLE!',
      3 => 'TRIPLE!',
      _ => 'AMAZING!',
    };
    if (title != null) {
      _popups.show(
        title,
        cx,
        cy - 40 * u,
        color: skin.palette[1],
        size: 40 * _fontScale,
      );
    }
    if (outcome.score.combo >= 2) {
      _popups.show(
        'COMBO x${outcome.score.combo}',
        cx,
        cy + 10 * u,
        color: skin.accent,
        size: 34 * _fontScale,
      );
    }
    _popups.show(
      '+${outcome.score.points}',
      cx,
      cy + 60 * u,
      size: 28 * _fontScale,
    );
  }

  double get _fontScale => layout.unit.clamp(0.7, 1.6);

  void _shake(double amplitude) {
    if (reduceMotion) return;
    _shakeAmplitude = amplitude * layout.unit;
    _shakeLeft = GameConstants.shakeSeconds;
  }

  bool undo() {
    if (_levelFinished || !session.undo()) return false;
    _board?.resetAnimations();
    _gameOverCountdown = -1;
    _syncNotifiers();
    return true;
  }

  /// Revive after game over: clears the best 3x3 area with a burst.
  bool revive() {
    final before = session.state.board;
    final area = session.revive();
    if (area == null) return false;
    _levelFinished = false;
    final (r0, c0) = area;
    final indices = <int>[];
    final colors = <int>[];
    for (var r = r0; r < r0 + GameConstants.reviveAreaSize; r++) {
      for (var c = c0; c < c0 + GameConstants.reviveAreaSize; c++) {
        final v = before.at(r, c);
        if (v != 0 && v != BoardState.blockerValue) {
          indices.add(BoardState.indexOf(r, c));
          colors.add(before.at(r, c));
          _particles.burst(
            layout.cellX(c) + layout.cell / 2,
            layout.cellY(r) + layout.cell / 2,
            before.at(r, c) - 1,
            count: _particleCount,
          );
        }
      }
    }
    _board?.onCleared(indices, colors);
    _gameOverCountdown = -1;
    haptics.heavy();
    audio.play(Sfx.clear);
    _syncNotifiers();
    return true;
  }

  void restart() {
    session.start();
    _board?.resetAnimations();
    _gameOverCountdown = -1;
    _levelFinished = false;
    _failAtCountdown = false;
    _pendingWin = null;
    _winCountdown = -1;
    _shakeLeft = 0;
    _syncNotifiers();
    resumeIfPaused();
  }

  void pauseGame() {
    _userPaused = true;
    pauseEngine();
  }

  void resumeGame() {
    _userPaused = false;
    resumeEngine();
  }

  void resumeIfPaused() {
    if (_userPaused || paused) resumeGame();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_shakeLeft > 0) _shakeLeft = max(0, _shakeLeft - dt);
    final win = _pendingWin;
    if (win != null && _winCountdown >= 0) {
      _winCountdown -= dt;
      if (_winCountdown < 0) {
        _pendingWin = null;
        onLevelEnd?.call(win);
      }
    }
    if (_gameOverCountdown >= 0) {
      _gameOverCountdown -= dt;
      if (_gameOverCountdown < 0) {
        // Leave the countdown at -1 so isInteractive re-evaluates from state,
        // which is still game over until revive/restart.
        audio.play(Sfx.gameOver);
        haptics.heavy();
        if (_failAtCountdown) {
          _failAtCountdown = false;
          final level = session.level!;
          onLevelEnd?.call(
            LevelResult(
              levelId: level.id,
              won: false,
              stars: 0,
              score: session.state.score,
              linesCleared: session.state.linesCleared,
              movesUsed: session.state.moves,
            ),
          );
        } else {
          onGameOver?.call(session.state);
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_shakeLeft <= 0) {
      super.render(canvas);
      return;
    }
    final f = _shakeLeft / GameConstants.shakeSeconds;
    canvas.save();
    canvas.translate(
      sin(_shakeLeft * 90) * _shakeAmplitude * f,
      cos(_shakeLeft * 70) * _shakeAmplitude * f,
    );
    super.render(canvas);
    canvas.restore();
  }
}
