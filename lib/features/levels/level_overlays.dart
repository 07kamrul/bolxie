import 'package:bloxie/features/common/reward_labels.dart';
import 'package:bloxie/features/common/constrained_content.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:material_ui/material_ui.dart';

/// Shown before a level starts: goal, move limit and rules.
class LevelIntroOverlay extends StatelessWidget {
  const LevelIntroOverlay({
    required this.spec,
    required this.onStart,
    super.key,
  });

  final LevelSpec spec;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: ScrollableCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'LEVEL ${spec.id}',
              style: const TextStyle(
                fontSize: 20,
                letterSpacing: 3,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              spec.title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),
            Text(
              spec.goalText,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4DB8FF),
              ),
            ),
            if (spec.moveLimit != null) ...[
              const SizedBox(height: 8),
              Text(
                '${spec.moveLimit} moves only',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            if (!spec.undoAllowed) ...[
              const SizedBox(height: 8),
              const Text('No undo', style: TextStyle(color: Colors.white70)),
            ],
            const SizedBox(height: 32),
            FilledButton(onPressed: onStart, child: const Text('START')),
          ],
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Icon(
            i < count ? Icons.star_rounded : Icons.star_outline_rounded,
            color: i < count ? const Color(0xFFFFD43B) : Colors.white30,
            size: 44,
          ),
      ],
    );
  }
}

/// Won: stars, score, coins, then next / replay / level list.
class LevelCompleteOverlay extends StatelessWidget {
  const LevelCompleteOverlay({
    required this.result,
    required this.coinsEarned,
    required this.hasNextLevel,
    required this.isBusy,
    required this.onNext,
    required this.onReplay,
    required this.onLevels,
    super.key,
  });

  final LevelResult result;
  final int coinsEarned;
  final bool hasNextLevel;
  final bool isBusy;
  final VoidCallback onNext;
  final VoidCallback onReplay;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: ScrollableCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEVEL CLEAR!',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            _StarsRow(count: result.stars),
            const SizedBox(height: 12),
            Text(
              '${result.score}',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900),
            ),
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
            if (hasNextLevel) ...[
              FilledButton(
                onPressed: isBusy ? null : onNext,
                child: const Text('NEXT LEVEL'),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.tonal(
              onPressed: isBusy ? null : onReplay,
              child: const Text('REPLAY'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isBusy ? null : onLevels,
              child: const Text('LEVELS'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lost: retry or back to the level list (revive only when the board jammed).
class LevelFailedOverlay extends StatelessWidget {
  const LevelFailedOverlay({
    required this.result,
    required this.canRevive,
    required this.isBusy,
    required this.onRevive,
    required this.onRetry,
    required this.onLevels,
    super.key,
  });

  final LevelResult result;
  final bool canRevive;
  final bool isBusy;
  final VoidCallback onRevive;
  final VoidCallback onRetry;
  final VoidCallback onLevels;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.78),
      child: ScrollableCenter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'LEVEL FAILED',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Text(
              'Score ${result.score}',
              style: const TextStyle(fontSize: 24, color: Colors.white70),
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
              onPressed: isBusy ? null : onRetry,
              child: const Text('RETRY'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isBusy ? null : onLevels,
              child: const Text('LEVELS'),
            ),
          ],
        ),
      ),
    );
  }
}
