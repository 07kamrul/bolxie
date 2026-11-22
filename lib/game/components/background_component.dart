import 'dart:ui';

import 'package:bloxie/core/theme/game_skin.dart';
import 'package:flame/components.dart';

class BackgroundComponent extends Component {
  BackgroundComponent(this.skin) : super(priority: 0);

  final GameSkin skin;
  final Paint _paint = Paint();
  Rect _rect = Rect.zero;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _paint.shader = Gradient.linear(_rect.topCenter, _rect.bottomCenter, [
      skin.bgTop,
      skin.bgBottom,
    ]);
  }

  @override
  void render(Canvas canvas) => canvas.drawRect(_rect, _paint);
}
