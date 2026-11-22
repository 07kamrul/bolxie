import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/shape.dart';

/// Revive power-up: clears a 3x3 area chosen to give the player a way out.
abstract final class Revive {
  static const int _size = GameConstants.reviveAreaSize;
  static const int _maxOrigin = GameConstants.gridSize - _size;

  static List<int> _areaIndices(int row, int col) => [
    for (var r = row; r < row + _size; r++)
      for (var c = col; c < col + _size; c++) BoardState.indexOf(r, c),
  ];

  static BoardState apply(BoardState board, int row, int col) =>
      board.withCells(_areaIndices(row, col), 0);

  static int _filledIn(BoardState board, int row, int col) {
    var n = 0;
    for (final i in _areaIndices(row, col)) {
      if (board.at(i ~/ GameConstants.gridSize, i % GameConstants.gridSize) !=
          0) {
        n++;
      }
    }
    return n;
  }

  /// Picks the top-left of the best 3x3 area: areas that let at least one
  /// remaining shape fit win; ties and the no-fit case go to the densest area.
  static (int, int) findArea(BoardState board, List<ShapeDef?> tray) {
    var best = (0, 0);
    var bestScore = -1;
    for (var r = 0; r <= _maxOrigin; r++) {
      for (var c = 0; c <= _maxOrigin; c++) {
        final filled = _filledIn(board, r, c);
        final after = apply(board, r, c);
        final helps = tray.any((s) => s != null && Placement.anyFit(after, s));
        final score = (helps ? 100 : 0) + filled;
        if (score > bestScore) {
          bestScore = score;
          best = (r, c);
        }
      }
    }
    return best;
  }
}
