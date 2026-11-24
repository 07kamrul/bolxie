import 'package:bloxie/core/platform/platform_info.dart';

/// All ad unit IDs live here. These are Google's public TEST IDs.
/// Replace with real IDs (and the manifest/Info.plist app IDs) before release.
abstract final class AdConfig {
  static String get rewardedUnitId => PlatformInfo.isIOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';

  static String get interstitialUnitId => PlatformInfo.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  /// Show an interstitial after every Nth game over (random in [min, max]).
  static const int interstitialMinGameOvers = 3;
  static const int interstitialMaxGameOvers = 4;
  static const Duration interstitialCooldown = Duration(seconds: 120);

  static const Duration retryBaseDelay = Duration(seconds: 5);
  static const int maxRetryDoublings = 5;

  /// Web build (itch.io): rewarded actions are free, each gated by its own
  /// cooldown so using one never blocks another. Keys are AdPlacement values.
  static const Map<String, Duration> freeRewardCooldowns = {
    'undo': Duration(seconds: 30),
    'revive': Duration(minutes: 2),
    'free_coins': Duration(minutes: 5),
  };

  /// Fallback for a placement missing from [freeRewardCooldowns].
  static const Duration freeRewardDefaultCooldown = Duration(minutes: 5);

  static Duration freeRewardCooldownFor(String placement) =>
      freeRewardCooldowns[placement] ?? freeRewardDefaultCooldown;
}
