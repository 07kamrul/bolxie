import 'package:bloxie/core/constants/game_constants.dart';
import 'package:flutter/foundation.dart';

/// Immutable 8x8 board. Each cell holds 0 (empty), colorIndex + 1, or
/// [blockerValue] for stone cells that only go away when their line clears.
@immutable
class BoardState {
  BoardState._(this._cells);

  /// Reserved cell value for blocker (stone) cells. Higher than any
  /// colorIndex + 1 in every skin palette.
  static const int blockerValue = 99;

  factory BoardState.empty() =>
      BoardState._(List<int>.filled(GameConstants.cellCount, 0));

  /// Builds a board from rows of '.' (empty) and any other char (filled).
  /// Handy for tests and for debugging.
  factory BoardState.fromRows(List<String> rows) {
    final cells = List<int>.filled(GameConstants.cellCount, 0);
    for (var r = 0; r < rows.length; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        if (rows[r][c] != '.') cells[r * GameConstants.gridSize + c] = 1;
      }
    }
    return BoardState._(cells);
  }

  final List<int> _cells;

  static int indexOf(int row, int col) => row * GameConstants.gridSize + col;

  int at(int row, int col) => _cells[indexOf(row, col)];

  bool isFilled(int row, int col) => _cells[indexOf(row, col)] != 0;

  int get filledCount {
    var n = 0;
    for (final v in _cells) {
      if (v != 0) n++;
    }
    return n;
  }

  bool get isEmpty => filledCount == 0;

  int get blockerCount {
    var n = 0;
    for (final v in _cells) {
      if (v == blockerValue) n++;
    }
    return n;
  }

  /// Color index (0-based) of a filled non-blocker cell.
  static int colorIndexOf(int cellValue) => cellValue - 1;

  /// Returns a new board with the given cells set to [value].
  BoardState withCells(Iterable<int> indices, int value) {
    final next = List<int>.of(_cells);
    for (final i in indices) {
      next[i] = value;
    }
    return BoardState._(next);
  }

  @override
  bool operator ==(Object other) =>
      other is BoardState && listEquals(_cells, other._cells);

  @override
  int get hashCode => Object.hashAll(_cells);
}
