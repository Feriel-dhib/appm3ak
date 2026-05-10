import 'package:flutter/material.dart';

import 'package:appm3ak/features/learning/models/accessibility_navigation_profile.dart';
import 'package:appm3ak/features/learning/services/accessibility_preferences_service.dart';
import 'package:appm3ak/features/learning/screens/external_ai_studio_screen.dart';

/// Questionnaire pour adapter la navigation au type d’handicap / préférence (voix, regard, tactile).
class AccessibilityQuestionnaireScreen extends StatefulWidget {
  const AccessibilityQuestionnaireScreen({
    super.key,
    this.isFirstRun = false,
    this.initial,
  });

  /// Premier lancement : texte d’accueil un peu plus pédagogique.
  final bool isFirstRun;

  final AccessibilityNavigationProfile? initial;

  @override
  State<AccessibilityQuestionnaireScreen> createState() =>
      _AccessibilityQuestionnaireScreenState();
}

class _AccessibilityQuestionnaireScreenState
    extends State<AccessibilityQuestionnaireScreen> {
  late AccessibilityNavigationMode _selected;
  final _prefs = AccessibilityPreferencesService();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial?.mode ?? AccessibilityNavigationMode.tactile;
  }

  Future<void> _saveAndClose({required bool markDone}) async {
    await _prefs.save(
      AccessibilityNavigationProfile(
        mode: _selected,
        questionnaireCompleted: markDone,
      ),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pop(context, true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation accessible'),
        backgroundColor: const Color(0xFF0f766e),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.isFirstRun) ...[
            Text(
              'Bienvenue — M3AK s’adapte à vous',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0f766e),
                  ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'Comment souhaitez-vous surtout utiliser l’application ? '
            'Vous pourrez changer ce réglage plus tard (icône accessibilité en haut).',
            style: TextStyle(fontSize: 16, height: 1.4, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 24),
          _ChoiceTile(
            mode: AccessibilityNavigationMode.tactile,
            selected: _selected,
            icon: Icons.touch_app,
            title: 'Tactile classique',
            subtitle:
                'Je fais défiler et j’appuie sur les boutons comme d’habitude. '
                'Les commandes vocales restent disponibles si vous le voulez.',
            onSelect: () => setState(() => _selected = AccessibilityNavigationMode.tactile),
          ),
          _ChoiceTile(
            mode: AccessibilityNavigationMode.voix,
            selected: _selected,
            icon: Icons.mic,
            title: 'Surtout par la voix',
            subtitle:
                'L’écoute vocale et les consignes pour parler à l’app sont mises en avant '
                '(ex. « ouvrir chatbot », « reconnaissance faciale »).',
            onSelect: () => setState(() => _selected = AccessibilityNavigationMode.voix),
          ),
          _ChoiceTile(
            mode: AccessibilityNavigationMode.regardYeux,
            selected: _selected,
            icon: Icons.visibility,
            title: 'Par le regard (yeux)',
            subtitle:
                'Dans M3AK mobile : modules plus grands pour limiter les gestes précis. '
                'Sur PC, votre outil ia_accessibilite lit réellement le regard (webcam + MediaPipe, '
                'position des yeux / iris) et surligne une zone de la grille — lancez-le depuis « Studio IA — PC ».',
            onSelect: () => setState(() => _selected = AccessibilityNavigationMode.regardYeux),
          ),
          _ChoiceTile(
            mode: AccessibilityNavigationMode.voixEtTactile,
            selected: _selected,
            icon: Icons.record_voice_over,
            title: 'Voix + grosses cibles (les deux)',
            subtitle:
                'Vous gardez la même aide vocale que l’option 2, et les mêmes boutons / cartes '
                'agrandis que l’option 3 — sans utiliser la caméra pour le regard.',
            detailBullets: const [
              'Sur l’accueil : texte d’écoute plus lisible, modules plus hauts et plus faciles à taper.',
              'Bouton « Chat signes » étendu et commandes orales mises en avant (ex. « ouvrir chatbot »).',
              'À choisir si vous mélangez parole et doigt, ou si viser les petits boutons est pénible.',
            ],
            onSelect: () => setState(() => _selected = AccessibilityNavigationMode.voixEtTactile),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => _saveAndClose(markDone: true),
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer mon choix'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0f766e),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () async {
              setState(() => _selected = AccessibilityNavigationMode.tactile);
              await _saveAndClose(markDone: true);
            },
            child: const Text('Mode tactile par défaut (sans questionnaire)'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await _prefs.save(
                AccessibilityNavigationProfile(
                  mode: widget.initial?.mode ??
                      AccessibilityNavigationMode.tactile,
                  questionnaireCompleted: true,
                ),
              );
              if (!context.mounted) return;
              Navigator.pop(context, false);
            },
            child: const Text('Plus tard (garder le tactile par défaut)'),
          ),
          if (_selected == AccessibilityNavigationMode.regardYeux) ...[
            const SizedBox(height: 24),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.computer, color: Color(0xFF6366f1)),
              title: const Text('Lecture du regard sur PC (vos yeux)'),
              subtitle: const Text(
                'Votre script analyse le regard via la webcam (Face Landmarker / iris). '
                'Ouvrez le hub Studio IA — PC pour le lancer.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ExternalAiStudioScreen()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.mode,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelect,
    this.detailBullets,
  });

  final AccessibilityNavigationMode mode;
  final AccessibilityNavigationMode selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String>? detailBullets;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final on = selected == mode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: on ? const Color(0xFF0f766e).withValues(alpha: 0.12) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onSelect,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 36, color: on ? const Color(0xFF0f766e) : Colors.grey.shade600),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: on ? const Color(0xFF0f766e) : Colors.black87,
                                  ),
                            ),
                          ),
                          if (on) const Icon(Icons.check_circle, color: Color(0xFF0f766e)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, height: 1.35, color: Colors.grey.shade700),
                      ),
                      if (detailBullets != null && detailBullets!.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...detailBullets!.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '•',
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.2,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
