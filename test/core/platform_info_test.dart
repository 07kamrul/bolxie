import 'package:bloxie/core/platform/platform_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlatformInfo', () {
    // flutter_test runs on the VM, so kIsWeb is false and the dart:io
    // Platform checks must resolve without throwing.
    test('isWeb is false under the test VM', () {
      expect(PlatformInfo.isWeb, isFalse);
    });

    test('platform getters resolve without throwing', () {
      // The assertion here is simply that none of these getters throw —
      // each one is guarded by !kIsWeb before touching dart:io.
      expect(
        () =>
            (PlatformInfo.isMobile, PlatformInfo.isAndroid, PlatformInfo.isIOS),
        returnsNormally,
      );
    });
  });
}
