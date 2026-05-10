import 'external_ai_types.dart';

/// Pas d’exécution de processus (Web / plateformes sans `dart:io`).
Future<ExternalLaunchResult> launchEyeGazeNavigationDemo() async =>
    const ExternalLaunchResult(
      ok: false,
      message:
          'Le lancement automatique n’est pas disponible sur cette plateforme. '
          'Utilisez un PC Windows ou macOS/Linux en mode bureau, ou copiez la commande affichée.',
    );

Future<ExternalLaunchResult> launchM3akSignStudio() async =>
    const ExternalLaunchResult(
      ok: false,
      message:
          'Le lancement automatique n’est pas disponible sur cette plateforme. '
          'Copiez la commande et exécutez-la dans un terminal sur votre ordinateur.',
    );
