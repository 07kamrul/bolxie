import 'package:bloxie/features/common/reward_labels.dart';
import 'package:bloxie/features/common/constrained_content.dart';
import 'package:material_ui/material_ui.dart';

class GameOverOverlay extends StatelessWidget {
  const GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.isNewBest,
    required this.coinsEarned,
    required this.canRevive,
    required this.isBusy,
    required this.onRevive,
    required this.onPlayAgain,
    required this.onHome,
    super.key,
  });

  final int score;
  final int bestScore;
  final bool isNewBest;
  final int coinsEarned;
  final bool canRevive;
  final bool isBusy;
  final VoidCallback onRevive;
  final VoidCallback onPlayAgain;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: ScrollableCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isNewBest ? 'NEW BEST!' : 'GAME OVER',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: TweenAnimationBuilder<int>(
                tween: IntTween(begin: 0, end: score),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => Text(
                  '$v',
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Text(
              'BEST $bestScore',
              style: const TextStyle(letterSpacing: 2, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Color(0xFFFFD43B)),
                const SizedBox(width: 6),
                Text(
                  '+$coinsEarned',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 28),
            if (canRevive) ...[
              FilledButton.icon(
                onPressed: isBusy ? null : onRevive,
                icon: const Icon(Icons.favorite),
                label: Text(RewardLabels.revive),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.tonal(
              onPressed: isBusy ? null : onPlayAgain,
              child: const Text('PLAY AGAIN'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isBusy ? null : onHome,
              child: const Text('HOME'),
            ),
          ],
        ),
      ),
    );
  }
}
