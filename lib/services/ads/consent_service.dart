import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google UMP consent flow (required for EEA/UK users).
class ConsentService {
  /// Completes with whether ads may be requested. Never throws; on failure it
  /// falls back to whatever the cached consent state allows.
  Future<bool> gather() async {
    final done = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          await ConsentForm.loadAndShowConsentFormIfRequired((error) {
            if (error != null) debugPrint('consent form: ${error.message}');
          });
          if (!done.isCompleted) done.complete();
        },
        (error) {
          debugPrint('consent update: ${error.message}');
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 15));
    } on Object catch (e) {
      debugPrint('consent flow failed: $e');
    }
    try {
      return await ConsentInformation.instance.canRequestAds();
    } on Object {
      return false;
    }
  }
}
