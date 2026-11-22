import 'dart:math';

import 'package:bloxie/core/constants/game_constants.dart';

/// Pure layout maths for a portrait play area. All values are in canvas px.
class GameLayout {
  GameLayout(double width, double height) : width = width, height = height {
    const margin = 16.0;
    const gap = 12.0;
    final byWidth = width - margin * 2;
    final byHeight = (height - gap * 2) * 0.66;
    boardSize = max(0, min(byWidth, byHeight));
    cell = boardSize / GameConstants.gridSize;
    boardLeft = (width - boardSize) / 2;
    boardTop = gap;
    trayTop = boardTop + boardSize + gap;
    trayHeight = max(0, height - trayTop - gap);
    slotWidth = width / GameConstants.trayCapacity;
    trayCell = min(cell * 0.62, slotWidth / 5.5);
  }

  final double width;
  final double height;
  late final double boardSize;
  late final double cell;
  late final double boardLeft;
  late final double boardTop;
  late final double trayTop;
  late final double trayHeight;
  late final double slotWidth;
  late final double trayCell;

  double get boardCenterX => boardLeft + boardSize / 2;
  double get boardCenterY => boardTop + boardSize / 2;
  double slotCenterX(int slot) => slotWidth * (slot + 0.5);
  double get slotCenterY => trayTop + trayHeight / 2;

  /// Scale of a resting tray piece relative to a board cell.
  double get trayScale => cell == 0 ? 0 : trayCell / cell;

  double cellX(int col) => boardLeft + col * cell;
  double cellY(int row) => boardTop + row * cell;
}
