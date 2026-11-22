import 'package:bloxie/features/daily_reward/bloc/daily_reward_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  late DateTime now;

  Future<(DailyRewardCubit, WalletCubit)> make([
    Map<String, Object> initial = const {},
  ]) async {
    final prefs = await makePrefs(initial);
    final wallet = WalletCubit(prefs);
    final cubit = DailyRewardCubit(
      prefs: prefs,
      wallet: wallet,
      analytics: const NoopAnalyticsService(),
      clock: () => now,
    );
    return (cubit, wallet);
  }

  setUp(() => now = DateTime(2026, 3, 10, 9));

  test('a first-time player can claim day 1', () async {
    final (c, _) = await make();
    expect(c.state.canClaim, isTrue);
    expect(c.state.nextDayIndex, 0);
  });

  test('claiming grants day-1 coins and blocks a second claim today', () async {
    final (c, wallet) = await make();
    expect(await c.claim(), 20);
    expect(wallet.state.coins, 20);
    expect(c.state.canClaim, isFalse);
    expect(await c.claim(), isNull);
  });

  test('claiming on consecutive days advances the streak', () async {
    final (c, wallet) = await make({
      'daily_last_claim': '2026-03-09',
      'daily_streak': 1,
    });
    expect(c.state.nextDayIndex, 1);
    expect(await c.claim(), 30);
    expect(wallet.state.coins, 30);
  });

  test('missing a day resets the streak to day 1', () async {
    final (c, _) = await make({
      'daily_last_claim': '2026-03-07',
      'daily_streak': 4,
    });
    expect(c.state.canClaim, isTrue);
    expect(c.state.nextDayIndex, 0);
    expect(await c.claim(), 20);
  });

  test('day 7 pays the jackpot and the cycle wraps to day 1', () async {
    final (c, _) = await make({
      'daily_last_claim': '2026-03-09',
      'daily_streak': 6,
    });
    expect(await c.claim(), 200);
    expect(c.state.claimedDays, 7);
    now = DateTime(2026, 3, 11, 9);
    c.refresh();
    expect(c.state.canClaim, isTrue);
    expect(c.state.nextDayIndex, 0);
    expect(await c.claim(), 20);
  });

  test('streak continues across a month boundary', () async {
    now = DateTime(2026, 4, 1, 9);
    final (c, _) = await make({
      'daily_last_claim': '2026-03-31',
      'daily_streak': 2,
    });
    expect(await c.claim(), 40);
  });
}
