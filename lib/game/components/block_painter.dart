import 'dart:ui';

import 'package:bloxie/core/theme/game_skin.dart';
import 'package:bloxie/game/logic/shape.dart';

/// Draws rounded blocks without allocating per call. Positions are applied
/// with canvas transforms against prototype rounded rects built once.
class BlockPainter {
  BlockPainter({required this.cell, required GameSkin skin}) {
    final pad = cell * 0.06;
    final size = cell - pad * 2;
    final radius = Radius.circular(size * 0.24);
    _rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(pad, pad, size, size),
      radius,
    );
    _highlight = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pad + size * 0.1,
        pad + size * 0.08,
        size * 0.8,
        size * 0.34,
      ),
      Radius.circular(size * 0.16),
    );
    _fills = [for (final c in skin.palette) Paint()..color = c];
    _emptyPaint = Paint()..color = skin.cellEmpty;
    _highlightPaint = Paint()..color = const Color(0x33FFFFFF);
    _ghostPaint = Paint()..color = skin.accent.withValues(alpha: 0.38);
    _overlay = Paint();
  }

  final double cell;
  late final RRect _rrect;
  late final RRect _highlight;
  late final List<Paint> _fills;
  late final Paint _emptyPaint;
  late final Paint _highlightPaint;
  late final Paint _ghostPaint;
  late final Paint _overlay;

  void _enter(Canvas canvas, double x, double y, double scale) {
    canvas.save();
    canvas.translate(x + cell / 2, y + cell / 2);
    if (scale != 1) canvas.scale(scale);
    canvas.translate(-cell / 2, -cell / 2);
  }

  void drawEmpty(Canvas canvas, double x, double y) {
    _enter(canvas, x, y, 1);
    canvas.drawRRect(_rrect, _emptyPaint);
    canvas.restore();
  }

  void drawBlock(
    Canvas canvas,
    double x,
    double y,
    int colorIndex, {
    double scale = 1,
  }) {
    _enter(canvas, x, y, scale);
    canvas.drawRRect(_rrect, _fills[colorIndex % _fills.length]);
    canvas.drawRRect(_highlight, _highlightPaint);
    canvas.restore();
  }

  void drawGhost(Canvas canvas, double x, double y) {
    _enter(canvas, x, y, 1);
    canvas.drawRRect(_rrect, _ghostPaint);
    canvas.restore();
  }

  /// Solid [color] overlay on a block (used for the clear flash).
  void drawFlash(Canvas canvas, double x, double y, double scale, Color color) {
    _enter(canvas, x, y, scale);
    _overlay.color = color;
    canvas.drawRRect(_rrect, _overlay);
    canvas.restore();
  }

  /// Draws [shape] with its center at ([cx], [cy]); cell spacing is
  /// `cell * scale`.
  void drawShape(
    Canvas canvas,
    ShapeDef shape,
    double cx,
    double cy,
    double scale,
  ) {
    final step = cell * scale;
    final left = cx - shape.cols * step / 2;
    final top = cy - shape.rows * step / 2;
    for (var i = 0; i < shape.cellCount; i++) {
      drawBlock(
        canvas,
        left + shape.colOffsets[i] * step - (cell - step) / 2,
        top + shape.rowOffsets[i] * step - (cell - step) / 2,
        shape.colorIndex,
        scale: scale,
      );
    }
  }
}
