import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/accessibility/navigation_mode.dart';
import 'auth_providers.dart';

/// Clé `SharedPreferences` du mode d'accessibilité persisté localement.
const String kAccessibilityModeKey = 'm3ak_accessibility_mode';

/// Clé `SharedPreferences` indiquant si l'utilisateur a déjà passé l'onboarding
/// de sélection du mode (évite de réafficher l'écran à chaque connexion).
const String kAccessibilityModeOnboardingDoneKey =
    'm3ak_accessibility_mode_onboarding_done';

/// Provider du mode d'accessibilité actif — **source unique de vérité**.
///
/// Comportement :
///  - Au démarrage : lecture de `SharedPreferences`. Si rien n'est stocké, on
///    initialise depuis `user.typeHandicap` (cohérence backend) puis on persiste.
///  - `setMode(...)` : met à jour l'état + `SharedPreferences`. La synchro
///    backend (`PATCH /users/me { typeHandicap }`) est laissée au caller pour
///    découpler ce provider des repositories.
///
/// Voir [AccessibilityMode] pour les valeurs et la migration depuis `typeHandicap`.
final accessibilityModeProvider =
    StateNotifierProvider<AccessibilityModeNotifier, AccessibilityMode>(
  AccessibilityModeNotifier.new,
);

class AccessibilityModeNotifier extends StateNotifier<AccessibilityMode> {
  AccessibilityModeNotifier(this._ref) : super(AccessibilityMode.standard) {
    _hydrate();
  }

  final Ref _ref;

  Future<void> _hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kAccessibilityModeKey);
    if (stored != null) {
      state = AccessibilityMode.fromStorage(stored);
      return;
    }
    // Pas encore de mode local : on tente de déduire depuis le profil backend.
    final user = _ref.read(authStateProvider).value;
    final derived =
        AccessibilityMode.fromBackendTypeHandicap(user?.typeHandicap);
    state = derived;
    // On NE persiste PAS encore : tant que l'utilisateur n'a pas validé via
    // l'onboarding, le mode reste « auto-dérivé » et révisable.
  }

  /// Définit le mode (utilisé par l'onboarding et l'écran profil).
  ///
  /// [markOnboardingDone] : si `true`, marque l'onboarding comme terminé
  /// pour ne pas le réafficher au prochain démarrage.
  Future<void> setMode(
    AccessibilityMode mode, {
    bool markOnboardingDone = true,
  }) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kAccessibilityModeKey, mode.name);
    if (markOnboardingDone) {
      await prefs.setBool(kAccessibilityModeOnboardingDoneKey, true);
    }
  }

  /// Vrai si l'utilisateur a déjà choisi (ou ignoré) le mode via l'onboarding.
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kAccessibilityModeOnboardingDoneKey) ?? false;
  }

  /// Réinitialise (utile pour les tests / le "logout" si on veut reproposer).
  Future<void> reset() async {
    state = AccessibilityMode.standard;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(kAccessibilityModeKey);
    await prefs.remove(kAccessibilityModeOnboardingDoneKey);
  }
}

/// Indique si l'onboarding du mode d'accessibilité a été passé (exposé en async
/// pour les redirects GoRouter).
final accessibilityModeOnboardingDoneProvider =
    FutureProvider<bool>((ref) async {
  return AccessibilityModeNotifier.hasCompletedOnboarding();
});
