import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

import '../models/detected_obstacle.dart';
import 'object_detection_service.dart';
import 'voice_guidance_service.dart';

/// Orchestre la détection d'obstacles et les annonces vocales.
class NavigationAIService {
  NavigationAIService({
    ObjectDetectionService? objectDetection,
    VoiceGuidanceService? voice,
  })  : _detection = objectDetection ?? ObjectDetectionService(),
        _voice = voice ?? VoiceGuidanceService();

  final ObjectDetectionService _detection;
  final VoiceGuidanceService _voice;

  VoiceGuidanceService get voice => _voice;

  /// Derniers obstacles détectés (pour l'UI / overlay).
  List<DetectedObstacle> get lastObstacles => List.unmodifiable(_lastObstacles);
  final List<DetectedObstacle> _lastObstacles = [];

  /// Intervalle minimum entre deux annonces vocales pour le même type (éviter le spam).
  static const Duration _minAnnounceInterval = Duration(seconds: 3);
  DateTime? _lastAnnounceTime;
  String? _lastAnnouncedLabel;

  /// Traite une image caméra et met à jour [lastObstacles], annonce les obstacles à voix haute.
  Future<List<DetectedObstacle>> processCameraImage(CameraImage image, {required int sensorOrientation}) async {
    final input = _imageFromCamera(image, sensorOrientation);
    if (input == null) return _lastObstacles;

    final obstacles = await _detection.processImage(input);
    _lastObstacles
      ..clear()
      ..addAll(obstacles);

    await _announceClosestObstacleIfNeeded(obstacles);
    return obstacles;
  }

  InputImage? _imageFromCamera(CameraImage image, int sensorOrientation) {
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final rotation = _rotationFromSensor(sensorOrientation);
    if (image.planes.length == 1) {
      return InputImage.fromBytes(
        bytes: image.planes.first.bytes,
        metadata: InputImageMetadata(
          size: size,
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }
    final nv21 = _yuv420ToNv21(image);
    if (nv21 == null) return null;
    return InputImage.fromBytes(
      bytes: nv21,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List? _yuv420ToNv21(CameraImage image) {
    if (image.planes.length < 3) return null;
    final y = image.planes[0].bytes;
    final u = image.planes[1].bytes;
    final v = image.planes[2].bytes;
    final nv21 = Uint8List(y.length + u.length + v.length);
    nv21.setRange(0, y.length, y);
    for (var i = 0; i < u.length; i++) {
      nv21[y.length + i * 2] = v[i];
      nv21[y.length + i * 2 + 1] = u[i];
    }
    return nv21;
  }

  Future<void> _announceClosestObstacleIfNeeded(List<DetectedObstacle> obstacles) async {
    if (obstacles.isEmpty) return;
    final closest = _closestToCenter(obstacles);
    if (closest == null) return;

    final now = DateTime.now();
    if (_lastAnnounceTime != null &&
        now.difference(_lastAnnounceTime!) < _minAnnounceInterval &&
        _lastAnnouncedLabel == closest.label) {
      return;
    }

    _lastAnnounceTime = now;
    _lastAnnouncedLabel = closest.label;
    await _voice.speakObstacle(closest.label);
  }

  DetectedObstacle? _closestToCenter(List<DetectedObstacle> obstacles) {
    if (obstacles.isEmpty) return null;
    const cx = 0.5;
    const cy = 0.5;
    DetectedObstacle? best;
    var bestD = double.infinity;
    for (final o in obstacles) {
      final d = (o.centerX - cx) * (o.centerX - cx) + (o.centerY - cy) * (o.centerY - cy);
      if (d < bestD) {
        bestD = d;
        best = o;
      }
    }
    return best;
  }

  /// Annonce une direction (pour l’AR / guidage).
  Future<void> announceDirection(String directionKey) async {
    await _voice.speakDirection(directionKey);
  }

  void dispose() {
    _detection.dispose();
    _voice.dispose();
  }
}
