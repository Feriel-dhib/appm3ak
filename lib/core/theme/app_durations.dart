/// Durées d'animation standardisées pour l'app Ma3ak.
///
/// Cohérence : transitions Material 3 (short = 100–200 ms, medium = 250–400 ms).
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);

  /// Délai max pour le splash avant fallback (au lieu d'une race condition à 400 ms).
  static const Duration splashSafetyTimeout = Duration(seconds: 6);

  /// Durée d'affichage d'un SnackBar standard.
  static const Duration snackbar = Duration(seconds: 3);
}
