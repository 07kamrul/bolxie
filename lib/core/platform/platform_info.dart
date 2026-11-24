import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Platform detection that is safe on web.
///
/// `Platform` from `dart:io` throws an `UnsupportedError` when touched from
/// dart2js/dart2wasm code, so every check must be guarded by [kIsWeb] first.
abstract final class PlatformInfo {
  /// True when running inside a browser (including the itch.io iframe).
  static bool get isWeb => kIsWeb;

  /// True on Android or iOS native builds. False on web and desktop.
  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// True only on native Android builds.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// True only on native iOS builds.
  static bool get isIOS => !kIsWeb && Platform.isIOS;
}
