import 'package:flutter/foundation.dart';

/// An immutable block shape. Rotation is intentionally not supported.
@immutable
class ShapeDef {
  ShapeDef._({
    required this.id,
    required this.rows,
    required this.cols,
    required this.rowOffsets,
    required this.colOffsets,
    required this.colorIndex,
    required this.weight,
  });

  /// Builds a shape from an ASCII pattern where `X` marks a filled cell.
  factory ShapeDef.fromPattern(
    String id,
    List<String> pattern, {
    required int colorIndex,
    int weight = 10,
  }) {
    assert(pattern.isNotEmpty, 'pattern must not be empty');
    final rowOffsets = <int>[];
    final colOffsets = <int>[];
    var maxCols = 0;
    for (var r = 0; r < pattern.length; r++) {
      final line = pattern[r];
      if (line.length > maxCols) maxCols = line.length;
      for (var c = 0; c < line.length; c++) {
        if (line[c] == 'X') {
          rowOffsets.add(r);
          colOffsets.add(c);
        }
      }
    }
    assert(rowOffsets.isNotEmpty, 'shape $id has no cells');
    return ShapeDef._(
      id: id,
      rows: pattern.length,
      cols: maxCols,
      rowOffsets: List.unmodifiable(rowOffsets),
      colOffsets: List.unmodifiable(colOffsets),
      colorIndex: colorIndex,
      weight: weight,
    );
  }

  final String id;
  final int rows;
  final int cols;
  final List<int> rowOffsets;
  final List<int> colOffsets;
  final int colorIndex;

  /// Relative spawn weight.
  final int weight;

  int get cellCount => rowOffsets.length;

  @override
  String toString() => 'ShapeDef($id)';
}
