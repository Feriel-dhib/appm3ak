import 'package:flutter/material.dart';

/// Rayons et helpers UI « cute » alignés sur [AppTheme].
class Ma3akUi {
  Ma3akUi._();

  static const double radiusCard = 20;
  static const double radiusPill = 28;
  static const double radiusChip = 16;

  static BorderRadius borderRadiusCard = BorderRadius.circular(radiusCard);
  static BorderRadius borderRadiusPill = BorderRadius.circular(radiusPill);

  /// Fond de carte / tuile selon le thème.
  static Color cardBackground(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? cs.surface
        : cs.surfaceContainerHighest;
  }

  static Color subtleBorder(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return cs.outline.withValues(alpha: 0.35);
  }
}
