/// The events the app can report. The app has no backend, so the only
/// implementation discards them. Implementations must never throw.
abstract interface class AnalyticsService {
  Future<void> gameStart();
  Future<void> gameOver({required int score, required int durationSeconds});
  Future<void> adShown({required String type, required String placement});
  Future<void> adRewarded({required String placement});
  Future<void> iapPurchase({required String productId});
  Future<void> dailyRewardClaimed({required int day, required int coins});
  Future<void> themeChanged({required String themeId});
}

/// Offline build: nothing leaves the device.
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
