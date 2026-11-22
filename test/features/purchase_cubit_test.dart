import 'package:bloxie/features/wallet/bloc/purchase_cubit.dart';
import 'package:bloxie/services/analytics/analytics_service.dart';
import 'package:bloxie/services/iap/iap_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_iap.dart';
import '../helpers/prefs.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeIapService iap;

  Future<PurchaseCubit> make([Map<String, Object> initial = const {}]) async {
    final c = PurchaseCubit(
      prefs: await makePrefs(initial),
      iap: iap,
      analytics: const NoopAnalyticsService(),
    );
    await c.init();
    return c;
  }

  setUp(() => iap = FakeIapService());

  test('init exposes store availability and price', () async {
    final c = await make();
    expect(c.state.isStoreAvailable, isTrue);
    expect(c.state.price, isNotNull);
  });

  test('buyRemoveAds calls the store and marks busy', () async {
    final c = await make();
    await c.buyRemoveAds();
    expect(iap.buyCalls, 1);
    expect(c.state.isBusy, isTrue);
  });

  test('a purchased event removes ads and persists', () async {
    final prefs = await makePrefs();
    final c = PurchaseCubit(
      prefs: prefs,
      iap: iap,
      analytics: const NoopAnalyticsService(),
    );
    await c.init();
    iap.controller.add(const IapEvent(IapOutcome.purchased));
    await settle();
    expect(c.state.adsRemoved, isTrue);
    expect(c.state.isBusy, isFalse);
    expect(prefs.adsRemoved, isTrue);
  });

  test('a restored event removes ads', () async {
    final c = await make();
    iap.controller.add(const IapEvent(IapOutcome.restored));
    await settle();
    expect(c.state.adsRemoved, isTrue);
  });

  test('does not buy again once ads are removed', () async {
    final c = await make({'ads_removed': true});
    await c.buyRemoveAds();
    expect(iap.buyCalls, 0);
  });

  test('an error event clears busy and surfaces a message', () async {
    final c = await make();
    await c.buyRemoveAds();
    iap.controller.add(const IapEvent(IapOutcome.error, message: 'boom'));
    await settle();
    expect(c.state.isBusy, isFalse);
    expect(c.state.message, 'boom');
  });

  test('restore invokes the store', () async {
    final c = await make();
    await c.restore();
    expect(iap.restoreCalls, 1);
  });
}
