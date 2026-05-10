import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../accessibility/widgets/global_gaze_overlay.dart';
import '../models/detected_obstacle.dart';
import '../services/navigation_ai_service.dart';
import '../services/voice_guidance_service.dart';
import '../widgets/ar_obstacle_overlay.dart';
import '../widgets/guidance_arrow_overlay.dart';

/// Écran de navigation AR : flux caméra, détection d'obstacles, instructions vocales FR/AR.
class ArNavigationScreen extends ConsumerStatefulWidget {
  const ArNavigationScreen({super.key});

  @override
  ConsumerState<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends ConsumerState<ArNavigationScreen> {
  CameraController? _controller;
  NavigationAIService? _aiService;
  List<DetectedObstacle> _obstacles = [];
  bool _isProcessing = false;
  StreamSubscription<CameraImage>? _subscription;
  String? _error;
  final bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  bool _gazeWasRunning = false;

  Future<void> _init() async {
    try {
      // Libère la caméra avant utilisée par l'eye-gaze global, si actif.
      final gaze = ref.read(globalGazeServiceProvider);
      _gazeWasRunning = gaze.isRunning;
      if (_gazeWasRunning) await gaze.stop();

      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() => _error =
            'Permission caméra refusée. Activez-la dans Réglages → Ma3ak → Caméra.');
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _error = 'Aucune caméra disponible sur cet appareil.');
        return;
      }

      final CameraDescription camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.external,
          orElse: () => cameras.first,
        ),
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.yuv420,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _aiService = NavigationAIService();
        _error = null;
      });
      _startStream();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erreur caméra: $e');
    }
  }

  void _startStream() {
    _controller?.startImageStream((CameraImage image) {
      if (_isPaused || _isProcessing || _aiService == null) return;
      _isProcessing = true;
      _aiService!
          .processCameraImage(
            image,
            sensorOrientation: _controller!.description.sensorOrientation,
          )
          .then((obstacles) {
            if (mounted) setState(() => _obstacles = obstacles);
          })
          .whenComplete(() => _isProcessing = false);
    });
  }

  void _stopStream() {
    _subscription?.cancel();
    _controller?.stopImageStream();
  }

  @override
  void dispose() {
    _stopStream();
    _controller?.dispose();
    _aiService?.dispose();
    // Reprend l'eye-gaze global si on l'avait suspendu.
    if (_gazeWasRunning) {
      ref.read(globalGazeServiceProvider).start();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation AR')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.pop(),
                  child: const Text('Retour'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Navigation AR')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          ArObstacleOverlay(obstacles: _obstacles),
          const GuidanceArrowOverlay(bearingDegrees: 0, deviceHeadingDegrees: null),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: _TopBar(
              onBack: () => context.pop(),
              onLangToggle: () {
                final voice = _aiService?.voice;
                if (voice != null) {
                  voice.language = voice.language == VoiceLanguage.french
                      ? VoiceLanguage.arabic
                      : VoiceLanguage.french;
                  setState(() {});
                }
              },
              voiceLanguage: _aiService?.voice.language ?? VoiceLanguage.french,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.onBack,
    required this.onLangToggle,
    required this.voiceLanguage,
  });

  final VoidCallback onBack;
  final VoidCallback onLangToggle;
  final VoiceLanguage voiceLanguage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: onBack,
          ),
          const Spacer(),
          Material(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onLangToggle,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  voiceLanguage == VoiceLanguage.french ? 'FR' : 'AR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
