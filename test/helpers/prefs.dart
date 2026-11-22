import 'package:bloxie/services/storage/prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<PrefsRepository> makePrefs([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return PrefsRepository(await SharedPreferences.getInstance());
}
