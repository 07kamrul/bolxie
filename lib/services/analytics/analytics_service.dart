import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// The seven events the app reports. Implementations must never throw.
abstract interface class AnalyticsService {
  Future<void> gameStart();
  Future<void> gameOver({required int score, required int durationSeconds});
  Future<void> adShown({required String type, required String placement});
  Future<void> adRewarded({required String placement});
  Future<void> iapPurchase({required String productId});
  Future<void> dailyRewardClaimed({required int day, required int coins});
  Future<void> themeChanged({required String themeId});
}

class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  Future<void> gameStart() async {}
  @override
  Future<void> gameOver({
    required int score,
    required int durationSeconds,
  }) async {}
  @override
  Future<void> adShown({
    required String type,
    required String placement,
  }) async {}
  @override
  Future<void> adRewarded({required String placement}) async {}
  @override
  Future<void> iapPurchase({required String productId}) async {}
  @override
  Future<void> dailyRewardClaimed({
    required int day,
    required int coins,
  }) async {}
  @override
  Future<void> themeChanged({required String themeId}) async {}
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _analytics.logEvent(name: name, parameters: params);
    } on Object catch (e, st) {
      debugPrint('analytics "$name" failed: $e\n$st');
    }
  }

  @override
  Future<void> gameStart() => _log('game_start');

  @override
  Future<void> gameOver({required int score, required int durationSeconds}) =>
      _log('game_over', {'score': score, 'duration': durationSeconds});

  @override
  Future<void> adShown({required String type, required String placement}) =>
      _log('ad_shown', {'ad_type': type, 'placement': placement});

  @override
  Future<void> adRewarded({required String placement}) =>
      _log('ad_rewarded', {'placement': placement});

  @override
  Future<void> iapPurchase({required String productId}) =>
      _log('iap_purchase', {'product_id': productId});

  @override
  Future<void> dailyRewardClaimed({required int day, required int coins}) =>
      _log('daily_reward_claimed', {'day': day, 'coins': coins});

  @override
  Future<void> themeChanged({required String themeId}) =>
      _log('theme_changed', {'theme_id': themeId});
}
