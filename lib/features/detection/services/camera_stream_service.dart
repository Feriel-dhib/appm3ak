import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';

/// Service de capture vidéo en temps réel pour la détection d'obstacles.
/// Gère l'initialisation de la caméra (avant/arrière), le flux d'images et le cycle de vie.
class CameraStreamService {
  CameraStreamService({this.preferredLens = CameraLensDirection.back});

  CameraController? _controller;
  StreamController<CameraImage>? _streamController;
  bool _isStreaming = false;

  /// Caméra préférée : arrière pour la marche (champ devant), avant pour selfie.
  final CameraLensDirection preferredLens;

  CameraController? get controller => _controller;
  bool get isInitialized => _controller?.value.isInitialized ?? false;
  bool get isStreaming => _isStreaming;

  /// Flux d'images brutes (à consommer avec throttling pour l'inférence).
  Stream<CameraImage>? get imageStream => _streamController?.stream;

  /// Initialise la caméra (premier appareil correspondant à [preferredLens], sinon le premier disponible).
  Future<void> initialize() async {
    if (_controller != null) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('Aucune caméra disponible');
    }

    CameraDescription? camera;
    for (final c in cameras) {
      if (c.lensDirection == preferredLens) {
        camera = c;
        break;
      }
    }
    camera ??= cameras.first;

    // iOS : BGRA8888 (1 plan) plus fiable ; Android : YUV420 (3 plans).
    final imageFormat = Platform.isIOS
        ? ImageFormatGroup.bgra8888
        : ImageFormatGroup.yuv420;
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      imageFormatGroup: imageFormat,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
  }

  /// Démarre le flux d'images (à appeler après [initialize]).
  void startImageStream(void Function(CameraImage image) onImage) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    _controller!.startImageStream(onImage);
    _isStreaming = true;
  }

  /// Arrête le flux d'images (sans erreur si aucun flux n'est actif).
  Future<void> stopImageStream() async {
    if (_controller == null || !_isStreaming) return;
    try {
      await _controller!.stopImageStream();
    } on CameraException catch (e) {
      // Condition de course possible lors du dispose/navigation rapide.
      if (!e.description.toString().contains('No camera is streaming images')) {
        rethrow;
      }
    } finally {
      _isStreaming = false;
    }
  }

  /// Libère la caméra.
  Future<void> dispose() async {
    await stopImageStream();
    // Mettre à null tout de suite : pendant `dispose()` natif, [controller] ne doit plus
    // exposer un [CameraPreview] (évite buildPreview() sur contrôleur en cours de destruction).
    final c = _controller;
    _controller = null;
    await c?.dispose();
    await _streamController?.close();
    _streamController = null;
  }
}
