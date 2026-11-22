abstract final class EconomyConstants {
  static const int scorePerCoin = 100;
  static const int rewardedCoinAmount = 25;

  /// Coins granted for each day of the 7-day streak calendar.
  static const List<int> dailyRewards = [20, 30, 40, 50, 75, 100, 200];
  static const int streakLength = 7;
}
