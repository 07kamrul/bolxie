import 'package:bloxie/features/common/reward_labels.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RewardLabels', () {
    test('formatCooldown pads seconds', () {
      expect(
        RewardLabels.formatCooldown(const Duration(minutes: 3, seconds: 7)),
        '3:07',
      );
    });

    test('formatCooldown clamps negative durations to zero', () {
      expect(RewardLabels.formatCooldown(const Duration(seconds: -5)), '0:00');
    });

    // Tests run on the VM (not web), so the mobile wording applies.
    test('mobile labels mention ads', () {
      expect(RewardLabels.revive, 'REVIVE (AD)');
      expect(RewardLabels.undoTooltip, 'Undo (watch ad)');
      expect(
        RewardLabels.unavailable(Duration.zero),
        'No ad available right now. Try again later.',
      );
    });
  });
}
