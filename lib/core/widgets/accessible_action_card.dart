import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Carte d'action accessible — pattern unifié pour remplacer les nombreuses
/// duplications de `FilledButton.tonalIcon` + hauteur forcée + `Semantics`
/// éparpillées dans les écrans adaptés (mode vocal, gestuel, etc.).
///
/// Caractéristiques :
///  - Cible tactile **≥ 64 dp** par défaut (compatible mode aveugle / moteur).
///  - `Semantics` complet : `button: true`, `label`, `hint` optionnel.
///  - Couleur et radius issus du thème (jamais de couleur hardcodée).
///  - Icône à gauche, libellé + description optionnelle au centre, chevron à
///    droite (caché en `compact: true`).
class AccessibleActionCard extends StatelessWidget {
  const AccessibleActionCard({
    super.key,
    required this.icon,
    required this.label,
    this.description,
    this.onTap,
    this.iconColor,
    this.backgroundColor,
    this.semanticHint,
    this.trailing,
    this.compact = false,
  });

  /// Icône principale (Material outlined recommandé pour cohérence).
  final IconData icon;

  /// Libellé clair, court, sans jargon (lu par TalkBack/VoiceOver).
  final String label;

  /// Description secondaire (optionnelle) — affichée en plus petit sous le
  /// libellé. À utiliser pour clarifier une action moins évidente.
  final String? description;

  final VoidCallback? onTap;

  /// Surcharge éventuelle de la couleur de l'icône (sinon `colorScheme.primary`).
  final Color? iconColor;

  /// Surcharge éventuelle du fond (sinon `surfaceContainerHighest`).
  final Color? backgroundColor;

  /// Indice pour TalkBack/VoiceOver (ex: "Active le mode vocal").
  /// Si null, [label] sert de label de base ; [description] sert d'indice.
  final String? semanticHint;

  /// Widget de droite (par défaut un chevron). Mettre `SizedBox.shrink()` pour
  /// le cacher, ou passer un `Switch` / `Badge` selon le contexte.
  final Widget? trailing;

  /// Mode compact (cible 56 dp au lieu de 72) pour les listes denses du
  /// profil. Le mode standard reste recommandé pour les écrans adaptés.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bg = backgroundColor ?? cs.surfaceContainerHighest;
    final icColor = iconColor ?? cs.primary;
    final minHeight = compact ? 56.0 : 72.0;

    return Semantics(
      button: true,
      label: label,
      hint: semanticHint ?? description,
      child: Material(
        color: bg,
        borderRadius: AppRadius.cardBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 40 : 48,
                    height: compact ? 40 : 48,
                    decoration: BoxDecoration(
                      color: icColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: compact ? 22 : 26, color: icColor),
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!compact)
                    trailing ??
                        Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
