import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/eye_navigation_action.dart';
import '../services/eye_navigation_service.dart';

/// Démo minimale : prévisualisation caméra avant, démarrage / arrêt, dernière action.
///
/// **Branchement UI** : passez [onNavigationAction] ou écoutez [EyeNavigationService.actions]
/// (obtenu via un service injecté / provider) pour appeler `FocusScope.of(context).nextFocus()`,
/// `PreviousFocusAction`, `ActivateAction`, etc.
class EyeNavigationDemoScreen extends StatefulWidget {
  const EyeNavigationDemoScreen({
    super.key,
    this.baseUrl,
    this.clientId,
    this.onNavigationAction,
  });

  /// Surcharge `--dart-define=EYE_NAVIGATION_BASE_URL=...` sinon défaut [AppConfig].
  final String? baseUrl;

  /// Envoyé en champ `client_id` (lissage serveur).
  final String? clientId;

  /// Hook pour votre navigation par focus / sélection.
  final void Function(EyeNavigationAction action)? onNavigationAction;

  @override
  State<EyeNavigationDemoScreen> createState() =>
      _EyeNavigationDemoScreenState();
}

class _EyeNavigationDemoScreenState extends State<EyeNavigationDemoScreen>
    with WidgetsBindingObserver {
  late final EyeNavigationService _service;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _service = EyeNavigationService(
      baseUrl: widget.baseUrl,
      clientId: widget.clientId,
      onAction: _onRemoteAction,
    );
  }

  void _onRemoteAction(EyeNavigationAction action) {
    widget.onNavigationAction?.call(action);
    // Exemples de branchement (commentez ou adaptez) :
    // switch (action) {
    //   case EyeNavigationAction.moveDown:
    //   case EyeNavigationAction.moveRight:
    //     FocusScope.of(context).nextFocus();
    //     break;
    //   case EyeNavigationAction.moveUp:
    //   case EyeNavigationAction.moveLeft:
    //     FocusScope.of(context).previousFocus();
    //     break;
    //   case EyeNavigationAction.click:
    //     Actions.invoke(context, const ActivateIntent());
    //     break;
    //   case EyeNavigationAction.idle:
    //     break;
    // }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _service.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(_service.pauseForAppLifecycle());
        break;
      case AppLifecycleState.resumed:
        unawaited(_service.resumeFromAppLifecycle());
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Navigation par regard'),
      ),
      body: ListenableBuilder(
        listenable: _service,
        builder: (context, _) {
          final cam = _service.cameraController;
          final running = _service.isRunning;
          final err = _service.lastError;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: cam != null && cam.value.isInitialized
                    ? CameraPreview(cam)
                    : ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: Text(
                            running
                                ? 'Préparation de la caméra…'
                                : 'Caméra arrêtée — appuyez sur Démarrer',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dernière action : ${_service.lastAction.name}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Serveur : ${_service.configuredBaseUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (err != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        err,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: () => unawaited(
                            running ? _service.stop() : _service.start(),
                          ),
                          child: Text(running ? 'Arrêter' : 'Démarrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
