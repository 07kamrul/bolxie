import 'package:flutter/services.dart';

class HapticsService {
  HapticsService({required bool Function() isEnabled}) : _isEnabled = isEnabled;

  final bool Function() _isEnabled;

  Future<void> light() async {
    if (_isEnabled()) await HapticFeedback.lightImpact();
  }

  Future<void> medium() async {
    if (_isEnabled()) await HapticFeedback.mediumImpact();
  }

  Future<void> heavy() async {
    if (_isEnabled()) await HapticFeedback.heavyImpact();
  }
}
