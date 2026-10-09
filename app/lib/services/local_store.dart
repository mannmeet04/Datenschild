import 'package:shared_preferences/shared_preferences.dart';

/// Daten, die nur auf dem Gerät bleiben (erledigte Schritte, Name für DSGVO-Briefe).
class LocalStore {
  static const _onboardingKey = 'onboarding_done';
  static const _doneKey = 'done_actions';
  static const _nameKey = 'letter_name';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> onboardingDone() async => (await _prefs).getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingDone() async => (await _prefs).setBool(_onboardingKey, true);

  Future<Set<String>> doneActions() async => ((await _prefs).getStringList(_doneKey) ?? const []).toSet();

  Future<void> saveDoneActions(Set<String> ids) async => (await _prefs).setStringList(_doneKey, ids.toList());

  Future<String> letterName() async => (await _prefs).getString(_nameKey) ?? '';

  Future<void> saveLetterName(String name) async => (await _prefs).setString(_nameKey, name);

  Future<void> clear() async => (await _prefs).clear();
}
