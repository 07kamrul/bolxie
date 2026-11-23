import 'package:flutter/foundation.dart';

/// Keeps errors on-device: they are printed to the console and never sent
/// anywhere, since the app has no backend.
abstract final class CrashReporter {
  static void install() {
    FlutterError.onError = FlutterError.presentError;
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Unhandled error: $error\n$stack');
      return true;
    };
  }
}
