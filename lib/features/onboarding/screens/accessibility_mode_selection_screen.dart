import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/accessibility/navigation_mode.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_semantic_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/navigation_mode_provider.dart';

/// Écran de sélection du mode d'accessibilité (handicap moteur / visuel /
/// auditif / standard).
///
/// **Quand est-il affiché ?**
///  - À la **première connexion** (juste après login/register, redirect
///    GoRouter si `accessibilityModeOnboardingDoneProvider == false`).
///  - À tout moment, depuis le **profil** (bouton "Mode d'accessibilité").
///
/// **UX** :
///  - 4 cartes claires avec icône, libellé et description courte
///    (non stigmatisant, ton neutre).
///  - Bouton "Continuer" en bas (state-driven, dégrisé si rien sélectionné
///    après edit, mais pré-sélectionne le mode actuel).
///  - Lien "Passer (mode standard)" pour ignorer le choix : mode `standard`
///    appliqué + onboarding marqué comme fait.
///  - Sync optionnelle avec le profil backend (`PATCH /users/me`).
class AccessibilityModeSelectionScreen extends ConsumerStatefulWidget {
  const AccessibilityModeSelectionScreen({
    super.key,
    this.isEditing = false,
  });

  /// `true` quand l'écran est ouvert depuis le profil (titre + UX adapté).
  /// `false` (défaut) = première sélection lors de l'onboarding.
  final bool isEditing;

  @override
  ConsumerState<AccessibilityModeSelectionScreen> createState() =>
      _AccessibilityModeSelectionScreenState();
}

class _AccessibilityModeSelectionScreenState
    extends ConsumerState<AccessibilityModeSelectionScreen> {
  AccessibilityMode? _selected;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Pré-sélectionner le mode actuel en mode édition, sinon laisser vide
    // pour que l'utilisateur fasse un choix actif.
    if (widget.isEditing) {
      _selected = ref.read(accessibilityModeProvider);
    }
  }

  Future<void> _apply(AccessibilityMode mode) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Persistance locale immédiate (provider + SharedPreferences).
      await ref
          .read(accessibilityModeProvider.notifier)
          .setMode(mode, markOnboardingDone: true);

      // Synchro best-effort avec le backend si l'utilisateur est connecté
      // ET que le `typeHandicap` actuel diffère.
      final user = ref.read(authStateProvider).value;
      final currentBackend = user?.typeHandicap;
      final desiredBackend = mode.backendTypeHandicap;
      if (user != null && currentBackend != desiredBackend) {
        try {
          await ref.read(userRepositoryProvider).updateMe(
                typeHandicap: desiredBackend,
              );
          await ref.read(authStateProvider.notifier).refreshUser();
        } catch (_) {
          // Erreur réseau silencieuse : le mode local prime, la synchro
          // backend se fera au prochain `PATCH /users/me`.
        }
      }

      if (!mounted) return;
      _goNext();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _goNext() {
    if (widget.isEditing) {
      context.pop();
      return;
    }
    // Onboarding : on rejoint l'accueil.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final semantic = context.semanticColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? 'Mode d\'accessibilité'
            : 'Personnaliser votre expérience'),
        leading: widget.isEditing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
                tooltip: 'Retour',
              )
            : null,
        automaticallyImplyLeading: widget.isEditing,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      widget.isEditing
                          ? 'Quel mode utilisez-vous ?'
                          : 'Comment souhaitez-vous utiliser Ma3ak ?',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
                  AppSpacing.gapSm,
                  Text(
                    'Choisissez le mode qui vous convient le mieux. Vous pourrez '
                    'le modifier à tout moment depuis votre profil.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  AppSpacing.gapLg,
                  ...AccessibilityMode.values.map(
                    (mode) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _ModeCard(
                        mode: mode,
                        selected: _selected == mode,
                        onTap: _saving
                            ? null
                            : () => setState(() => _selected = mode),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    AppSpacing.gapMd,
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: semantic.dangerContainer,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: semantic.danger),
                          AppSpacing.hGapSm,
                          Expanded(
                            child: Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: semantic.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Barre de boutons en bas (toujours visible).
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: (_selected == null || _saving)
                          ? null
                          : () => _apply(_selected!),
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.isEditing
                              ? 'Enregistrer'
                              : 'Continuer'),
                    ),
                  ),
                  if (!widget.isEditing) ...[
                    AppSpacing.gapSm,
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _apply(AccessibilityMode.standard),
                      child: const Text('Passer (mode standard)'),
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

/// Carte d'un mode dans la sélection — radio button visuel, accessible.
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final AccessibilityMode mode;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = mode.label(context);
    final description = mode.description(context);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label. $description',
      child: Material(
        color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
        borderRadius: AppRadius.cardBorder,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: selected ? cs.primary : cs.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    mode.icon,
                    size: 28,
                    color: selected ? cs.onPrimary : cs.primary,
                  ),
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
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapSm,
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? cs.primary : cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
