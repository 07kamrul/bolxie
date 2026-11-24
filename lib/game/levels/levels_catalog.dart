import 'package:bloxie/game/levels/level_spec.dart';

/// All 50 levels, built from one compact table so difficulty rises in
/// standard steps: each world unlocks a new mechanic and tightens limits.
abstract final class LevelsCatalog {
  /// Small shapes only: 1-3 cell bars and the 2x2 square.
  static const List<String> _smallShapes = [
    'single',
    'h2',
    'v2',
    'h3',
    'v3',
    'sq2',
  ];

  /// Adds the L and T families and 4-long bars.
  static const List<String> _midShapes = [
    ..._smallShapes,
    'h4',
    'v4',
    'l0',
    'l1',
    'l2',
    'l3',
    't0',
    't1',
    't2',
    't3',
  ];

  /// Everything, including 5-long bars, Z/S and the 3x3 square.
  // Represented by a null allowedShapeIds; kept implicit for clarity.

  // Prefill patterns (8x8). '.' empty, 'X' filled, 'B' blocker stone.
  static const _lightA = [
    '........',
    '..X.....',
    '........',
    '......X.',
    '.X......',
    '........',
    '.....X..',
    '........',
  ];
  static const _lightB = [
    'X.......',
    '........',
    '.......X',
    '........',
    '........',
    'X.......',
    '........',
    '.......X',
  ];
  static const _mediumA = [
    'XX......',
    'XX......',
    '......XX',
    '........',
    '........',
    'XX......',
    '......XX',
    '......XX',
  ];
  static const _mediumB = [
    '...XX...',
    '...XX...',
    '........',
    'XX....XX',
    'XX....XX',
    '........',
    '...XX...',
    '...XX...',
  ];
  static const _blockerCenter = [
    '........',
    '........',
    '..BB....',
    '..BB..B.',
    '........',
    '....BB..',
    '.B..BB..',
    '........',
  ];
  static const _blockerEdges = [
    'BB..B...',
    '........',
    '..B...BB',
    '........',
    'BB...B..',
    '........',
    '...B..BB',
    '.......B',
  ];
  static const _blockerHeavy = [
    '.BB..BB.',
    '..B..B..',
    '........',
    '.BB..BB.',
    '.BB..BB.',
    '........',
    '..B..B..',
    '.BB..BB.',
  ];
  static const _denseA = [
    'XX....XX',
    'XX....XX',
    '........',
    '...XX...',
    '...XX...',
    '........',
    'XX....XX',
    'XX....XX',
  ];
  static const _denseB = [
    'X.X..X.X',
    '.B.XX.B.',
    'X.X..X.X',
    '........',
    '........',
    'X.X..X.X',
    '.B.XX.B.',
    'X.X..X.X',
  ];

  static final List<LevelSpec> all = List.unmodifiable(_build());

  static LevelSpec byId(int id) => all.firstWhere(
    (l) => l.id == id,
    orElse: () => throw StateError('level $id'),
  );

  static int get count => all.length;

