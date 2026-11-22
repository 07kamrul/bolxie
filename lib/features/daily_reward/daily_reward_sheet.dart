import 'package:bloxie/core/constants/economy_constants.dart';
import 'package:bloxie/features/common/snack.dart';
import 'package:bloxie/features/daily_reward/bloc/daily_reward_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

Future<void> showDailyRewardSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => BlocProvider.value(
      value: context.read<DailyRewardCubit>(),
      child: const _DailyRewardSheet(),
    ),
  );
}

class _DailyRewardSheet extends StatelessWidget {
  const _DailyRewardSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: BlocBuilder<DailyRewardCubit, DailyRewardState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Daily Reward',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text('Come back every day for bigger rewards'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < EconomyConstants.streakLength; i++)
                      _DayTile(
                        day: i + 1,
                        coins: EconomyConstants.dailyRewards[i],
                        isClaimed: i < state.claimedDays,
                        isNext: state.canClaim && i == state.nextDayIndex,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: state.canClaim
                      ? () async {
                          final coins = await context
                              .read<DailyRewardCubit>()
                              .claim();
                          if (coins != null && context.mounted) {
                            showSnack(context, '+$coins coins!');
                          }
                        }
                      : null,
                  child: Text(state.canClaim ? 'CLAIM' : 'Come back tomorrow'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.coins,
    required this.isClaimed,
    required this.isNext,
  });

  final int day;
  final int coins;
  final bool isClaimed;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isJackpot = day == EconomyConstants.streakLength;
    return Container(
      width: isJackpot ? 140 : 72,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isNext
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isNext ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text('Day $day', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          Icon(
            isClaimed ? Icons.check_circle : Icons.monetization_on,
            color: isClaimed ? Colors.greenAccent : const Color(0xFFFFD43B),
            size: isJackpot ? 34 : 26,
          ),
          const SizedBox(height: 6),
          Text('$coins', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
