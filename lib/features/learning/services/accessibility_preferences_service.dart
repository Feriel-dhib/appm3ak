import 'package:shared_preferences/shared_preferences.dart';

import 'package:appm3ak/features/learning/models/accessibility_navigation_profile.dart';

/// Stockage local du profil de navigation (questionnaire accessibilité).
class AccessibilityPreferencesService {
  static const _keyMode = 'm3ak_a11y_nav_mode';
  static const _keyQuestionnaireDone = 'm3ak_a11y_questionnaire_done';

  Future<AccessibilityNavigationProfile> load() async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_keyQuestionnaireDone) ?? false;
    final idx = prefs.getInt(_keyMode) ?? 0;
    final mode = AccessibilityNavigationMode.values[
        idx.clamp(0, AccessibilityNavigationMode.values.length - 1)];
    return AccessibilityNavigationProfile(
      mode: mode,
      questionnaireCompleted: done,
    );
  }

  Future<void> save(AccessibilityNavigationProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMode, profile.mode.index);
    await prefs.setBool(_keyQuestionnaireDone, profile.questionnaireCompleted);
  }
}
