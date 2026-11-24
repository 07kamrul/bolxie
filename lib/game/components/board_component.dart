import 'dart:typed_data';
import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:bloxie/core/theme/game_skin.dart';
import 'package:bloxie/game/components/block_painter.dart';
import 'package:bloxie/game/game_layout.dart';
import 'package:bloxie/game/logic/board_state.dart';
import 'package:bloxie/game/logic/shape.dart';
import 'package:flame/components.dart';

/// Renders the 8x8 grid, placed blocks, ghost preview and all per-cell
/// animations. Per-cell state lives in preallocated typed lists.
class BoardComponent extends Component {
  BoardComponent({
    required this.skin,
    required this.painter,
    required GameLayout layout,
    required BoardState Function() boardSource,
  }) : _layout = layout,
       _boardSource = boardSource,
       super(priority: 1);

  final GameSkin skin;
  BlockPainter painter;
  GameLayout _layout;
  final BoardState Function() _boardSource;

  static const int _n = GameConstants.cellCount;
  static const int _cols = GameConstants.gridSize;

  final Float32List _bounce = Float32List(_n); // 1 -> 0
  final Float32List _clearing = Float32List(_n); // 1 -> 0
  final Int8List _clearColor = Int8List(_n);

  late final Paint _panelPaint = Paint()..color = skin.boardColor;
  Picture? _gridPicture;
  bool _isAnimating = false;
  late final Paint _glowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4;
  RRect _panel = RRect.zero;
  double _glow = 0;

  ShapeDef? _ghostShape;
  int _ghostRow = 0;
  int _ghostCol = 0;

  void relayout(GameLayout layout, BlockPainter newPainter) {
    _layout = layout;
    painter = newPainter;
    final pad = layout.cell * 0.12;
    _panel = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        layout.boardLeft - pad,
        layout.boardTop - pad,
        layout.boardSize + pad * 2,
        layout.boardSize + pad * 2,
      ),
      Radius.circular(layout.cell * 0.35),
    );
    _rebuildGridPicture();
  }

  /// Panel and empty cells never change between relayouts, so they are
  /// recorded once and replayed as a single draw call.
  void _rebuildGridPicture() {
    _gridPicture?.dispose();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRRect(_panel, _panelPaint);
    for (var r = 0; r < _cols; r++) {
      for (var c = 0; c < _cols; c++) {
        painter.drawEmpty(canvas, _layout.cellX(c), _layout.cellY(r));
      }
    }
    _gridPicture = recorder.endRecording();
  }

  @override
  void onRemove() {
    _gridPicture?.dispose();
    _gridPicture = null;
    super.onRemove();
  }

  void setGhost(ShapeDef? shape, int row, int col) {
    _ghostShape = shape;
    _ghostRow = row;
    _ghostCol = col;
  }

  void onPlaced(ShapeDef shape, int row, int col) {
    for (var i = 0; i < shape.cellCount; i++) {
      _bounce[BoardState.indexOf(
            row + shape.rowOffsets[i],
            col + shape.colOffsets[i],
          )] =
          1;
    }
    _glow = 1;
    _isAnimating = true;
  }

  void onCleared(List<int> indices, List<int> colorValues) {
    for (var k = 0; k < indices.length; k++) {
      final i = indices[k];
      _clearing[i] = 1;
      _clearColor[i] = (colorValues[k] - 1).clamp(0, 127);
      _bounce[i] = 0;
    }
    _isAnimating = true;
  }

  void resetAnimations() {
    _bounce.fillRange(0, _n, 0);
    _clearing.fillRange(0, _n, 0);
    _glow = 0;
    _isAnimating = false;
    _ghostShape = null;
  }

  @override
  void update(double dt) {
    if (!_isAnimating) return;
    final bounceStep = dt / GameConstants.placeBounceSeconds;
    final clearStep = dt / GameConstants.clearAnimSeconds;
    var any = _glow > 0;
    for (var i = 0; i < _n; i++) {
      if (_bounce[i] > 0) {
        _bounce[i] = (_bounce[i] - bounceStep).clamp(0.0, 1.0);
        any = any || _bounce[i] > 0;
      }
      if (_clearing[i] > 0) {
        _clearing[i] = (_clearing[i] - clearStep).clamp(0.0, 1.0);
        any = any || _clearing[i] > 0;
      }
    }
    if (_glow > 0) {
      _glow = (_glow - dt * 2.5).clamp(0.0, 1.0);
      any = any || _glow > 0;
    }
    _isAnimating = any;
  }

  @override
  void render(Canvas canvas) {
    final l = _layout;
    final grid = _gridPicture;
    if (grid != null) canvas.drawPicture(grid);
    if (_glow > 0) {
      _glowPaint.color = skin.accent.withValues(alpha: 0.7 * _glow);
      canvas.drawRRect(_panel, _glowPaint);
    }
    final board = _boardSource();
    for (var r = 0; r < _cols; r++) {
      for (var c = 0; c < _cols; c++) {
        final x = l.cellX(c);
        final y = l.cellY(r);
        final i = r * _cols + c;
        final value = board.at(r, c);
        if (value != 0) {
          final b = _bounce[i];
          // sin gives a quick overshoot-and-settle pop.
          final scale = b > 0 ? 1 + 0.18 * _sinPop(b) : 1.0;
          painter.drawCell(canvas, x, y, value - 1, scale: scale);
        }
      }
    }
    _renderClearing(canvas, l);
    _renderGhost(canvas, l);
  }

  static double _sinPop(double t) {
    // t in (0,1]; peaks mid-animation, returns to 0 at both ends.
    final p = 1 - t;
    return 4 * p * (1 - p);
  }

  void _renderClearing(Canvas canvas, GameLayout l) {
    for (var i = 0; i < _n; i++) {
      final t = _clearing[i];
      if (t <= 0) continue;
      final p = 1 - t;
      final x = l.cellX(i % _cols);
      final y = l.cellY(i ~/ _cols);
      final scale = p < 0.25
          ? 1 + 0.12 * (p / 0.25)
          : 1.12 * (1 - (p - 0.25) / 0.75);
      painter.drawCell(canvas, x, y, _clearColor[i], scale: scale);
      final flash = (1 - p / 0.45).clamp(0.0, 1.0);
      if (flash > 0) {
        painter.drawFlash(
          canvas,
          x,
          y,
          scale,
          Color.fromRGBO(255, 255, 255, 0.85 * flash),
        );
      }
    }
  }

  void _renderGhost(Canvas canvas, GameLayout l) {
    final shape = _ghostShape;
    if (shape == null) return;
    for (var i = 0; i < shape.cellCount; i++) {
      painter.drawGhost(
        canvas,
        l.cellX(_ghostCol + shape.colOffsets[i]),
        l.cellY(_ghostRow + shape.rowOffsets[i]),
      );
    }
  }
}
