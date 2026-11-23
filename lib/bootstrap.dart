import 'dart:async';

import 'package:bloxie/app.dart';
import 'package:bloxie/core/services/service_locator.dart';
import 'package:bloxie/services/analytics/crash_reporter.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // All orientations are supported: GameLayout switches to a side-by-side
  // arrangement on wide windows.
  await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  CrashReporter.install();

  await setupServices();
  runApp(const BloxieApp());
  unawaited(warmUpServices());
}
