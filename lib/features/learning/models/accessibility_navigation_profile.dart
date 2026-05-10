/// Profil choisi après le questionnaire « IA accessible » : moyen de navigation prioritaire.
enum AccessibilityNavigationMode {
  /// Navigation classique (tactile).
  tactile,

  /// Commandes vocales mises en avant (écoute continue, consignes parlées).
  voix,

  /// Grosses zones tactiles + lien vers outil regard PC ; l’app reste au doigt / switch.
  regardYeux,

  /// Voix (mise en avant comme [voix]) + grandes cibles tactiles (comme [regardYeux], sans webcam).
  voixEtTactile,
}

class AccessibilityNavigationProfile {
  const AccessibilityNavigationProfile({
    required this.mode,
    required this.questionnaireCompleted,
  });

  final AccessibilityNavigationMode mode;
  final bool questionnaireCompleted;

  bool get useExpandedTouchTargets =>
      mode == AccessibilityNavigationMode.regardYeux ||
      mode == AccessibilityNavigationMode.voixEtTactile;

  bool get emphasizeVoiceNavigation =>
      mode == AccessibilityNavigationMode.voix ||
      mode == AccessibilityNavigationMode.voixEtTactile;

  static AccessibilityNavigationProfile get defaultProfile =>
      const AccessibilityNavigationProfile(
        mode: AccessibilityNavigationMode.tactile,
        questionnaireCompleted: false,
      );

  AccessibilityNavigationProfile copyWith({
    AccessibilityNavigationMode? mode,
    bool? questionnaireCompleted,
  }) {
    return AccessibilityNavigationProfile(
      mode: mode ?? this.mode,
      questionnaireCompleted: questionnaireCompleted ?? this.questionnaireCompleted,
    );
  }
}
