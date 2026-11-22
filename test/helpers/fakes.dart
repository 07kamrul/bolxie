import 'package:bloxie/game/logic/shape.dart';

ShapeDef shape(String id, List<String> pattern) =>
    ShapeDef.fromPattern(id, pattern, colorIndex: 0);

final ShapeDef single = shape('single', ['X']);
final ShapeDef h2 = shape('h2', ['XX']);
final ShapeDef h3 = shape('h3', ['XXX']);
final ShapeDef v3 = shape('v3', ['X', 'X', 'X']);
final ShapeDef sq2 = shape('sq2', ['XX', 'XX']);
final ShapeDef sq3 = shape('sq3', ['XXX', 'XXX', 'XXX']);
final ShapeDef lShape = shape('l', ['X.', 'X.', 'XX']);
