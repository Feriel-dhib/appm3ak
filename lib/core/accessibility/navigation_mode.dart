import 'package:flutter/material.dart';

import '../../data/models/type_handicap.dart';

/// Mode d'accessibilité / navigation choisi par l'utilisateur — **source
/// unique de vérité** pour personnaliser l'UI et les flux selon le type de
/// handicap.
///
/// (Nommé `AccessibilityMode` pour éviter le conflit avec `NavigationMode`
/// défini par Flutter dans `media_query.dart`.)
///
/// Ce mode est :
///  - sélectionné à l'onboarding (écran `AccessibilityModeSelectionScreen`),
///  - modifiable à tout moment depuis le profil,
///  - persisté localement (`SharedPreferences`) ET synchronisable avec le
///    champ `typeHandicap` du backend pour la cohérence multi-appareils.
///
/// **Important** : remplace l'utilisation directe de `user.typeHandicap` /
/// `TypeHandicap.fromApiString` / `AiUserType.fromJson` qui coexistaient
/// dans le code avec des règles divergentes.
enum AccessibilityMode {
  /// Mode par défaut, aucune adaptation spécifique.
  standard,

  /// Handicap moteur : grands boutons, balayage, dwell, air-click.
  motor,

  /// Handicap visuel : mode vocal, TTS systématique, navigation par voix.
  visual,

  /// Handicap auditif : sous-titres, alertes visuelles, langue des signes.
  hearing;

  /// Construit un `AccessibilityMode` à partir du champ `typeHandicap` du
  /// backend ou de toute chaîne API hétérogène (`"Handicap moteur"`,
  /// `"visuel"`, `"malvoyant"`, `"aveugle"`, etc.). Retourne [standard] si
  /// aucune correspondance n'est trouvée (au lieu de `null` pour ne pas
  /// obliger les callers à gérer un cas nul).
  static AccessibilityMode fromBackendTypeHandicap(String? value) {
    final type = TypeHandicap.fromApiString(value);
    switch (type) {
      case TypeHandicap.moteur:
        return AccessibilityMode.motor;
      case TypeHandicap.visuel:
        return AccessibilityMode.visual;
      case TypeHandicap.auditif:
        return AccessibilityMode.hearing;
      case null:
        return AccessibilityMode.standard;
    }
  }

  /// Sérialisation pour `SharedPreferences`.
  static AccessibilityMode fromStorage(String? value) {
    if (value == null) return AccessibilityMode.standard;
    for (final m in AccessibilityMode.values) {
      if (m.name == value) return m;
    }
    return AccessibilityMode.standard;
  }

  /// Valeur `typeHandicap` à envoyer au backend pour rester cohérent avec le
  /// profil utilisateur. `null` pour le mode standard (pas de handicap déclaré).
  String? get backendTypeHandicap {
    switch (this) {
      case AccessibilityMode.standard:
        return null;
      case AccessibilityMode.motor:
        return TypeHandicap.moteur.backendValue;
      case AccessibilityMode.visual:
        return TypeHandicap.visuel.backendValue;
      case AccessibilityMode.hearing:
        return TypeHandicap.auditif.backendValue;
    }
  }

  /// Indique si ce mode déclenche un parcours adapté (à utiliser pour les
  /// gardes de route et les filtres d'écrans).
  bool get isAdaptive => this != AccessibilityMode.standard;
}

/// Métadonnées d'affichage du mode — libellés, icônes, descriptions.
///
/// Séparé de l'enum pour éviter d'importer `material` partout (les
/// repositories / providers utilisent seulement l'enum brut).
extension AccessibilityModeUi on AccessibilityMode {
  /// Libellé court pour les cartes / chips.
  String label(BuildContext context) {
    switch (this) {
      case AccessibilityMode.standard:
        return 'Mode standard';
      case AccessibilityMode.motor:
        return 'Handicap moteur';
      case AccessibilityMode.visual:
        return 'Handicap visuel';
      case AccessibilityMode.hearing:
        return 'Handicap auditif';
    }
  }

  /// Description courte, affichée sous le libellé sur la carte de sélection.
  String description(BuildContext context) {
    switch (this) {
      case AccessibilityMode.standard:
        return 'Interface classique, sans adaptation spécifique.';
      case AccessibilityMode.motor:
        return 'Grands boutons, balayage automatique, geste à distance.';
      case AccessibilityMode.visual:
        return 'Navigation vocale, lecture d\'écran, alertes sonores.';
      case AccessibilityMode.hearing:
        return 'Sous-titres, alertes visuelles, communication écrite.';
    }
  }

  /// Icône représentative — neutre et non stigmatisante.
  IconData get icon {
    switch (this) {
      case AccessibilityMode.standard:
        return Icons.smartphone_outlined;
      case AccessibilityMode.motor:
        return Icons.accessibility_new_outlined;
      case AccessibilityMode.visual:
        return Icons.visibility_outlined;
      case AccessibilityMode.hearing:
        return Icons.hearing_outlined;
    }
  }
}
