import 'package:bloxie/features/shop/bloc/shop_cubit.dart';
import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  Future<(ShopCubit, WalletCubit)> make(int coins) async {
    final prefs = await makePrefs({'coins': coins});
    final wallet = WalletCubit(prefs);
    final shop = ShopCubit(
      prefs: prefs,
      wallet: wallet,
      analytics: const NoopAnalyticsService(),
    );
    return (shop, wallet);
  }

  test('starts with only the default skin unlocked', () async {
    final (shop, _) = await make(0);
    expect(shop.state.selectedId, 'neon');
    expect(shop.state.unlocked, {'neon'});
  });

  test(
    'buying an affordable skin spends coins, unlocks and selects it',
    () async {
      final (shop, wallet) = await make(600);
      expect(await shop.selectOrBuy('sunset'), ShopResult.unlocked);
      expect(wallet.state.coins, 100);
      expect(shop.state.selectedId, 'sunset');
      expect(shop.state.unlocked, contains('sunset'));
    },
  );

  test('an unaffordable skin is refused and nothing changes', () async {
    final (shop, wallet) = await make(499);
    expect(await shop.selectOrBuy('sunset'), ShopResult.insufficientCoins);
    expect(wallet.state.coins, 499);
    expect(shop.state.selectedId, 'neon');
  });

  test('re-selecting an owned skin is free', () async {
    final (shop, wallet) = await make(500);
    await shop.selectOrBuy('sunset');
    await shop.selectOrBuy('neon');
    expect(await shop.selectOrBuy('sunset'), ShopResult.selected);
    expect(wallet.state.coins, 0);
  });
}
