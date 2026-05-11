import 'package:flutter/material.dart';

/// Tokens de rayon (corner radius) de Ma3ak.
///
/// Aligné sur `AppTheme` : inputs 18, cartes 20, pills/CTA 28.
/// Utilisez `AppRadius.cardBorder` au lieu de `BorderRadius.circular(20)` partout.
class AppRadius {
  AppRadius._();

  static const double xs = 6.0;
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double input = 18.0;
  static const double card = 20.0;
  static const double pill = 28.0;
  static const double round = 999.0;

  static const BorderRadius inputBorder = BorderRadius.all(Radius.circular(input));
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
}

/// Tailles tactiles minimales (WCAG / Material 3 : 48×48 dp).
class AppMinSize {
  AppMinSize._();

  /// Hauteur minimale d'un bouton accessible.
  static const double buttonHeight = 52.0;

  /// Hauteur minimale d'un gros CTA pour modes adaptatifs (mode aveugle).
  static const double accessibleButtonHeight = 64.0;

  /// Cible tactile minimale (icônes cliquables).
  static const double touchTarget = 48.0;

  /// Largeur minimale pour un bouton avec libellé.
  static const double buttonWidth = 88.0;
}
