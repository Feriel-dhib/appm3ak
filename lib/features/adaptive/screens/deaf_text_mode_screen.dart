import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/accessible_action_card.dart';
import '../../../core/widgets/accessible_section_header.dart';
import '../../../core/widgets/ma3ak_primary_button.dart';
import '../../../providers/ai_inference_providers.dart';

/// Mode texte pour utilisateurs sourds ou malentendants.
///
/// Pendant longtemps cet écran ne contenait que la conversion texte → signes
/// et deux cartes placeholders ("Notifications" → SnackBar, "Confirmation" →
/// dialog statique) qui ne menaient nulle part. Cette refonte :
///  - garde la fonctionnalité IA texte → signes (utile),
///  - ajoute une **vraie** navigation par rubriques (équivalent textuel du
///    mode vocal de [BlindVoiceModeScreen]) : sous-titres conversation,
///    notifications, communauté, transport, contacts d'urgence,
///  - utilise [AccessibleActionCard] pour la cohérence visuelle et sémantique.
class DeafTextModeScreen extends ConsumerStatefulWidget {
  const DeafTextModeScreen({super.key});

  @override
  ConsumerState<DeafTextModeScreen> createState() =>
      _DeafTextModeScreenState();
}

class _DeafTextModeScreenState extends ConsumerState<DeafTextModeScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _runSignText() async {
    await ref
        .read(signTextControllerProvider.notifier)
        .run(_textController.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = context.semanticColors;
    final signTextState = ref.watch(signTextControllerProvider);
    final generated = signTextState.valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode texte'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Retour',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Bandeau d'introduction (sémantique header pour les lecteurs d'écran).
            Semantics(
              header: true,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: AppRadius.cardBorder,
                ),
                child: Row(
                  children: [
                    Icon(Icons.text_fields, color: cs.onPrimaryContainer),
                    AppSpacing.hGapSm,
                    Expanded(
                      child: Text(
                        'Interface visuelle active. Toutes les alertes et '
                        'confirmations passent par du texte.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.gapLg,

            // === Section 1 : Navigation rapide ===
            const AccessibleSectionHeader(
              label: 'Navigation rapide',
              icon: Icons.explore_outlined,
            ),
            AppSpacing.gapXs,
            AccessibleActionCard(
              icon: Icons.closed_caption_outlined,
              label: 'Sous-titres de conversation',
              description: 'Transcription en temps réel autour de vous',
              onTap: () =>
                  context.push('/accessibility/conversation-captions'),
            ),
            AppSpacing.gapSm,
            AccessibleActionCard(
              icon: Icons.notifications_active_outlined,
              label: 'Notifications',
              description: 'Toutes les alertes en texte',
              onTap: () => context.push('/notifications'),
            ),
            AppSpacing.gapSm,
            AccessibleActionCard(
              icon: Icons.groups_outlined,
              label: 'Communauté',
              description: 'Messages et entraide',
              onTap: () => context.go('/home?tab=4'),
            ),
            AppSpacing.gapSm,
            AccessibleActionCard(
              icon: Icons.directions_car_outlined,
              label: 'Transport',
              description: 'Demander un trajet adapté',
              onTap: () => context.go('/home?tab=1'),
            ),
            AppSpacing.gapSm,
            AccessibleActionCard(
              icon: Icons.emergency_outlined,
              label: 'Contacts d\'urgence',
              description: 'Liste des proches à prévenir',
              iconColor: semantic.danger,
              onTap: () => context.push('/accompagnants'),
            ),

            AppSpacing.gapLg,

            // === Section 2 : Outil IA — texte vers langue des signes ===
            const AccessibleSectionHeader(
              label: 'Convertir du texte en signes',
              icon: Icons.sign_language_outlined,
            ),
            AppSpacing.gapXs,
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: AppRadius.cardBorder,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      labelText: 'Phrase à convertir',
                      hintText: 'Ex : bonjour, j\'ai besoin d\'aide',
                    ),
                    minLines: 1,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  AppSpacing.gapSm,
                  Ma3akPrimaryButton(
                    label: 'Lancer la conversion',
                    icon: Icons.play_arrow,
                    loading: signTextState.isLoading,
                    onPressed: signTextState.isLoading ? null : _runSignText,
                    semanticHint:
                        'Convertit la phrase saisie en séquence visuelle en langue des signes',
                  ),
                  if (signTextState.hasError) ...[
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: semantic.dangerContainer,
                        borderRadius: AppRadius.smBorder,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 18,
                            color: semantic.danger,
                          ),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              aiFriendlyError(signTextState.error!),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: semantic.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (generated != null) ...[
                    AppSpacing.gapMd,
                    const Divider(),
                    AppSpacing.gapSm,
                    Text(
                      'Séquence visuelle',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    AppSpacing.gapXs,
                    Text(
                      generated.visualSequence.isEmpty
                          ? 'Aucune séquence visuelle retournée.'
                          : generated.visualSequence.join('  '),
                      style: theme.textTheme.titleMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
