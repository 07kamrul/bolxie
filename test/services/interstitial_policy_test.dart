import 'dart:math';

import 'package:bloxie/services/ads/interstitial_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  InterstitialPolicy make({int seed = 1}) => InterstitialPolicy(
    random: Random(seed),
    minGameOvers: 3,
    maxGameOvers: 4,
    cooldown: const Duration(seconds: 120),
  );

  void gameOvers(InterstitialPolicy p, int n) {
    for (var i = 0; i < n; i++) {
      p.recordGameOver();
    }
  }

  test('does not show before the minimum number of game overs', () {
    final p = make();
    gameOvers(p, 2);
    expect(p.shouldShow(adsRemoved: false, now: t0), isFalse);
  });

  test('always shows once the maximum is reached', () {
    final p = make();
    gameOvers(p, 4);
    expect(p.shouldShow(adsRemoved: false, now: t0), isTrue);
  });

  test('never shows when ads were removed', () {
    final p = make();
    gameOvers(p, 10);
    expect(p.shouldShow(adsRemoved: true, now: t0), isFalse);
  });

  test('respects the cooldown after an ad was shown', () {
    final p = make();
    gameOvers(p, 4);
    p.markShown(t0);
    gameOvers(p, 4);
    expect(
      p.shouldShow(adsRemoved: false, now: t0.add(const Duration(seconds: 60))),
      isFalse,
    );
    expect(
      p.shouldShow(
        adsRemoved: false,
        now: t0.add(const Duration(seconds: 121)),
      ),
      isTrue,
    );
  });

  test('markShown resets the counter', () {
    final p = make();
    gameOvers(p, 4);
    p.markShown(t0);
    expect(
      p.shouldShow(adsRemoved: false, now: t0.add(const Duration(hours: 1))),
      isFalse,
    );
  });

  test('interval is always within [min, max] across seeds', () {
    for (var seed = 0; seed < 50; seed++) {
      final p = make(seed: seed);
      expect(p.target, inInclusiveRange(3, 4));
    }
  });
}
