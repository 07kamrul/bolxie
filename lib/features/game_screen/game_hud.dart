import 'package:bloxie/core/platform/platform_info.dart';
import 'package:bloxie/features/common/reward_labels.dart';
import 'package:bloxie/core/theme/breakpoints.dart';
import 'package:bloxie/game/block_game.dart';
import 'package:material_ui/material_ui.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.game,
    required this.bestScore,
    required this.onPause,
    required this.onUndo,
    this.goalText,
    this.showUndo = true,
    super.key,
  });

  final BlockGame game;
  final int bestScore;
  final VoidCallback onPause;
  final VoidCallback onUndo;

  /// Level mode: shows the goal and remaining moves instead of BEST.
  final String? goalText;

  /// Level mode can disable undo entirely.
  final bool showUndo;

  bool get _isLevelMode => goalText != null;

  static const Duration _countUp = Duration(milliseconds: 350);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isCompact =
        Breakpoints.isCompactHeight(size) || Breakpoints.isCompactWidth(size);
    final scoreSize = isCompact ? 28.0 : 38.0;
    final iconSize = isCompact ? 30.0 : 36.0;
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Row(
          children: [
            IconButton(
              onPressed: onPause,
              icon: const Icon(Icons.pause_circle_filled_rounded),
              iconSize: iconSize,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              tooltip: 'Pause',
            ),
            Expanded(
              child: ValueListenableBuilder<int>(
                valueListenable: game.score,
                builder: (_, score, __) {
                  final isNewBest = bestScore > 0 && score > bestScore;
                  return Semantics(
                    liveRegion: true,
                    label:
                        'Score $score, best ${isNewBest ? score : bestScore}',
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: TweenAnimationBuilder<int>(
                            tween: IntTween(end: score),
                            duration: _countUp,
                            curve: Curves.easeOut,
                            builder: (_, v, __) => Text(
                              '$v',
                              style: TextStyle(
                                fontSize: scoreSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _isLevelMode
                              ? ValueListenableBuilder<int>(
                                  valueListenable: game.goalProgress,
                                  builder: (_, progress, __) =>
                                      ValueListenableBuilder<int?>(
                                        valueListenable: game.movesLeft,
                                        builder: (_, moves, ___) => Text(
                                          '$goalText · MOVES ${moves ?? '∞'}',
                                          key: const ValueKey('goal'),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF4DB8FF),
                                          ),
                                        ),
                                      ),
                                )
                              : Text(
                                  isNewBest
                                      ? 'NEW BEST!'
                                      : 'BEST ${bestScore > score ? bestScore : score}',
                                  key: ValueKey(isNewBest),
                                  style: TextStyle(
                                    fontSize: 12,
                                    letterSpacing: 1.5,
                                    fontWeight: isNewBest
                                        ? FontWeight.w900
                                        : FontWeight.normal,
                                    color: isNewBest
                                        ? const Color(0xFFFFD43B)
                                        : Colors.white70,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.combo,
              builder: (_, combo, __) => AnimatedOpacity(
                opacity: combo >= 2 ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: Text(
                  'x$combo',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFFFB84D),
                  ),
                ),
              ),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: game.canUndo,
              builder: (_, canUndo, __) => IconButton(
                onPressed: showUndo && canUndo ? onUndo : null,
                iconSize: iconSize - 4,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: RewardLabels.undoTooltip,
                icon: Badge(
                  label: const Icon(Icons.play_arrow, size: 10),
                  isLabelVisible: !PlatformInfo.isWeb && showUndo && canUndo,
                  child: const Icon(Icons.undo_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
