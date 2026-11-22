import 'dart:io' show Platform;

/// All ad unit IDs live here. These are Google's public TEST IDs.
/// Replace with real IDs (and the manifest/Info.plist app IDs) before release.
abstract final class AdConfig {
  static String get rewardedUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/1712485313'
      : 'ca-app-pub-3940256099942544/5224354917';

  static String get interstitialUnitId => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/4411468910'
      : 'ca-app-pub-3940256099942544/1033173712';

  /// Show an interstitial after every Nth game over (random in [min, max]).
  static const int interstitialMinGameOvers = 3;
  static const int interstitialMaxGameOvers = 4;
  static const Duration interstitialCooldown = Duration(seconds: 120);

  static const Duration retryBaseDelay = Duration(seconds: 5);
  static const int maxRetryDoublings = 5;
}
