import 'package:bloxie/core/constants/ad_config.dart';
import 'package:bloxie/services/ads/ad_service.dart';
import 'package:bloxie/services/ads/free_reward_ad_service.dart';
import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/prefs.dart';

void main() {
  late PrefsRepository prefs;
  late DateTime clock;

  FreeRewardAdService build() =>
      FreeRewardAdService(prefs: prefs, now: () => clock);

  setUp(() async {
    prefs = await makePrefs();
    clock = DateTime.utc(2026, 11, 24, 12);
  });

  group('FreeRewardAdService', () {
    test('grants the first reward immediately', () async {
      final earned = await build().showRewarded(AdPlacement.coins);

      expect(earned, isTrue);
    });

    test('denies the same placement while its cooldown runs', () async {
      final service = build();
      await service.showRewarded(AdPlacement.coins);

      final earned = await service.showRewarded(AdPlacement.coins);

      expect(earned, isFalse);
    });

    test('cooldowns are per placement: undo does not block revive', () async {
      final service = build();
      await service.showRewarded(AdPlacement.undo);

      final earned = await service.showRewarded(AdPlacement.revive);

      expect(earned, isTrue);
    });

    test('grants again once the cooldown has elapsed', () async {
      final service = build();
      await service.showRewarded(AdPlacement.coins);

      clock = clock.add(AdConfig.freeRewardCooldownFor(AdPlacement.coins));

      expect(await service.showRewarded(AdPlacement.coins), isTrue);
    });

    test('cooldownRemaining counts down with the clock', () async {
      final service = build();
      await service.showRewarded(AdPlacement.coins);
      final full = AdConfig.freeRewardCooldownFor(AdPlacement.coins);

      clock = clock.add(const Duration(minutes: 1));

      expect(
        service.cooldownRemaining(AdPlacement.coins),
        full - const Duration(minutes: 1),
      );
    });

    test('cooldown survives a new service instance (page reload)', () async {
      await build().showRewarded(AdPlacement.coins);

      final reloaded = build();

      expect(await reloaded.showRewarded(AdPlacement.coins), isFalse);
      expect(
        reloaded.cooldownRemaining(AdPlacement.coins),
        isNot(Duration.zero),
      );
    });

    test('a clock moved backwards does not unlock the reward', () async {
      final service = build();
      await service.showRewarded(AdPlacement.coins);

      clock = clock.subtract(const Duration(hours: 1));

      expect(await service.showRewarded(AdPlacement.coins), isFalse);
    });

    test('cooldownRemaining is zero for a never-used placement', () {
      expect(build().cooldownRemaining(AdPlacement.revive), Duration.zero);
    });

    test('noop lifecycle methods complete without error', () async {
      final service = build();

      await service.init();
      service.recordGameOver();
      await service.maybeShowInterstitial();
    });
  });
}
