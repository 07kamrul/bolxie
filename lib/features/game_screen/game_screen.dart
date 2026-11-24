import 'dart:async';

import 'package:bloxie/core/constants/economy_constants.dart';
import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/common/snack.dart';
import 'package:bloxie/features/game_screen/game_hud.dart';
import 'package:bloxie/features/game_screen/game_over_overlay.dart';
import 'package:bloxie/features/game_screen/pause_overlay.dart';
import 'package:bloxie/features/game_screen/tutorial_overlay.dart';
import 'package:bloxie/features/levels/bloc/level_progress_cubit.dart';
import 'package:bloxie/features/levels/level_overlays.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/game/block_game.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/levels/levels_catalog.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/audio/audio_service.dart';
import 'package:bloxie/services/audio/haptics_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({this.level, super.key});

  /// Level mode: goals, move limits and prefills come from [spec].
  GameScreen.level(LevelSpec spec, {super.key}) : level = spec;

  final LevelSpec? level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final BlockGame _game;
  late int _bestAtStart;
  late DateTime _startedAt;

  GameState? _over;
  LevelResult? _levelResult;
  bool _isPaused = false;
  bool _isBusy = false;
  bool _isFinalized = false;

  /// Level mode: stats are recorded once per run, even across revives.
  bool _levelStatsRecorded = false;
  bool _showTutorial = false;
  bool _showIntro = false;

  bool get _isLevelMode => widget.level != null;

  @override
  void initState() {
    super.initState();
    final skin = Skins.byId(sl<ShopCubit>().state.selectedId);
    final level = widget.level;
    if (level != null) {
      _game = BlockGame.level(
        level: level,
        skin: skin,
        audio: sl<AudioService>(),
        haptics: sl<HapticsService>(),
        onLevelEnd: _handleLevelEnd,
        reduceMotion: sl<SettingsCubit>().state.reduceMotion,
      );
      _showIntro = true;
      // Hold the engine until the intro card's START button is pressed.
      _game.pauseGame();
    } else {
      _game = BlockGame(
        skin: skin,
        audio: sl<AudioService>(),
        haptics: sl<HapticsService>(),
        onGameOver: _handleGameOver,
        reduceMotion: sl<SettingsCubit>().state.reduceMotion,
      );
    }
    _showTutorial = !sl<PrefsRepository>().tutorialSeen;
    WidgetsBinding.instance.addObserver(this);
    _beginRun();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never let the game run (or a timer tick) while the app is hidden.
    final isHidden =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
    if (isHidden &&
        !_isPaused &&
        _over == null &&
        _levelResult == null &&
        !_isBusy &&
        !_showTutorial &&
        !_showIntro) {
      _pause();
    }
  }

  void _dismissTutorial() {
    unawaited(sl<PrefsRepository>().setTutorialSeen(true));
    setState(() => _showTutorial = false);
  }

  void _beginRun() {
    _startedAt = DateTime.now();
    _bestAtStart = sl<StatsCubit>().state.bestScore;
    _isFinalized = false;
    _levelStatsRecorded = false;
    unawaited(sl<AnalyticsService>().gameStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Leaving while the game-over overlay is up still counts the game.
    if (_over != null) unawaited(_finalize());
    super.dispose();
  }

  void _handleGameOver(GameState state) {
    if (!mounted) return;
    sl<AdService>().recordGameOver();
    unawaited(
      sl<AnalyticsService>().gameOver(
        score: state.score,
        durationSeconds: DateTime.now().difference(_startedAt).inSeconds,
      ),
    );
    setState(() => _over = state);
  }

  /// Level end (win or loss). Saves progress and coins exactly once.
  /// A loss may be revived and end again; a win always ends the run.
  void _handleLevelEnd(LevelResult result) {
    if (!mounted) return;
    if (!_levelStatsRecorded && (result.won || !_canReviveLevel)) {
      _recordLevelStats(result);
    }
    if (result.won) {
      unawaited(sl<LevelProgressCubit>().completeLevel(result));
      final coins =
          EconomyConstants.levelStarCoins[(result.stars - 1).clamp(0, 2)];
      unawaited(sl<WalletCubit>().addCoins(coins));
    }
    setState(() => _levelResult = result);
  }

  bool get _canReviveLevel =>
      (widget.level?.reviveAllowed ?? false) &&
      _game.session.state.isGameOver &&
      !_game.session.state.reviveUsed;

  void _recordLevelStats(LevelResult result) {
    _levelStatsRecorded = true;
    unawaited(
      sl<StatsCubit>().recordGame(
        score: result.score,
        lines: result.linesCleared,
      ),
    );
  }

  /// Records stats and coins exactly once per run, after any revive.
  /// Classic mode only; level mode saves inside [_handleLevelEnd].
  Future<void> _finalize() async {
    final over = _over;
    if (_isFinalized || over == null || _isLevelMode) return;
    _isFinalized = true;
    await sl<StatsCubit>().recordGame(
      score: over.score,
      lines: over.linesCleared,
    );
    await sl<WalletCubit>().addCoins(
      over.score ~/ EconomyConstants.scorePerCoin,
    );
  }

  Future<void> _undo() async {
    if (_isBusy || !_game.canUndo.value) return;
    _game.pauseGame();
    setState(() => _isBusy = true);
    final earned = await sl<AdService>().showRewarded(AdPlacement.undo);
    if (!mounted) return;
    _game.resumeGame();
    if (earned) {
      _game.undo();
    } else {
      showSnack(context, 'No ad available right now. Try again later.');
    }
    setState(() => _isBusy = false);
  }

  Future<void> _revive() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final earned = await sl<AdService>().showRewarded(AdPlacement.revive);
    if (!mounted) return;
    if (earned && _game.revive()) {
      setState(() {
        _over = null;
        _levelResult = null;
        _isBusy = false;
      });
      return;
    }
    setState(() => _isBusy = false);
    showSnack(context, 'No ad available right now. Try again later.');
  }

  /// Records a pending level loss the player chose not to revive.
  void _flushLevelLoss() {
    final r = _levelResult;
    if (_isLevelMode && r != null && !r.won && !_levelStatsRecorded) {
      _recordLevelStats(r);
    }
  }

  /// Classic: new endless run. Level mode: retry the same level.
  Future<void> _playAgain() async {
    _flushLevelLoss();
    await _finalize();
    setState(() => _isBusy = true);
    if (!_isLevelMode) {
      // Interstitials only appear here, between games, never mid-play.
      await sl<AdService>().maybeShowInterstitial();
      if (!mounted) return;
    }
    _game.restart();
    _beginRun();
    setState(() {
      _over = null;
      _levelResult = null;
      _isPaused = false;
      _isBusy = false;
    });
  }

  /// Pops this screen and opens the next level (level mode, win only).
  void _nextLevel() {
    final next = widget.level!.id + 1;
    if (next > LevelsCatalog.count) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen.level(LevelsCatalog.byId(next)),
      ),
    );
  }

  Future<void> _goHome() async {
    _flushLevelLoss();
    if (_isLevelMode) {
      Navigator.of(context).pop();
      return;
    }
    await _finalize();
    if (_over != null) {
      setState(() => _isBusy = true);
      await sl<AdService>().maybeShowInterstitial();
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _startLevel() {
    _game.resumeGame();
    setState(() => _showIntro = false);
  }

  void _pause() {
    _game.pauseGame();
    setState(() => _isPaused = true);
  }

  void _resume() {
    _game.resumeGame();
    setState(() => _isPaused = false);
  }

  @override
  Widget build(BuildContext context) {
    final skin = _game.skin;
    final over = _over;
    final levelResult = _levelResult;
    final level = widget.level;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (over != null || levelResult != null) {
          unawaited(_goHome());
        } else if (!_isPaused) {
          _pause();
        }
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [skin.bgTop, skin.bgBottom],
          ),
        ),
        child: Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    GameHud(
                      game: _game,
                      bestScore: _bestAtStart,
                      onPause: _pause,
                      onUndo: _undo,
                      goalText: level?.goalText,
                      showUndo: level?.undoAllowed ?? true,
                    ),
                    Expanded(
                      child: RepaintBoundary(
                        child: GameWidget<BlockGame>(game: _game),
                      ),
                    ),
                  ],
                ),
                if (_showTutorial)
                  Positioned.fill(
                    child: TutorialOverlay(onDone: _dismissTutorial),
                  ),
                if (_showIntro && level != null)
                  Positioned.fill(
                    child: LevelIntroOverlay(spec: level, onStart: _startLevel),
                  ),
                if (_isPaused)
                  Positioned.fill(
                    child: PauseOverlay(
                      onResume: _resume,
                      onRestart: () => unawaited(_playAgain()),
                      onHome: () => unawaited(_goHome()),
                    ),
                  ),
                if (levelResult != null && level != null)
                  Positioned.fill(
                    child: levelResult.won
                        ? LevelCompleteOverlay(
                            result: levelResult,
                            coinsEarned: EconomyConstants
                                .levelStarCoins[(levelResult.stars - 1)
                                    .clamp(0, 2)],
                            hasNextLevel:
                                levelResult.levelId < LevelsCatalog.count,
                            isBusy: _isBusy,
                            onNext: _nextLevel,
                            onReplay: () => unawaited(_playAgain()),
                            onLevels: () => unawaited(_goHome()),
                          )
                        : LevelFailedOverlay(
                            result: levelResult,
                            canRevive: _canReviveLevel,
                            isBusy: _isBusy,
                            onRevive: () => unawaited(_revive()),
                            onRetry: () => unawaited(_playAgain()),
                            onLevels: () => unawaited(_goHome()),
                          ),
                  ),
                if (over != null)
                  Positioned.fill(
                    child: GameOverOverlay(
                      score: over.score,
                      bestScore: over.score > _bestAtStart
                          ? over.score
                          : _bestAtStart,
                      isNewBest: over.score > _bestAtStart,
                      coinsEarned: over.score ~/ EconomyConstants.scorePerCoin,
                      canRevive: !over.reviveUsed,
                      isBusy: _isBusy,
                      onRevive: () => unawaited(_revive()),
                      onPlayAgain: () => unawaited(_playAgain()),
                      onHome: () => unawaited(_goHome()),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
