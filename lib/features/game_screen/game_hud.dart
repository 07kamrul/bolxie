import 'package:bloxie/core/theme/breakpoints.dart';
import 'package:bloxie/game/block_game.dart';
import 'package:material_ui/material_ui.dart';

class GameHud extends StatelessWidget {
  const GameHud({
    required this.game,
    required this.bestScore,
    required this.onPause,
    required this.onUndo,
    super.key,
  });

  final BlockGame game;
  final int bestScore;
  final VoidCallback onPause;
  final VoidCallback onUndo;

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
                          child: Text(
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
                onPressed: canUndo ? onUndo : null,
                iconSize: iconSize - 4,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                tooltip: 'Undo (watch ad)',
                icon: Badge(
                  label: const Icon(Icons.play_arrow, size: 10),
                  isLabelVisible: canUndo,
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
