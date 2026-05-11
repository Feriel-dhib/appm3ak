import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// En-tête de section avec `Semantics(header: true)` — sert de **landmark**
/// pour TalkBack / VoiceOver et homogénéise la hiérarchie visuelle.
///
/// Remplace les `Text('Section', style: titleMedium.copyWith(...))` éparpillés
/// dans les écrans avec des marges différentes.
class AccessibleSectionHeader extends StatelessWidget {
  const AccessibleSectionHeader({
    super.key,
    required this.label,
    this.action,
    this.padding,
    this.icon,
  });

  final String label;

  /// Bouton optionnel à droite (`TextButton("Voir tout")` typiquement).
  final Widget? action;

  /// Padding personnalisé (par défaut : 0 horizontal, 8 vertical).
  final EdgeInsets? padding;

  /// Icône à gauche du titre (optionnel).
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: padding ??
          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.primary),
            AppSpacing.hGapSm,
          ],
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
