import 'package:flutter/material.dart';

/// Tokens d'espacement de Ma3ak — utilisés pour les paddings, margins et `SizedBox`.
///
/// Évite les magic numbers : `EdgeInsets.all(AppSpacing.md)` au lieu de `EdgeInsets.all(16)`.
/// Échelle 4 px : multiples de 4 pour rester cohérent avec Material 3.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Paddings d'écran usuels (gutter horizontal cohérent sur toute l'app).
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: md);
  static const EdgeInsets screenPaddingTight =
      EdgeInsets.symmetric(horizontal: md, vertical: sm);

  // Espacement vertical entre sections d'écran.
  static const SizedBox gapXs = SizedBox(height: xs);
  static const SizedBox gapSm = SizedBox(height: sm);
  static const SizedBox gapMd = SizedBox(height: md);
  static const SizedBox gapLg = SizedBox(height: lg);
  static const SizedBox gapXl = SizedBox(height: xl);

  // Espacement horizontal.
  static const SizedBox hGapXs = SizedBox(width: xs);
  static const SizedBox hGapSm = SizedBox(width: sm);
  static const SizedBox hGapMd = SizedBox(width: md);
  static const SizedBox hGapLg = SizedBox(width: lg);
}
