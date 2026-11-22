import 'dart:async';

import 'package:bloxie/core/constants/ad_config.dart';
import 'package:bloxie/services/ads/consent_service.dart';
import 'package:bloxie/services/ads/interstitial_policy.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Where a rewarded ad was offered; used for analytics.
abstract final class AdPlacement {
  static const revive = 'revive';
  static const undo = 'undo';
  static const coins = 'free_coins';
  static const gameOver = 'game_over';
}

abstract interface class AdService {
  Future<void> init();
  bool get isRewardedReady;

  /// Shows a rewarded ad. Resolves true only if the reward was earned.
  Future<bool> showRewarded(String placement);

  /// Call when a game ends so the interstitial schedule advances.
  void recordGameOver();

  /// Shows an interstitial if the policy allows. Call only from menus or the
  /// game-over flow, never during gameplay.
  Future<void> maybeShowInterstitial();
}

class AdMobAdService implements AdService {
  AdMobAdService({
    required AnalyticsService analytics,
    required bool Function() adsRemoved,
    ConsentService? consent,
    InterstitialPolicy? policy,
  }) : _analytics = analytics,
       _adsRemoved = adsRemoved,
       _consent = consent ?? ConsentService(),
       _policy = policy ?? InterstitialPolicy();

  final AnalyticsService _analytics;
  final bool Function() _adsRemoved;
  final ConsentService _consent;
  final InterstitialPolicy _policy;

  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  int _rewardedFailures = 0;
  int _interstitialFailures = 0;
  bool _initialised = false;

  @override
  bool get isRewardedReady => _rewarded != null;

  @override
  Future<void> init() async {
    try {
      final canRequest = await _consent.gather();
      if (!canRequest) return;
      await MobileAds.instance.initialize();
      _initialised = true;
      _loadRewarded();
      if (!_adsRemoved()) _loadInterstitial();
    } on Object catch (e) {
      debugPrint('ads init failed: $e');
    }
  }

  Duration _backoff(int failures) {
    final doublings = failures.clamp(0, AdConfig.maxRetryDoublings);
    return AdConfig.retryBaseDelay * (1 << doublings);
  }

  void _loadRewarded() {
    if (!_initialised || _rewarded != null) return;
    RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedFailures = 0;
          _rewarded = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('rewarded load: ${error.message}');
          Future<void>.delayed(_backoff(_rewardedFailures++), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!_initialised || _interstitial != null) return;
    InterstitialAd.load(
      adUnitId: AdConfig.interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialFailures = 0;
          _interstitial = ad;
        },
        onAdFailedToLoad: (error) {
          debugPrint('interstitial load: ${error.message}');
          Future<void>.delayed(
            _backoff(_interstitialFailures++),
            _loadInterstitial,
          );
        },
      ),
    );
  }

  @override
  Future<bool> showRewarded(String placement) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdShowedFullScreenContent: (_) =>
          unawaited(_analytics.adShown(type: 'rewarded', placement: placement)),
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('rewarded show: ${error.message}');
        ad.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    try {
      await ad.show(
        onUserEarnedReward: (_, __) {
          earned = true;
          unawaited(_analytics.adRewarded(placement: placement));
        },
      );
    } on Object catch (e) {
      debugPrint('rewarded show threw: $e');
      if (!result.isCompleted) result.complete(false);
    }
    return result.future;
  }

  @override
  void recordGameOver() => _policy.recordGameOver();

  @override
  Future<void> maybeShowInterstitial() async {
    final now = DateTime.now();
    if (!_policy.shouldShow(adsRemoved: _adsRemoved(), now: now)) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdShowedFullScreenContent: (_) {
        _policy.markShown(now);
        unawaited(
          _analytics.adShown(
            type: 'interstitial',
            placement: AdPlacement.gameOver,
          ),
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    try {
      await ad.show();
    } on Object catch (e) {
      debugPrint('interstitial show threw: $e');
    }
  }
}

/// Used when ads cannot run (tests, unsupported platforms).
class NoopAdService implements AdService {
  @override
  Future<void> init() async {}
  @override
  bool get isRewardedReady => false;
  @override
  Future<bool> showRewarded(String placement) async => false;
  @override
  void recordGameOver() {}
  @override
  Future<void> maybeShowInterstitial() async {}
}
