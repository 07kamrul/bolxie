import 'package:bloxie/core/platform/platform_info.dart';

/// Wording for rewarded actions. On web (itch.io) there are no ads, so the
/// labels must not mention them.
abstract final class RewardLabels {
  static String get revive => PlatformInfo.isWeb ? 'REVIVE' : 'REVIVE (AD)';

  static String get undoTooltip =>
      PlatformInfo.isWeb ? 'Undo' : 'Undo (watch ad)';

  /// Shown when a reward could not be granted.
  static String unavailable(Duration cooldown) => PlatformInfo.isWeb
      ? 'Available again in ${formatCooldown(cooldown)}.'
      : 'No ad available right now. Try again later.';

  /// "m:ss", e.g. 3:07.
  static String formatCooldown(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final seconds = (safe.inSeconds % 60).toString().padLeft(2, '0');
    return '${safe.inMinutes}:$seconds';
  }
}
