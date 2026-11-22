/// Tunable gameplay constants. Keep magic numbers here.
abstract final class GameConstants {
  static const int gridSize = 8;
  static const int cellCount = gridSize * gridSize;
  static const int trayCapacity = 3;

  /// Max distance (in cells) a dropped shape may be snapped to a valid spot.
  static const int snapRadius = 1;

  /// Gap between the thumb and the dragged piece's bottom, in cell heights.
  static const double dragLiftCells = 0.9;

  /// Max attempts the spawner makes to find a fair tray before forcing one.
  static const int spawnRetries = 24;

  // Scoring
  static const int lineBonusBase = 10;
  static const int streakInterval = 5;
  static const int streakBonus = 50;
  static const int bigComboLines = 3;

  // Revive
  static const int reviveAreaSize = 3;

  // Effects
  static const double placeBounceSeconds = 0.18;
  static const double clearAnimSeconds = 0.38;
  static const double comboPopupSeconds = 0.9;
  static const double shakeSeconds = 0.35;
  static const int maxParticles = 160;
  static const int particlesPerCell = 3;
}
