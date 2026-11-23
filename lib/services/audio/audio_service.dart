import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

/// Placeholder asset names; replace the files in assets/audio/ to re-skin.
abstract final class Sfx {
  static const place = 'place.wav';
  static const clear = 'clear.wav';
  static const combo = 'combo.wav';
  static const gameOver = 'game_over.wav';
  static const all = [place, clear, combo, gameOver];
}

class AudioService {
  AudioService({required bool Function() isEnabled}) : _isEnabled = isEnabled;

  final bool Function() _isEnabled;
  bool _ready = false;
  final Map<String, AudioPool> _pools = {};

  Future<void> preload() async {
    try {
      await FlameAudio.audioCache.loadAll(Sfx.all);
      // Pools reuse players, avoiding per-play player creation latency.
      for (final file in Sfx.all) {
        _pools[file] = await FlameAudio.createPool(file, maxPlayers: 4);
      }
      _ready = true;
    } on Object catch (e) {
      debugPrint('audio preload failed: $e');
    }
  }

  Future<void> play(String file) async {
    if (!_ready || !_isEnabled()) return;
    try {
      final pool = _pools[file];
      if (pool != null) {
        await pool.start();
      } else {
        await FlameAudio.play(file);
      }
    } on Object catch (e) {
      debugPrint('audio "$file" failed: $e');
    }
  }
}
