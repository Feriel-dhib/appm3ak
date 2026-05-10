import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/detection_result.dart';
import '../services/camera_stream_service.dart';
import '../services/yolo_tflite_service.dart';
import '../widgets/detection_bbox_overlay.dart';
import '../../alerts/alert_engine.dart';
import '../../alerts/tts_alert_service.dart';

/// Écran de détection d'obstacles en temps réel pour personnes malvoyantes.
/// Avertissement : complément, pas remplacement de la canne blanche.
/// Bouton d'arrêt d'urgence pour couper les alertes.
class ObstacleDetectionScreen extends ConsumerStatefulWidget {
  const ObstacleDetectionScreen({super.key});

  @override
  ConsumerState<ObstacleDetectionScreen> createState() =>
      _ObstacleDetectionScreenState();
}

class _ObstacleDetectionScreenState extends ConsumerState<ObstacleDetectionScreen>
    with WidgetsBindingObserver {
  final CameraStreamService _cameraService = CameraStreamService(
    preferredLens: CameraLensDirection.back,
  );
  late final YoloTfliteService _detectionService;
  late final TtsAlertService _ttsService;
  late final AlertEngine _alertEngine;

  List<DetectionResult> _detections = [];
  String? _error;
  bool _isRunning = false;
  bool _alertsMuted = false;
  bool _useArabic = false;
  bool _isInitializing = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _detectionService = YoloTfliteService();
    _ttsService = TtsAlertService();
    _alertEngine = AlertEngine(tts: _ttsService);
    _init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pauseStream();
    } else if (state == AppLifecycleState.resumed && _isRunning) {
      _resumeStream();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Ne pas appeler _pauseStream() ici : il fait setState, interdit pendant dispose.
    _cameraService.stopImageStream();
    _isRunning = false;
    _detectionService.dispose();
    _cameraService.dispose();
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // Caméra et modèle en parallèle pour réduire le temps d'attente perçu
      await Future.wait([
        _cameraService.initialize(),
        _detectionService.initialize(),
      ]);
      if (!mounted) return;
      setState(() {
        _error = null;
        _isInitializing = false;
      });
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        final isMissingModel = msg.contains('Unable to load asset') ||
            msg.contains('m3ak_yolov8.tflite') ||
            msg.contains('does not exist or has empty data');
        setState(() {
          _error = isMissingModel
              ? 'Modèle manquant.\n\nCopiez l’export TFLite du dépôt Python (export_ma3ak_tflite.py) sous le nom m3ak_yolov8.tflite dans assets/models/ (voir assets/models/README.md).'
              : msg;
          _isInitializing = false;
        });
      }
    }
  }

  void _startDetection() {
    if (!_cameraService.isInitialized || _isRunning) return;
    setState(() {
      _isRunning = true;
      _alertsMuted = false;
    });
    _ttsService.setMuted(false);
    _cameraService.startImageStream(_onCameraImage);
  }

  void _onCameraImage(CameraImage image) {
    if (!_isRunning || _isProcessing) return;
    _isProcessing = true;
    _detectionService.processCameraImage(image).then((output) {
      if (!mounted || !_isRunning) return;
      if (output.error != null && output.error!.isNotEmpty) {
        debugPrint('[Detection] ${output.error}');
      }
      final list = output.detections
          .map((s) => s.toDetectionResult())
          .toList();
      if (list.isNotEmpty) {
        final first = list.first;
        debugPrint(
          '[Detection] count=${list.length} first='
          '${first.label} conf=${first.confidence.toStringAsFixed(3)} '
          'box=(${first.boundingBox.left.toStringAsFixed(2)},'
          '${first.boundingBox.top.toStringAsFixed(2)},'
          '${first.boundingBox.right.toStringAsFixed(2)},'
          '${first.boundingBox.bottom.toStringAsFixed(2)})',
        );
      } else {
        debugPrint('[Detection] count=0');
      }
      setState(() => _detections = list);
      if (!_alertsMuted && list.isNotEmpty) {
        _alertEngine.processDetections(list, useArabic: _useArabic);
      }
    }).whenComplete(() {
      if (mounted) _isProcessing = false;
    });
  }

  void _pauseStream() {
    if (!_isRunning) return;
    _cameraService.stopImageStream();
    setState(() => _isRunning = false);
  }

  Future<void> _resumeStream() async {
    if (_isRunning) return;
    setState(() => _isRunning = true);
    _cameraService.startImageStream(_onCameraImage);
  }

  void _toggleMute() {
    setState(() => _alertsMuted = !_alertsMuted);
    _ttsService.setMuted(_alertsMuted);
    if (_alertsMuted) _ttsService.stop();
  }

  /// Après `context.go(...)` (ex. mode vocal), il n’y a souvent rien à `pop`.
  /// En secours, retour à l’accueil (pas au hub transport) pour coller au flux mode vocal.
  void _goBack() {
    if (!mounted) return;
    _pauseStream();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home?tab=0');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détection d\'obstacles'),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _goBack,
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_isInitializing) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Détection d\'obstacles'),
          backgroundColor: theme.colorScheme.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Détection d\'obstacles'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_useArabic ? Icons.translate : Icons.translate),
            onPressed: () => setState(() => _useArabic = !_useArabic),
            tooltip: _useArabic ? 'Français' : 'العربية',
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraService.controller != null &&
              _cameraService.controller!.value.isInitialized)
            CameraPreview(_cameraService.controller!),
          DetectionBBoxOverlay(detections: _detections),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: _DisclaimerBanner(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: _ControlButtons(
              isRunning: _isRunning,
              alertsMuted: _alertsMuted,
              onStart: _startDetection,
              onStop: _pauseStream,
              onMute: _toggleMute,
              onBack: _goBack,
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: 'Avertissement : ce système est un complément, pas un remplacement de la canne blanche.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.amber.shade200, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Complément à la canne blanche. Ne pas remplacer les aides habituelles.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  const _ControlButtons({
    required this.isRunning,
    required this.alertsMuted,
    required this.onStart,
    required this.onStop,
    required this.onMute,
    required this.onBack,
  });

  final bool isRunning;
  final bool alertsMuted;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onMute;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BigButton(
            icon: Icons.arrow_back,
            label: 'Retour',
            onPressed: onBack,
          ),
          _BigButton(
            icon: isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded,
            label: isRunning ? 'Arrêter' : 'Démarrer',
            onPressed: isRunning ? onStop : onStart,
            primary: true,
          ),
          _BigButton(
            icon: alertsMuted ? Icons.volume_off : Icons.volume_up,
            label: alertsMuted ? 'Réactiver alertes' : 'Couper alertes',
            onPressed: onMute,
            warning: alertsMuted,
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.warning = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool primary;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color bg = theme.colorScheme.surfaceContainerHighest;
    Color fg = theme.colorScheme.onSurface;
    if (primary) {
      bg = theme.colorScheme.primary;
      fg = theme.colorScheme.onPrimary;
    } else if (warning) {
      bg = theme.colorScheme.errorContainer;
      fg = theme.colorScheme.onErrorContainer;
    }
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: const BoxConstraints(minWidth: 88, minHeight: 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 28, color: fg),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
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
