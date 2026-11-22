import 'dart:math';

import 'package:bloxie/core/constants/ad_config.dart';

/// Pure scheduling rules for interstitials: every 3-4 game overs, with a
/// cooldown, never when ads are removed. Contains no ad SDK code.
class InterstitialPolicy {
  InterstitialPolicy({
    Random? random,
    this.minGameOvers = AdConfig.interstitialMinGameOvers,
    this.maxGameOvers = AdConfig.interstitialMaxGameOvers,
    this.cooldown = AdConfig.interstitialCooldown,
  }) : _random = random ?? Random() {
    _target = _roll();
  }

  final int minGameOvers;
  final int maxGameOvers;
  final Duration cooldown;
  final Random _random;

  late int _target;
  int _gameOversSinceShown = 0;
  DateTime? _lastShown;

  /// Game overs required before the next interstitial. Exposed for tests.
  int get target => _target;

  int _roll() =>
      minGameOvers + _random.nextInt(maxGameOvers - minGameOvers + 1);

  void recordGameOver() => _gameOversSinceShown++;

  bool shouldShow({required bool adsRemoved, required DateTime now}) {
    if (adsRemoved || _gameOversSinceShown < _target) return false;
    final last = _lastShown;
    return last == null || now.difference(last) >= cooldown;
  }

  void markShown(DateTime now) {
    _lastShown = now;
    _gameOversSinceShown = 0;
    _target = _roll();
  }
}
