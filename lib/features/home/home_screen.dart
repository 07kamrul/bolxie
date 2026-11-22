import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/features/common/coin_chip.dart';
import 'package:bloxie/features/common/gradient_scaffold.dart';
import 'package:bloxie/features/daily_reward/bloc/daily_reward_cubit.dart';
import 'package:bloxie/features/daily_reward/daily_reward_sheet.dart';
import 'package:bloxie/features/game_screen/game_screen.dart';
import 'package:bloxie/features/settings/settings_screen.dart';
import 'package:bloxie/features/shop/shop_screen.dart';
import 'package:bloxie/features/stats/bloc/stats_cubit.dart';
import 'package:bloxie/features/stats/stats_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A new day may have started while the app was in the background.
    if (state == AppLifecycleState.resumed) sl<DailyRewardCubit>().refresh();
  }

  void _push(Widget screen) =>
      Navigator.of(context)
          .push<void>(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final best = context.select<StatsCubit, int>((c) => c.state.bestScore);
    return GradientScaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(alignment: Alignment.centerRight, child: CoinChip()),
            const Spacer(flex: 2),
            ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                colors: [
                  Color(0xFFFF5C8A),
                  Color(0xFFFFB84D),
                  Color(0xFF4DB8FF),
                ],
              ).createShader(r),
              child: const Text(
                'BLOXIE',
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'BEST  $best',
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _push(const GameScreen()),
              icon: const Icon(Icons.play_arrow_rounded, size: 30),
              label: const Text('PLAY'),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                BlocBuilder<DailyRewardCubit, DailyRewardState>(
                  builder: (context, s) => _RoundButton(
                    icon: Icons.card_giftcard,
                    label: 'Daily',
                    showBadge: s.canClaim,
                    onTap: () => showDailyRewardSheet(context),
                  ),
                ),
                _RoundButton(
                  icon: Icons.palette,
                  label: 'Themes',
                  onTap: () => _push(const ShopScreen()),
                ),
                _RoundButton(
                  icon: Icons.bar_chart_rounded,
                  label: 'Stats',
                  onTap: () => _push(const StatsScreen()),
                ),
                _RoundButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () => _push(const SettingsScreen()),
                ),
              ],
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Badge(
          isLabelVisible: showBadge,
          smallSize: 12,
          child: IconButton.filledTonal(
            onPressed: onTap,
            iconSize: 28,
            icon: Icon(icon),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
