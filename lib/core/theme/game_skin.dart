import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A purchasable look: background gradient, block palette and accents.
class GameSkin extends Equatable {
  const GameSkin({
    required this.id,
    required this.name,
    required this.price,
    required this.bgTop,
    required this.bgBottom,
    required this.boardColor,
    required this.cellEmpty,
    required this.accent,
    required this.palette,
  });

  final String id;
  final String name;
  final int price;
  final Color bgTop;
  final Color bgBottom;
  final Color boardColor;
  final Color cellEmpty;
  final Color accent;

  /// 7 block colors, indexed by `ShapeDef.colorIndex`.
  final List<Color> palette;

  @override
  List<Object?> get props => [id];
}
