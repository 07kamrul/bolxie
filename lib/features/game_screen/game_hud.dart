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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onPause,
            icon: const Icon(Icons.pause_circle_filled_rounded),
            iconSize: 36,
            tooltip: 'Pause',
          ),
          Expanded(
            child: Column(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, __) => Text(
                    '$score',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: game.score,
                  builder: (_, score, __) => Text(
                    'BEST ${score > bestScore ? score : bestScore}',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: game.canUndo,
            builder: (_, canUndo, __) => IconButton(
              onPressed: canUndo ? onUndo : null,
              iconSize: 32,
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
    );
  }
}
