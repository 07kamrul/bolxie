import 'dart:async';

import 'package:bloxie/core/constants/economy_constants.dart';
import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/common/snack.dart';
import 'package:bloxie/features/game_screen/game_hud.dart';
import 'package:bloxie/features/game_screen/game_over_overlay.dart';
import 'package:bloxie/features/game_screen/pause_overlay.dart';
import 'package:bloxie/features/game_screen/tutorial_overlay.dart';
import 'package:bloxie/features/settings/bloc/settings_cubit.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/game/block_game.dart';
import 'package:bloxie/game/logic/game_session.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/audio/audio_service.dart';
import 'package:bloxie/services/audio/haptics_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final BlockGame _game;
  late int _bestAtStart;
  late DateTime _startedAt;

  GameState? _over;
  bool _isPaused = false;
  bool _isBusy = false;
  bool _isFinalized = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    final skin = Skins.byId(sl<ShopCubit>().state.selectedId);
    _game = BlockGame(
      skin: skin,
      audio: sl<AudioService>(),
      haptics: sl<HapticsService>(),
      onGameOver: _handleGameOver,
      reduceMotion: sl<SettingsCubit>().state.reduceMotion,
    );
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
    if (isHidden && !_isPaused && _over == null && !_isBusy && !_showTutorial) {
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

  /// Records stats and coins exactly once per run, after any revive.
  Future<void> _finalize() async {
    final over = _over;
    if (_isFinalized || over == null) return;
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
        _isBusy = false;
      });
      return;
    }
    setState(() => _isBusy = false);
    showSnack(context, 'No ad available right now. Try again later.');
  }

  Future<void> _playAgain() async {
    await _finalize();
    // Interstitials only appear here, between games, never mid-play.
    setState(() => _isBusy = true);
    await sl<AdService>().maybeShowInterstitial();
    if (!mounted) return;
    _game.restart();
    _beginRun();
    setState(() {
      _over = null;
      _isPaused = false;
      _isBusy = false;
    });
  }

  Future<void> _goHome() async {
    await _finalize();
    if (_over != null) {
      setState(() => _isBusy = true);
      await sl<AdService>().maybeShowInterstitial();
    }
    if (mounted) Navigator.of(context).pop();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (over != null) {
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
                if (_isPaused)
                  Positioned.fill(
                    child: PauseOverlay(
                      onResume: _resume,
                      onRestart: _playAgain,
                      onHome: _goHome,
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
                      onRevive: _revive,
                      onPlayAgain: _playAgain,
                      onHome: _goHome,
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
