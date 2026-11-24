import 'package:bloxie/core/constants/ad_config.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';

/// Web replacement for rewarded ads on itch.io, where AdMob cannot run.
///
/// Players bought the game, so rewarded actions (undo, revive, free coins)
/// are free. Each placement has its own cooldown, saved through
/// [PrefsRepository] so reloading the page does not reset it.
class FreeRewardAdService implements AdService {
  FreeRewardAdService({
    required PrefsRepository prefs,
    DateTime Function()? now,
  }) : _prefs = prefs,
       _now = now ?? DateTime.now;

  final PrefsRepository _prefs;
  final DateTime Function() _now;

  @override
  Future<void> init() async {}

  @override
  bool get isRewardedReady => true;

  @override
  Duration cooldownRemaining(String placement) {
    final lastMs = _prefs.freeRewardLastGrantMs(placement);
    if (lastMs == null) return Duration.zero;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs, isUtc: true);
    final elapsed = _now().toUtc().difference(last);
    // A clock moved backwards counts as "just granted" rather than free.
    if (elapsed.isNegative) return AdConfig.freeRewardCooldownFor(placement);
    final remaining = AdConfig.freeRewardCooldownFor(placement) - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Future<bool> showRewarded(String placement) async {
    if (cooldownRemaining(placement) > Duration.zero) return false;
    await _prefs.setFreeRewardLastGrantMs(
      placement,
      _now().toUtc().millisecondsSinceEpoch,
    );
    return true;
  }

  @override
  void recordGameOver() {}

  @override
  Future<void> maybeShowInterstitial() async {}
}
