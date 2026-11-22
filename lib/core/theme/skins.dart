import 'dart:ui';

import 'package:bloxie/core/theme/game_skin.dart';

abstract final class Skins {
  static const String defaultId = 'neon';

  static const GameSkin neon = GameSkin(
    id: 'neon',
    name: 'Neon Night',
    price: 0,
    bgTop: Color(0xFF1B1446),
    bgBottom: Color(0xFF0A0A1F),
    boardColor: Color(0xFF141233),
    cellEmpty: Color(0xFF211D4B),
    accent: Color(0xFF7C5CFF),
    palette: [
      Color(0xFFFF5C8A),
      Color(0xFFFFB84D),
      Color(0xFF4DE0A8),
      Color(0xFF4DB8FF),
      Color(0xFFB36BFF),
      Color(0xFFFF7A59),
      Color(0xFF5CE1E6),
    ],
  );

  static const GameSkin sunset = GameSkin(
    id: 'sunset',
    name: 'Sunset',
    price: 500,
    bgTop: Color(0xFF4A1D3F),
    bgBottom: Color(0xFF1F0A1A),
    boardColor: Color(0xFF2E1128),
    cellEmpty: Color(0xFF42193A),
    accent: Color(0xFFFF8A5C),
    palette: [
      Color(0xFFFF6B6B),
      Color(0xFFFFA94D),
      Color(0xFFFFD43B),
      Color(0xFFF783AC),
      Color(0xFFE599F7),
      Color(0xFFFF8787),
      Color(0xFFFFC078),
    ],
  );

  static const GameSkin ocean = GameSkin(
    id: 'ocean',
    name: 'Deep Ocean',
    price: 1000,
    bgTop: Color(0xFF0B3954),
    bgBottom: Color(0xFF041A2B),
    boardColor: Color(0xFF082B42),
    cellEmpty: Color(0xFF0E3F5E),
    accent: Color(0xFF3DD6D0),
    palette: [
      Color(0xFF3DD6D0),
      Color(0xFF4DABF7),
      Color(0xFF74C0FC),
      Color(0xFF38D9A9),
      Color(0xFF66D9E8),
      Color(0xFF91A7FF),
      Color(0xFFA5D8FF),
    ],
  );

  static const GameSkin forest = GameSkin(
    id: 'forest',
    name: 'Forest',
    price: 2000,
    bgTop: Color(0xFF1B4332),
    bgBottom: Color(0xFF081C15),
    boardColor: Color(0xFF12301F),
    cellEmpty: Color(0xFF1D4A33),
    accent: Color(0xFF95D5B2),
    palette: [
      Color(0xFF95D5B2),
      Color(0xFFD8F3DC),
      Color(0xFFB7E4C7),
      Color(0xFFFFD166),
      Color(0xFFEF8354),
      Color(0xFF74C69D),
      Color(0xFFC9E265),
    ],
  );

  static const GameSkin candy = GameSkin(
    id: 'candy',
    name: 'Candy Pop',
    price: 3500,
    bgTop: Color(0xFF5B2A86),
    bgBottom: Color(0xFF24103F),
    boardColor: Color(0xFF341A56),
    cellEmpty: Color(0xFF4A2677),
    accent: Color(0xFFFF9EF5),
    palette: [
      Color(0xFFFF9EF5),
      Color(0xFF9EFFF5),
      Color(0xFFFFF59E),
      Color(0xFFFF9E9E),
      Color(0xFF9EB5FF),
      Color(0xFFB9FF9E),
      Color(0xFFFFC89E),
    ],
  );

  static const List<GameSkin> all = [neon, sunset, ocean, forest, candy];

  static GameSkin byId(String id) =>
      all.firstWhere((s) => s.id == id, orElse: () => neon);
}
