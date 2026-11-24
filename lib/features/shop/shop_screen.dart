import 'dart:async';

import 'package:bloxie/core/constants/economy_constants.dart';
import 'package:bloxie/core/platform/platform_info.dart';
import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/core/theme/skins.dart';
import 'package:bloxie/features/common/coin_chip.dart';
import 'package:bloxie/features/common/constrained_content.dart';
import 'package:bloxie/features/common/gradient_scaffold.dart';
import 'package:bloxie/features/common/reward_labels.dart';
import 'package:bloxie/features/common/snack.dart';
import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/shop/theme_card.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const _tick = Duration(seconds: 1);

  bool _isWatching = false;
  Timer? _ticker;

  Duration get _cooldown =>
      sl<AdService>().cooldownRemaining(AdPlacement.coins);

  @override
  void initState() {
    super.initState();
    _syncTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Rebuilds every second while the free-coins cooldown runs, then stops.
  void _syncTicker() {
    if (_cooldown == Duration.zero) {
      _ticker?.cancel();
      _ticker = null;
      return;
    }
    _ticker ??= Timer.periodic(_tick, (_) {
      if (!mounted) return;
      setState(() {});
      _syncTicker();
    });
  }

  Future<void> _watchForCoins() async {
    if (_isWatching) return;
    setState(() => _isWatching = true);
    final earned = await sl<AdService>().showRewarded(AdPlacement.coins);
    if (earned) {
      await sl<WalletCubit>().addCoins(EconomyConstants.rewardedCoinAmount);
    }
    if (!mounted) return;
    setState(() => _isWatching = false);
    _syncTicker();
    showSnack(
      context,
      earned
          ? '+${EconomyConstants.rewardedCoinAmount} coins!'
          : RewardLabels.unavailable(_cooldown),
    );
  }

  String get _coinsLabel {
    const amount = EconomyConstants.rewardedCoinAmount;
    if (!PlatformInfo.isWeb) return 'Watch ad: +$amount coins';
    final cooldown = _cooldown;
    if (cooldown > Duration.zero) {
      return 'Free coins in ${RewardLabels.formatCooldown(cooldown)}';
    }
    return 'Free coins: +$amount';
  }

  Future<void> _onTap(String id) async {
    final result = await context.read<ShopCubit>().selectOrBuy(id);
    if (!mounted || result != ShopResult.insufficientCoins) return;
    showSnack(
      context,
      PlatformInfo.isWeb
          ? 'Not enough coins. Play more or grab free coins!'
          : 'Not enough coins. Play more or watch an ad!',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Themes'),
        actions: const [CoinChip(), SizedBox(width: 16)],
      ),
      body: BlocBuilder<ShopCubit, ShopState>(
        builder: (context, shop) => ConstrainedContent(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _isWatching || _cooldown > Duration.zero
                    ? null
                    : _watchForCoins,
                icon: Icon(
                  PlatformInfo.isWeb
                      ? Icons.card_giftcard
                      : Icons.play_circle_outline,
                ),
                label: Text(_coinsLabel),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
              ),
              const SizedBox(height: 16),
              for (final skin in Skins.all)
                ThemeCard(
                  skin: skin,
                  isSelected: shop.selectedId == skin.id,
                  isUnlocked: shop.unlocked.contains(skin.id),
                  onTap: () => _onTap(skin.id),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