  static List<LevelSpec> _build() {
    final levels = <LevelSpec>[];

    // ── World 1: Basics (1-10) — score goals, small shapes, no limits ───
    const w1Scores = [300, 450, 600, 750, 900, 1000, 1100, 1200, 1300, 1500];
    for (var i = 0; i < 10; i++) {
      levels.add(
        LevelSpec(
          id: i + 1,
          world: 1,
          title: 'First Steps ${i + 1}',
          goal: LevelGoal.reachScore(w1Scores[i]),
          starThresholds: [
            w1Scores[i],
            (w1Scores[i] * 1.5).round(),
            w1Scores[i] * 2,
          ],
          allowedShapeIds: _smallShapes,
        ),
      );
    }

    // ── World 2: More Shapes (11-20) — line goals, L/T unlocked ────────
    const w2Lines = [4, 5, 6, 7, 8, 8, 9, 9, 10, 12];
    const w2Moves = [40, 40, 38, 38, 36, 36, 34, 34, 32, 32];
    for (var i = 0; i < 10; i++) {
      final target = w2Lines[i];
      levels.add(
        LevelSpec(
          id: 11 + i,
          world: 2,
          title: 'Line Worker ${i + 1}',
          goal: LevelGoal.clearLines(target),
          starThresholds: [target * 60, target * 90, target * 130],
          moveLimit: w2Moves[i],
          prefill: i.isEven ? _lightA : _lightB,
          allowedShapeIds: _midShapes,
          bigShapeBias: 0.2,
        ),
      );
    }

    // ── World 3: Tight Board (21-30) — stricter moves, all shapes ──────
    const w3Lines = [10, 11, 12, 12, 13, 13, 14, 14, 15, 16];
    const w3Moves = [30, 30, 28, 28, 26, 26, 24, 24, 22, 20];
    for (var i = 0; i < 10; i++) {
      final target = w3Lines[i];
      levels.add(
        LevelSpec(
          id: 21 + i,
          world: 3,
          title: 'Tight Fit ${i + 1}',
          goal: LevelGoal.clearLines(target),
          starThresholds: [target * 70, target * 105, target * 150],
          moveLimit: w3Moves[i],
          prefill: i.isEven ? _mediumA : _mediumB,
          bigShapeBias: 0.4,
        ),
      );
    }

    // ── World 4: Stone Breakers (31-40) — blockers appear ──────────────
    // Each target stays below its board's stone count (center 10,
    // edges 13, heavy 20) so every level leaves room for error.
    const w4Stones = [6, 7, 8, 9, 10, 9, 12, 11, 14, 16];
    const w4Moves = [25, 25, 24, 24, 22, 22, 20, 20, 19, 18];
    const w4Prefills = [
      _blockerCenter,
      _blockerEdges,
      _blockerCenter,
      _blockerEdges,
      _blockerHeavy,
      _blockerCenter,
      _blockerHeavy,
      _blockerEdges,
      _blockerHeavy,
      _blockerHeavy,
    ];
    for (var i = 0; i < 10; i++) {
      final target = w4Stones[i];
      levels.add(
        LevelSpec(
          id: 31 + i,
          world: 4,
          title: 'Stone Breaker ${i + 1}',
          goal: LevelGoal.clearBlockers(target),
          starThresholds: [target * 80, target * 120, target * 170],
          moveLimit: w4Moves[i],
          prefill: w4Prefills[i],
          bigShapeBias: 0.5,
        ),
      );
    }

    // ── World 5: Master (41-50) — mixed goals, undo off, dense boards ──
    const w5Moves = [18, 18, 17, 17, 16, 16, 15, 15, 14, 12];
    for (var i = 0; i < 10; i++) {
      final id = 41 + i;
      final moveLimit = w5Moves[i];
      final prefill = i.isEven ? _denseA : _denseB;
      final LevelSpec spec;
      switch (i) {
        case 0:
        case 1:
          final target = 16 + i * 2;
          spec = LevelSpec(
            id: id,
            world: 5,
            title: 'Master ${i + 1}',
            goal: LevelGoal.clearLines(target),
            starThresholds: [target * 80, target * 120, target * 170],
            moveLimit: moveLimit,
            prefill: prefill,
            bigShapeBias: 0.6,
          );
        case 2:
        case 3:
          final target = 1800 + i * 200;
          spec = LevelSpec(
            id: id,
            world: 5,
            title: 'Master ${i + 1}',
            goal: LevelGoal.reachScore(target),
            starThresholds: [target, (target * 1.4).round(), target * 2],
            moveLimit: moveLimit,
            prefill: prefill,
            bigShapeBias: 0.7,
          );
        case 4:
        case 5:
          final target = 17 + i;
          spec = LevelSpec(
            id: id,
            world: 5,
            title: 'Master ${i + 1}',
            goal: LevelGoal.clearLines(target),
            starThresholds: [target * 90, target * 135, target * 190],
            moveLimit: moveLimit,
            prefill: prefill,
            bigShapeBias: 0.7,
          );
        case 6:
        case 7:
          final target = 11 + i;
          spec = LevelSpec(
            id: id,
            world: 5,
            title: 'Master ${i + 1}',
            goal: LevelGoal.clearColor(target, 3),
            starThresholds: [target * 110, target * 160, target * 220],
            moveLimit: moveLimit,
            prefill: prefill,
            bigShapeBias: 0.7,
            undoAllowed: false,
          );
        default:
          final target = 20 + (i - 8);
          spec = LevelSpec(
            id: id,
            world: 5,
            title: 'Final Exam ${i - 7}',
            goal: LevelGoal.clearLines(target),
            starThresholds: [target * 100, target * 150, target * 210],
            moveLimit: moveLimit,
            prefill: prefill,
            bigShapeBias: 0.8,
            undoAllowed: false,
            reviveAllowed: false,
          );
      }
      levels.add(spec);
    }

    return levels;
  }
}
