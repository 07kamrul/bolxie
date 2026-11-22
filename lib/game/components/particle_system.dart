import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bloxie/core/constants/game_constants.dart';
import 'package:flame/components.dart';

/// Fixed-capacity particle pool; no allocation while updating.
class ParticleSystem extends Component {
  ParticleSystem({required List<Color> palette, Random? random})
    : _palette = palette,
      _random = random ?? Random(),
      super(priority: 2);

  static const int _stride = 7; // x, y, vx, vy, life, maxLife, colorIndex
  static const double _gravity = 520;
  static const int _alphaBuckets = 4;

  final List<Color> _palette;
  final Random _random;
  final Float32List _data = Float32List(GameConstants.maxParticles * _stride);
  final Paint _paint = Paint();
  late final List<List<Color>> _bucketColors = [
    for (final c in _palette)
      [
        for (var b = 0; b < _alphaBuckets; b++)
          c.withValues(alpha: (b + 1) / _alphaBuckets),
      ],
  ];
  int _next = 0;
  int _alive = 0;

  void burst(double x, double y, int colorIndex, {int count = 3}) {
    for (var n = 0; n < count; n++) {
      final base = _next * _stride;
      final angle = _random.nextDouble() * pi * 2;
      final speed = 90 + _random.nextDouble() * 220;
      final life = 0.35 + _random.nextDouble() * 0.35;
      _data[base] = x;
      _data[base + 1] = y;
      _data[base + 2] = cos(angle) * speed;
      _data[base + 3] = sin(angle) * speed - 80;
      _data[base + 4] = life;
      _data[base + 5] = life;
      _data[base + 6] = colorIndex.toDouble();
      _next = (_next + 1) % GameConstants.maxParticles;
      if (_alive < GameConstants.maxParticles) _alive++;
    }
  }

  @override
  void update(double dt) {
    if (_alive == 0) return;
    var any = false;
    for (var i = 0; i < GameConstants.maxParticles; i++) {
      final b = i * _stride;
      final life = _data[b + 4];
      if (life <= 0) continue;
      _data[b + 4] = life - dt;
      _data[b + 3] += _gravity * dt;
      _data[b] += _data[b + 2] * dt;
      _data[b + 1] += _data[b + 3] * dt;
      any = true;
    }
    if (!any) _alive = 0;
  }

  @override
  void render(Canvas canvas) {
    if (_alive == 0) return;
    for (var i = 0; i < GameConstants.maxParticles; i++) {
      final b = i * _stride;
      final life = _data[b + 4];
      if (life <= 0) continue;
      final t = life / _data[b + 5];
      final bucket = (t * _alphaBuckets).ceil().clamp(1, _alphaBuckets) - 1;
      final colors = _bucketColors[_data[b + 6].toInt() % _bucketColors.length];
      _paint.color = colors[bucket];
      canvas.drawCircle(Offset(_data[b], _data[b + 1]), 2 + 4 * t, _paint);
    }
  }
}
