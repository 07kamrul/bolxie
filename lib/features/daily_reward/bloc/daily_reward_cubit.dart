import 'dart:async';

import 'package:bloxie/core/constants/economy_constants.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DailyRewardState extends Equatable {
  const DailyRewardState({
    required this.canClaim,
    required this.nextDayIndex,
    required this.claimedDays,
  });

  final bool canClaim;

  /// 0-based calendar slot the next claim will land on.
  final int nextDayIndex;

  /// Number of calendar slots (0-7) already claimed in the current cycle.
  final int claimedDays;

  @override
  List<Object?> get props => [canClaim, nextDayIndex, claimedDays];
}

class DailyRewardCubit extends Cubit<DailyRewardState> {
  DailyRewardCubit({
    required PrefsRepository prefs,
    required WalletCubit wallet,
    required AnalyticsService analytics,
    DateTime Function()? clock,
  }) : _prefs = prefs,
       _wallet = wallet,
       _analytics = analytics,
       _clock = clock ?? DateTime.now,
       super(
         const DailyRewardState(
           canClaim: false,
           nextDayIndex: 0,
           claimedDays: 0,
         ),
       ) {
    refresh();
  }

  final PrefsRepository _prefs;
  final WalletCubit _wallet;
  final AnalyticsService _analytics;
  final DateTime Function() _clock;

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Whether claiming now continues the streak (claimed yesterday).
  bool _continuesStreak(DateTime now) {
    final last = _prefs.lastClaimDate;
    if (last == null) return false;
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    return last == _iso(yesterday);
  }

  void refresh() {
    final now = _clock();
    final streak = _prefs.dailyStreak;
    final last = _prefs.lastClaimDate;
    final canClaim = last != _iso(now);
    final effective = canClaim && !_continuesStreak(now) ? 0 : streak;
    const len = EconomyConstants.streakLength;
    if (canClaim) {
      emit(
        DailyRewardState(
          canClaim: true,
          nextDayIndex: effective % len,
          claimedDays: effective % len,
        ),
      );
    } else {
      final claimed = streak % len == 0 ? len : streak % len;
      emit(
        DailyRewardState(
          canClaim: false,
          nextDayIndex: streak % len,
          claimedDays: claimed,
        ),
      );
    }
  }

  /// Claims today's reward. Returns the coins granted, or null if unavailable.
  Future<int?> claim() async {
    if (!state.canClaim) return null;
    final now = _clock();
    final streak = _continuesStreak(now) ? _prefs.dailyStreak + 1 : 1;
    final dayIndex = (streak - 1) % EconomyConstants.streakLength;
    final coins = EconomyConstants.dailyRewards[dayIndex];
    await _prefs.setDailyStreak(streak);
    await _prefs.setLastClaimDate(_iso(now));
    await _wallet.addCoins(coins);
    unawaited(_analytics.dailyRewardClaimed(day: dayIndex + 1, coins: coins));
    refresh();
    return coins;
  }
}
