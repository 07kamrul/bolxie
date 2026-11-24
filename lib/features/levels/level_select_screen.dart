import 'package:bloxie/core/theme/breakpoints.dart';
import 'package:bloxie/features/common/gradient_scaffold.dart';
import 'package:bloxie/features/game_screen/game_screen.dart';
import 'package:bloxie/features/levels/bloc/level_progress_cubit.dart';
import 'package:bloxie/game/levels/level_spec.dart';
import 'package:bloxie/game/levels/levels_catalog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// World themes for headers.
const _worldNames = {
  1: 'Basics',
  2: 'Line Worker',
  3: 'Tight Fit',
  4: 'Stone Breakers',
  5: 'Master',
};

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  void _openLevel(BuildContext context, LevelSpec spec) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => GameScreen.level(spec)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<LevelProgressCubit>().state;
    final size = MediaQuery.sizeOf(context);
    final tile = Breakpoints.isWide(size) ? 84.0 : 64.0;
    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  BackButton(onPressed: () => Navigator.of(context).pop()),
                  const Expanded(
                    child: Text(
                      'LEVELS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      children: [
                        for (var world = 1; world <= 5; world++) ...[
                          _WorldHeader(world: world),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: [
                              for (final spec in LevelsCatalog.all.where(
                                (l) => l.world == world,
                              ))
                                _LevelTile(
                                  spec: spec,
                                  unlocked: progress.isUnlocked(spec.id),
                                  stars: progress.starsFor(spec.id),
                                  size: tile,
                                  onTap: progress.isUnlocked(spec.id)
                                      ? () => _openLevel(context, spec)
                                      : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldHeader extends StatelessWidget {
  const _WorldHeader({required this.world});

  final int world;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 12),
      child: Row(
        children: [
          Text(
            'WORLD $world · ${_worldNames[world] ?? ''}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Divider(color: Colors.white24)),
        ],
      ),
    );
  }
}

class _LevelTile extends StatelessWidget {
  const _LevelTile({
    required this.spec,
    required this.unlocked,
    required this.stars,
    required this.size,
    required this.onTap,
  });

  final LevelSpec spec;
  final bool unlocked;
  final int stars;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = unlocked
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${spec.id}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < 3; i++)
                    Icon(
                      Icons.star_rounded,
                      size: 14,
                      color: i < stars
                          ? const Color(0xFFFFD43B)
                          : Colors.white24,
                    ),
                ],
              ),
            ],
          )
        : Icon(Icons.lock_rounded, size: size * 0.3, color: Colors.white24);
    return Semantics(
      button: true,
      label: unlocked
          ? 'Level ${spec.id}, $stars stars'
          : 'Level ${spec.id} locked',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: unlocked
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white24),
          ),
          child: Center(child: content),
        ),
      ),
    );
  }
}
