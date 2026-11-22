import 'package:bloxie/game/logic/shape.dart';

/// All shapes the spawner can offer. Orientations are separate entries
/// because the player cannot rotate pieces.
abstract final class ShapesCatalog {
  static final List<ShapeDef> all = List.unmodifiable(<ShapeDef>[
    ShapeDef.fromPattern('single', ['X'], colorIndex: 0, weight: 6),
    ShapeDef.fromPattern('h2', ['XX'], colorIndex: 1),
    ShapeDef.fromPattern('v2', ['X', 'X'], colorIndex: 1),
    ShapeDef.fromPattern('h3', ['XXX'], colorIndex: 2),
    ShapeDef.fromPattern('v3', ['X', 'X', 'X'], colorIndex: 2),
    ShapeDef.fromPattern('h4', ['XXXX'], colorIndex: 3, weight: 7),
    ShapeDef.fromPattern('v4', ['X', 'X', 'X', 'X'], colorIndex: 3, weight: 7),
    ShapeDef.fromPattern('h5', ['XXXXX'], colorIndex: 4, weight: 4),
    ShapeDef.fromPattern(
      'v5',
      ['X', 'X', 'X', 'X', 'X'],
      colorIndex: 4,
      weight: 4,
    ),
    ShapeDef.fromPattern('sq2', ['XX', 'XX'], colorIndex: 5, weight: 12),
    ShapeDef.fromPattern(
      'sq3',
      ['XXX', 'XXX', 'XXX'],
      colorIndex: 6,
      weight: 4,
    ),
    // L family
    ShapeDef.fromPattern('l0', ['X.', 'X.', 'XX'], colorIndex: 0, weight: 6),
    ShapeDef.fromPattern('l1', ['XXX', 'X..'], colorIndex: 0, weight: 6),
    ShapeDef.fromPattern('l2', ['XX', '.X', '.X'], colorIndex: 0, weight: 6),
    ShapeDef.fromPattern('l3', ['..X', 'XXX'], colorIndex: 0, weight: 6),
    // T family
    ShapeDef.fromPattern('t0', ['XXX', '.X.'], colorIndex: 2, weight: 6),
    ShapeDef.fromPattern('t1', ['.X.', 'XXX'], colorIndex: 2, weight: 6),
    ShapeDef.fromPattern('t2', ['X.', 'XX', 'X.'], colorIndex: 2, weight: 6),
    ShapeDef.fromPattern('t3', ['.X', 'XX', '.X'], colorIndex: 2, weight: 6),
    // Z and S
    ShapeDef.fromPattern('z0', ['XX.', '.XX'], colorIndex: 3, weight: 6),
    ShapeDef.fromPattern('z1', ['.X', 'XX', 'X.'], colorIndex: 3, weight: 6),
    ShapeDef.fromPattern('s0', ['.XX', 'XX.'], colorIndex: 5, weight: 6),
    ShapeDef.fromPattern('s1', ['X.', 'XX', '.X'], colorIndex: 5, weight: 6),
  ]);

  static ShapeDef byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => throw StateError(id));
}
