import 'package:bloxie/features/wallet/bloc/wallet_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  test('addCoins increases and persists the balance', () async {
    final prefs = await makePrefs({'coins': 10});
    final w = WalletCubit(prefs);
    await w.addCoins(15);
    expect(w.state.coins, 25);
    expect(prefs.coins, 25);
  });

  test('addCoins ignores non-positive amounts', () async {
    final w = WalletCubit(await makePrefs({'coins': 10}));
    await w.addCoins(0);
    await w.addCoins(-5);
    expect(w.state.coins, 10);
  });

  test('spend deducts when affordable', () async {
    final w = WalletCubit(await makePrefs({'coins': 100}));
    expect(await w.spend(60), isTrue);
    expect(w.state.coins, 40);
  });

  test('spend refuses when balance is too low', () async {
    final w = WalletCubit(await makePrefs({'coins': 10}));
    expect(await w.spend(11), isFalse);
    expect(w.state.coins, 10);
  });
}
