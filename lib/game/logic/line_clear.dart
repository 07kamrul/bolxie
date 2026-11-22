import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:flutter/foundation.dart';

@immutable
class LineClearResult {
  const LineClearResult({required this.rows, required this.cols});

  static const LineClearResult none = LineClearResult(rows: [], cols: []);

  final List<int> rows;
  final List<int> cols;

  int get lineCount => rows.length + cols.length;
  bool get isEmpty => lineCount == 0;

  /// Unique board indices covered by the cleared lines.
  List<int> get cellIndices {
    const n = GameConstants.gridSize;
    final seen = <int>{};
    for (final r in rows) {
      for (var c = 0; c < n; c++) {
        seen.add(BoardState.indexOf(r, c));
      }
    }
    for (final c in cols) {
      for (var r = 0; r < n; r++) {
        seen.add(BoardState.indexOf(r, c));
      }
    }
    return seen.toList()..sort();
  }
}

abstract final class LineClear {
  static const int _n = GameConstants.gridSize;

  /// Finds every full row and column (evaluated simultaneously).
  static LineClearResult find(BoardState board) {
    final rows = <int>[];
    final cols = <int>[];
    for (var r = 0; r < _n; r++) {
      var full = true;
      for (var c = 0; c < _n && full; c++) {
        full = board.isFilled(r, c);
      }
      if (full) rows.add(r);
    }
    for (var c = 0; c < _n; c++) {
      var full = true;
      for (var r = 0; r < _n && full; r++) {
        full = board.isFilled(r, c);
      }
      if (full) cols.add(c);
    }
    if (rows.isEmpty && cols.isEmpty) return LineClearResult.none;
    return LineClearResult(rows: rows, cols: cols);
  }

  static BoardState apply(BoardState board, LineClearResult result) =>
      result.isEmpty ? board : board.withCells(result.cellIndices, 0);
}
