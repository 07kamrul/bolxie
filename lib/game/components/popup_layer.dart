import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class _Popup {
  TextPainter? painter;
  double age = 0;
  double x = 0;
  double y = 0;
  bool get isActive => painter != null;
}

/// Floating combo / score text. Painters are built on spawn (rare), then
/// only transformed while animating.
class PopupLayer extends Component {
  PopupLayer() : super(priority: 5);

  static const int _slots = 4;
  final List<_Popup> _popups = List.generate(_slots, (_) => _Popup());
  final Paint _layerPaint = Paint();
  int _next = 0;

  void show(
    String text,
    double x,
    double y, {
    Color color = const Color(0xFFFFFFFF),
    double size = 34,
  }) {
    final popup = _popups[_next];
    _next = (_next + 1) % _slots;
    popup.painter?.dispose();
    popup.painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 8, color: Color(0xAA000000))],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    popup
      ..age = 0
      ..x = x
      ..y = y;
  }

  @override
  void update(double dt) {
    for (final p in _popups) {
      if (!p.isActive) continue;
      p.age += dt;
      if (p.age >= GameConstants.comboPopupSeconds) {
        p.painter?.dispose();
        p.painter = null;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    for (final p in _popups) {
      final painter = p.painter;
      if (painter == null) continue;
      final t = p.age / GameConstants.comboPopupSeconds;
      final pop = t < 0.15 ? 0.6 + (t / 0.15) * 0.5 : 1.1 - (t - 0.15) * 0.12;
      final alpha = t < 0.6 ? 1.0 : (1 - (t - 0.6) / 0.4).clamp(0.0, 1.0);
      final rise = -60 * t;
      _layerPaint.color = Color.fromRGBO(255, 255, 255, alpha);
      canvas.saveLayer(null, _layerPaint);
      canvas.translate(p.x, p.y + rise);
      canvas.scale(pop);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }
}
