import 'dart:async';

import 'package:bloxie/services/iap/iap_service.dart';

class FakeIapService implements IapService {
  final controller = StreamController<IapEvent>.broadcast();
  int buyCalls = 0;
  int restoreCalls = 0;
  bool available = true;

  @override
  Stream<IapEvent> get events => controller.stream;
  @override
  Future<bool> init() async => available;
  @override
  bool get isAvailable => available;
  @override
  String? get removeAdsPrice => r'$2.99';
  @override
  Future<void> buyRemoveAds() async => buyCalls++;
  @override
  Future<void> restore() async => restoreCalls++;
  @override
  Future<void> dispose() async => controller.close();
}
