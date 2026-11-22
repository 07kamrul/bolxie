import 'dart:async';

import 'package:bloxie/app.dart';
import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/services/analytics/crash_reporter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  var isFirebaseReady = false;
  try {
    await Firebase.initializeApp();
    isFirebaseReady = true;
  } on Object catch (e) {
    // Expected until google-services.json / GoogleService-Info.plist exist.
    debugPrint('Firebase not configured, analytics disabled: $e');
  }
  CrashReporter.install(isFirebaseReady: isFirebaseReady);

  await setupServices(isFirebaseReady: isFirebaseReady);
  runApp(const BloxieApp());
  unawaited(warmUpServices());
}
