import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/shape.dart';

/// Pure placement rules. [row]/[col] always refer to the shape's top-left.
abstract final class Placement {
  static const int _size = GameConstants.gridSize;

  static bool canPlace(BoardState board, ShapeDef shape, int row, int col) {
    final rs = shape.rowOffsets;
    final cs = shape.colOffsets;
    for (var i = 0; i < rs.length; i++) {
      final r = row + rs[i];
      final c = col + cs[i];
      if (r < 0 || c < 0 || r >= _size || c >= _size) return false;
      if (board.isFilled(r, c)) return false;
    }
    return true;
  }

  /// Returns a new board with [shape] placed. Caller must validate first.
  static BoardState place(
    BoardState board,
    ShapeDef shape,
    int row,
    int col,
    int cellValue,
  ) {
    final indices = <int>[];
    for (var i = 0; i < shape.cellCount; i++) {
      indices.add(
        BoardState.indexOf(
          row + shape.rowOffsets[i],
          col + shape.colOffsets[i],
        ),
      );
    }
    return board.withCells(indices, cellValue);
  }

  static bool anyFit(BoardState board, ShapeDef shape) {
    for (var r = 0; r <= _size - shape.rows; r++) {
      for (var c = 0; c <= _size - shape.cols; c++) {
        if (canPlace(board, shape, r, c)) return true;
      }
    }
    return false;
  }

  /// Game is over when the tray still holds shapes but none can be placed.
  /// An empty tray is not game over: a refill is pending.
  static bool isGameOver(BoardState board, List<ShapeDef?> tray) {
    var hasShape = false;
    for (final s in tray) {
      if (s == null) continue;
      hasShape = true;
      if (anyFit(board, s)) return false;
    }
    return hasShape;
  }

  /// Finds the valid origin nearest to ([row], [col]) within the snap radius,
  /// or null. Ties favour the exact cell, then the earliest scan position.
  static (int, int)? snap(
    BoardState board,
    ShapeDef shape,
    int row,
    int col, {
    int radius = GameConstants.snapRadius,
  }) {
    if (canPlace(board, shape, row, col)) return (row, col);
    (int, int)? best;
    var bestDist = 1 << 30;
    for (var dr = -radius; dr <= radius; dr++) {
      for (var dc = -radius; dc <= radius; dc++) {
        final r = row + dr;
        final c = col + dc;
        final dist = dr * dr + dc * dc;
        if (dist >= bestDist || !canPlace(board, shape, r, c)) continue;
        best = (r, c);
        bestDist = dist;
      }
    }
    return best;
  }
}
