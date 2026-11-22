import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/game/block_game.dart';
import 'package:bloxie/game/logic/placement.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// One of the three pieces in the tray. It spans the whole play area so it
/// can draw in canvas coordinates, but only its slot is hit-testable.
class TrayPiece extends PositionComponent
    with DragCallbacks, HasGameReference<BlockGame> {
  TrayPiece(this.slot) : super(priority: 3);

  final int slot;

  static const double _followRate = 28;
  static const double _scaleRate = 18;
  static const double _hitPadding = 18;

  ShapeDef? _shape;
  double _cx = 0;
  double _cy = 0;
  double _scale = 0;

  bool _dragging = false;
  double _fingerX = 0;
  double _fingerY = 0;
  int _snapRow = -1;
  int _snapCol = -1;
  bool _hasSnap = false;

  ShapeDef? get _current => game.session.state.tray[slot];

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    position = Vector2.zero();
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    if (_current == null || !game.isInteractive) return false;
    final l = game.layout;
    final left = slot * l.slotWidth;
    return point.x >= left &&
        point.x <= left + l.slotWidth &&
        point.y >= l.trayTop - _hitPadding &&
        point.y <= l.trayTop + l.trayHeight + _hitPadding;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_current == null || !game.isInteractive) return;
    _dragging = true;
    _fingerX = event.canvasPosition.x;
    _fingerY = event.canvasPosition.y;
    _updateSnap();
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (!_dragging) return;
    _fingerX = event.canvasEndPosition.x;
    _fingerY = event.canvasEndPosition.y;
    _updateSnap();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _finishDrag();
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    _dragging = false;
    _clearSnap();
  }

  void _finishDrag() {
    if (!_dragging) return;
    _dragging = false;
    final row = _snapRow;
    final col = _snapCol;
    final valid = _hasSnap;
    _clearSnap();
    if (valid) game.placeFromTray(slot, row, col);
  }

  void _clearSnap() {
    _hasSnap = false;
    game.setGhost(null, 0, 0);
  }

  double get _targetCenterX => _fingerX;
  double _targetCenterY(ShapeDef s) {
    final l = game.layout;
    return _fingerY -
        GameConstants.dragLiftCells * l.cell -
        s.rows * l.cell / 2;
  }

  void _updateSnap() {
    final shape = _current;
    if (shape == null) return;
    final l = game.layout;
    final originX = _targetCenterX - shape.cols * l.cell / 2;
    final originY = _targetCenterY(shape) - shape.rows * l.cell / 2;
    final col = ((originX - l.boardLeft) / l.cell).round();
    final row = ((originY - l.boardTop) / l.cell).round();
    final spot = Placement.snap(game.session.state.board, shape, row, col);
    if (spot == null) {
      if (_hasSnap) _clearSnap();
      return;
    }
    if (_hasSnap && spot.$1 == _snapRow && spot.$2 == _snapCol) return;
    _hasSnap = true;
    _snapRow = spot.$1;
    _snapCol = spot.$2;
    game.setGhost(shape, spot.$1, spot.$2);
  }

  @override
  void update(double dt) {
    final shape = _current;
    if (shape == null) {
      _shape = null;
      _dragging = false;
      return;
    }
    final l = game.layout;
    if (!identical(shape, _shape)) {
      // New piece dealt (or restored by undo): pop in at the slot.
      _shape = shape;
      _cx = l.slotCenterX(slot);
      _cy = l.slotCenterY;
      _scale = 0;
      _dragging = false;
    }
    final targetX = _dragging ? _targetCenterX : l.slotCenterX(slot);
    final targetY = _dragging ? _targetCenterY(shape) : l.slotCenterY;
    final targetScale = _dragging ? 1.0 : l.trayScale;
    final follow = (dt * _followRate).clamp(0.0, 1.0);
    final grow = (dt * _scaleRate).clamp(0.0, 1.0);
    _cx += (targetX - _cx) * follow;
    _cy += (targetY - _cy) * follow;
    _scale += (targetScale - _scale) * grow;
  }

  @override
  void render(Canvas canvas) {
    final shape = _current;
    if (shape == null || _scale <= 0.01) return;
    game.painter.drawShape(canvas, shape, _cx, _cy, _scale);
  }
}
