import 'package:flutter/widgets.dart';

/// Single source of truth for responsive decisions in the Flutter layer.
abstract final class Breakpoints {
  static const double wideAspect = 1.15;
  static const double compactHeight = 560;
  static const double compactWidth = 360;

  static bool isWide(Size s) => s.height > 0 && s.width / s.height > wideAspect;
  static bool isCompactHeight(Size s) => s.height < compactHeight;
  static bool isCompactWidth(Size s) => s.width < compactWidth;
}
