import 'package:bloxie/core/theme/skins.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin typed wrapper over SharedPreferences. All persistence goes through
/// here so keys live in one place and tests can use mock initial values.
class PrefsRepository {
  PrefsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _bestScore = 'best_score';
  static const _coins = 'coins';
  static const _sound = 'sound_on';
  static const _haptics = 'haptics_on';
  static const _reduceMotion = 'reduce_motion';
  static const _tutorialSeen = 'tutorial_seen';
  static const _adsRemoved = 'ads_removed';
  static const _selectedSkin = 'selected_skin';
  static const _unlockedSkins = 'unlocked_skins';
  static const _gamesPlayed = 'games_played';
  static const _totalLines = 'total_lines';
  static const _lastClaim = 'daily_last_claim';
  static const _streak = 'daily_streak';

  int get bestScore => _prefs.getInt(_bestScore) ?? 0;
  Future<void> setBestScore(int v) => _prefs.setInt(_bestScore, v);

  int get coins => _prefs.getInt(_coins) ?? 0;
  Future<void> setCoins(int v) => _prefs.setInt(_coins, v);

  bool get soundOn => _prefs.getBool(_sound) ?? true;
  Future<void> setSoundOn(bool v) => _prefs.setBool(_sound, v);

  bool get hapticsOn => _prefs.getBool(_haptics) ?? true;
  Future<void> setHapticsOn(bool v) => _prefs.setBool(_haptics, v);

  bool get reduceMotion => _prefs.getBool(_reduceMotion) ?? false;
  Future<void> setReduceMotion(bool v) => _prefs.setBool(_reduceMotion, v);

  bool get tutorialSeen => _prefs.getBool(_tutorialSeen) ?? false;
  Future<void> setTutorialSeen(bool v) => _prefs.setBool(_tutorialSeen, v);

  bool get adsRemoved => _prefs.getBool(_adsRemoved) ?? false;
  Future<void> setAdsRemoved(bool v) => _prefs.setBool(_adsRemoved, v);

  String get selectedSkin => _prefs.getString(_selectedSkin) ?? Skins.defaultId;
  Future<void> setSelectedSkin(String v) => _prefs.setString(_selectedSkin, v);

  Set<String> get unlockedSkins => {
    Skins.defaultId,
    ...?_prefs.getStringList(_unlockedSkins),
  };
  Future<void> setUnlockedSkins(Set<String> v) =>
      _prefs.setStringList(_unlockedSkins, v.toList()..sort());

  int get gamesPlayed => _prefs.getInt(_gamesPlayed) ?? 0;
  Future<void> setGamesPlayed(int v) => _prefs.setInt(_gamesPlayed, v);

  int get totalLines => _prefs.getInt(_totalLines) ?? 0;
  Future<void> setTotalLines(int v) => _prefs.setInt(_totalLines, v);

  /// ISO date (yyyy-MM-dd) of the last claimed daily reward, or null.
  String? get lastClaimDate => _prefs.getString(_lastClaim);
  Future<void> setLastClaimDate(String v) => _prefs.setString(_lastClaim, v);

  int get dailyStreak => _prefs.getInt(_streak) ?? 0;
  Future<void> setDailyStreak(int v) => _prefs.setInt(_streak, v);

  static const _freeRewardPrefix = 'free_reward_last_';

  /// Web build: epoch millis (UTC) of the last free reward for [placement].
  int? freeRewardLastGrantMs(String placement) =>
      _prefs.getInt('$_freeRewardPrefix$placement');
  Future<void> setFreeRewardLastGrantMs(String placement, int ms) =>
      _prefs.setInt('$_freeRewardPrefix$placement', ms);

  static const _unlockedLevel = 'highest_unlocked_level';
  static const _levelStars = 'level_stars';

  /// Highest level id available to play (1-based). Level 1 is always open.
  int get highestUnlockedLevel => _prefs.getInt(_unlockedLevel) ?? 1;
  Future<void> setHighestUnlockedLevel(int v) =>
      _prefs.setInt(_unlockedLevel, v);

  /// Best star count per level id, stored as 'id:stars' entries.
  Map<int, int> get levelStars {
    final out = <int, int>{};
    for (final entry in _prefs.getStringList(_levelStars) ?? const <String>[]) {
      final parts = entry.split(':');
      if (parts.length == 2) {
        final id = int.tryParse(parts[0]);
        final stars = int.tryParse(parts[1]);
        if (id != null && stars != null) out[id] = stars;
      }
    }
    return out;
  }

  Future<void> setLevelStars(Map<int, int> v) => _prefs.setStringList(
    _levelStars,
    [for (final e in v.entries) '${e.key}:${e.value}']..sort(),
  );
}
