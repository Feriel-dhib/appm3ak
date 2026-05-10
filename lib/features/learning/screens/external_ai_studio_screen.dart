import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:appm3ak/features/learning/services/external_ai_desktop_only.dart';
import 'package:appm3ak/features/learning/services/external_ai_launcher.dart';

/// Point d’entrée unique pour les deux outils Python (PC) : navigation regard + audio→signes.
class ExternalAiStudioScreen extends StatefulWidget {
  const ExternalAiStudioScreen({super.key});

  @override
  State<ExternalAiStudioScreen> createState() => _ExternalAiStudioScreenState();
}

class _ExternalAiStudioScreenState extends State<ExternalAiStudioScreen> {
  String? _lastStatus;
  bool _busy = false;

  static const String _cmdEyePowershell = r'''# Terminal PowerShell — Lecture du regard (yeux) — grille 3×3, MediaPipe Face Landmarker
cd $env:USERPROFILE\ia_accessibilite
.\venv\Scripts\Activate.ps1
python eye_gaze_navigation_demo.py
''';

  static const String _cmdSignPowershell = r'''# Terminal PowerShell — M3AK Sign : audio → langue des signes (Whisper + glossaire)
cd $env:USERPROFILE\m3ak-sign
.\m3ak_env\Scripts\python.exe main.py
''';

  static const String _cmdSignPowershellWebcam = r'''# Avec webcam mains (optionnel) :
cd $env:USERPROFILE\m3ak-sign
.\m3ak_env\Scripts\python.exe main.py --webcam
''';

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text.trim()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Commande copiée dans le presse-papiers')),
    );
  }

  Future<void> _launch(Future<ExternalLaunchResult> Function() fn) async {
    setState(() {
      _busy = true;
      _lastStatus = null;
    });
    final r = await fn();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _lastStatus = r.message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(r.message),
        backgroundColor: r.ok ? Colors.green.shade800 : Colors.orange.shade900,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Studio IA — outils PC'),
        backgroundColor: const Color(0xFF1e3a5f),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Les deux projets suivants tournent sur votre ordinateur (Python), pas dans l’application mobile ou Web.',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.35),
          ),
          if (!canAutoLaunchExternalPythonTools) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  kIsWeb
                      ? 'Sur le Web : copiez la commande et exécutez-la dans PowerShell sur votre PC Windows.'
                      : 'Sur mobile : copiez la commande et lancez-la sur un PC où les dossiers ia_accessibilite et m3ak-sign sont installés.',
                  style: TextStyle(color: Colors.amber.shade900),
                ),
              ),
            ),
          ],
          if (_lastStatus != null) ...[
            const SizedBox(height: 12),
            Text(_lastStatus!, style: TextStyle(color: Colors.blueGrey.shade800)),
          ],
          const SizedBox(height: 24),
          _toolCard(
            context,
            icon: Icons.visibility,
            color: const Color(0xFF0d9488),
            title: 'IA accessibilité — lecture du regard (yeux)',
            body:
                'Ce module utilise la webcam et un modèle MediaPipe (Face Landmarker) qui lit la position du regard '
                'à partir des yeux (repères faciaux / iris). Une grille 3×3 sur l’écran indique la zone regardée — '
                'ce n’est pas une démo « décorative » : le regard est réellement estimé depuis la vidéo.\n\n'
                'Prérequis : dossier ia_accessibilite, Python, venv, mediapipe, opencv. '
                'Au premier lancement, le fichier face_landmarker.task est téléchargé.',
            copyText: _cmdEyePowershell,
            onLaunchDesktop: canAutoLaunchExternalPythonTools
                ? () => _launch(launchEyeGazeNavigationDemo)
                : null,
          ),
          const SizedBox(height: 20),
          _toolCard(
            context,
            icon: Icons.hearing,
            color: const Color(0xFF6366f1),
            title: 'M3AK Sign — audio vers langue des signes',
            body:
                'Écoute le micro (ou la sortie audio système selon la config du projet), transcrit avec Whisper, '
                'puis affiche glosses et séquence de signes (glossaire + visuels).\n\n'
                'Prérequis : environnement m3ak_env dans m3ak-sign, modèle Whisper (téléchargé au premier usage).',
            copyText: '$_cmdSignPowershell\n\n$_cmdSignPowershellWebcam',
            onLaunchDesktop: canAutoLaunchExternalPythonTools
                ? () => _launch(launchM3akSignStudio)
                : null,
          ),
          const SizedBox(height: 28),
          _howToTestSection(),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required String copyText,
    VoidCallback? onLaunchDesktop,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(body, style: TextStyle(height: 1.4, color: Colors.grey.shade800)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _copy(copyText),
                  icon: const Icon(Icons.copy, size: 20),
                  label: const Text('Copier la commande'),
                  style: FilledButton.styleFrom(backgroundColor: color),
                ),
                if (onLaunchDesktop != null)
                  OutlinedButton.icon(
                    onPressed: _busy ? null : onLaunchDesktop,
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(_busy ? 'Lancement…' : 'Lancer depuis M3AK'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _howToTestSection() {
    return Card(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comment tester (résumé)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const _Bullet('Placez les dossiers ia_accessibilite et m3ak-sign dans votre profil utilisateur Windows (même niveau que Documents).'),
            const _Bullet('Navigation regard : lancez le script, webcam ouverte. Le modèle lit le regard (yeux) : une case de la grille 3×3 suit vos yeux. Touche I inverse gauche/droite si besoin. Q pour quitter.'),
            const _Bullet('M3AK Sign : lancez la commande ; attendez le chargement de Whisper. Parlez : la transcription et les glosses apparaissent. Option --webcam pour un aperçu des mains.'),
            const _Bullet('Application Flutter : sur Windows en mode bureau, le bouton « Lancer depuis M3AK » démarre le script si le venv est au bon endroit.'),
            const _Bullet('Sur Android / iOS / Web : seule la copie de commande sert ; exécutez-la sur un PC où les projets Python sont installés.'),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.blueGrey.shade700, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: TextStyle(height: 1.35, color: Colors.blueGrey.shade900))),
        ],
      ),
    );
  }
}
