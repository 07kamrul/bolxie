import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Routes framework and async errors to Crashlytics when Firebase is ready,
/// and to the console otherwise.
abstract final class CrashReporter {
  static void install({required bool isFirebaseReady}) {
    if (!isFirebaseReady) {
      FlutterError.onError = FlutterError.presentError;
      return;
    }
    final crashlytics = FirebaseCrashlytics.instance;
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }
}
