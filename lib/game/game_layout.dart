import 'dart:math';
import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';

/// Pure layout maths for the play area. All values are in canvas px.
///
/// Portrait areas stack the board above a horizontal tray. Wide areas
/// (landscape phones, tablets, desktop windows) put the board on the left and
/// a vertical tray on the right.
class GameLayout {
  GameLayout(this.width, this.height) {
    isWide = height > 0 && width / height > wideAspect;
    final shortSide = min(width, height);
    final margin = max(8.0, shortSide * 0.04);
    final gap = max(8.0, shortSide * 0.025);
    this.margin = margin;
    this.gap = gap;

    if (isWide) {
      _layoutWide(margin, gap);
    } else {
      _layoutPortrait(margin, gap);
    }
    cell = boardSize / GameConstants.gridSize;
    trayCell = _computeTrayCell();
    unit = cell / 40;
  }

  /// Width / height above which the side-by-side layout is used.
  static const double wideAspect = 1.15;
  static const double maxBoardSize = 640;
  static const double maxTrayExtent = 720;
  static const double minHitExtent = 48;

  final double width;
  final double height;
  late final bool isWide;
  late final double margin;
  late final double gap;
  late final double boardSize;
  late final double cell;
  late final double boardLeft;
  late final double boardTop;
  late final double trayLeft;
  late final double trayTop;
  late final double trayWidth;
  late final double trayHeight;
  late final double trayCell;

  /// Scale factor for effects, where 1.0 equals a 40px cell.
  late final double unit;

  void _layoutPortrait(double margin, double gap) {
    final byWidth = width - margin * 2;
    final byHeight = (height - gap * 2) * 0.66;
    boardSize = max(0, min(min(byWidth, byHeight), maxBoardSize));
    boardLeft = (width - boardSize) / 2;
    boardTop = gap;
    trayTop = boardTop + boardSize + gap;
    trayHeight = max(0, height - trayTop - gap);
    trayWidth = min(width, max(boardSize, maxTrayExtent));
    trayLeft = (width - trayWidth) / 2;
  }

  void _layoutWide(double margin, double gap) {
    final byHeight = height - gap * 2;
    final byWidth = (width - margin * 3) * 0.64;
    boardSize = max(0, min(min(byHeight, byWidth), maxBoardSize));
    final trayExtent = min(
      max(0.0, width - margin * 3 - boardSize),
      boardSize * 0.7,
    );
    final totalWidth = boardSize + margin + trayExtent;
    boardLeft = (width - totalWidth) / 2;
    boardTop = (height - boardSize) / 2;
    trayLeft = boardLeft + boardSize + margin;
    trayWidth = trayExtent;
    trayTop = boardTop;
    trayHeight = boardSize;
  }

  double _computeTrayCell() {
    final slotW = isWide ? trayWidth : trayWidth / GameConstants.trayCapacity;
    final slotH = isWide ? trayHeight / GameConstants.trayCapacity : trayHeight;
    final fit = min(slotW, slotH) / 5.5;
    return min(cell * 0.62, fit);
  }

  double get boardCenterX => boardLeft + boardSize / 2;
  double get boardCenterY => boardTop + boardSize / 2;

  double get slotWidth =>
      isWide ? trayWidth : trayWidth / GameConstants.trayCapacity;
  double get slotHeight =>
      isWide ? trayHeight / GameConstants.trayCapacity : trayHeight;

  Rect slotRect(int slot) => isWide
      ? Rect.fromLTWH(
          trayLeft,
          trayTop + slot * slotHeight,
          slotWidth,
          slotHeight,
        )
      : Rect.fromLTWH(
          trayLeft + slot * slotWidth,
          trayTop,
          slotWidth,
          slotHeight,
        );

  /// Slot rect grown so the touch target is at least [minHitExtent] and has
  /// [pad] extra around it.
  Rect slotHitRect(int slot, double pad) {
    final r = slotRect(slot).inflate(pad);
    final dw = max(0.0, minHitExtent - r.width) / 2;
    final dh = max(0.0, minHitExtent - r.height) / 2;
    return r.inflate(max(dw, dh));
  }

  double slotCenterX(int slot) => slotRect(slot).center.dx;
  double slotCenterY(int slot) => slotRect(slot).center.dy;

  /// Scale of a resting tray piece relative to a board cell.
  double get trayScale => cell == 0 ? 0 : trayCell / cell;

  double cellX(int col) => boardLeft + col * cell;
  double cellY(int row) => boardTop + row * cell;
}
