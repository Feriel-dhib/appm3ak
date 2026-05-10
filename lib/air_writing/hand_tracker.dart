import 'package:camera/camera.dart';
import 'package:flutter/services.dart';

/// Represente un landmark de main en coordonnees image.
class HandLandmark {
  const HandLandmark({
    required this.x,
    required this.y,
    required this.z,
  });

  final double x;
  final double y;
  final double z;
}

/// Represente l'ensemble des landmarks d'une main detectee.
class HandDetectionResult {
  const HandDetectionResult({
    required this.landmarks,
  });

  final List<HandLandmark> landmarks;

  /// Retourne la position de l'index (landmark #8).
  Offset get indexTip {
    if (landmarks.length <= 8) {
      return Offset.zero;
    }
    final tip = landmarks[8];
    return Offset(tip.x, tip.y);
  }
}

/// Wrapper de detection de main via MethodChannel (MediaPipe natif).
class HandTracker {
  HandTracker({
    MethodChannel? channel,
  }) : _channel = channel ?? const MethodChannel('ma3ak/air_writing_hand_tracker');

  final MethodChannel _channel;

  bool _isInitialized = false;

  Future<void> initialize({String? taskAssetPath}) async {
    if (_isInitialized) {
      return;
    }
    await _channel.invokeMethod<void>('initialize', <String, dynamic>{
      'taskAssetPath': taskAssetPath,
    });
    _isInitialized = true;
  }

  Future<void> dispose() async {
    if (!_isInitialized) {
      return;
    }
    await _channel.invokeMethod<void>('dispose');
    _isInitialized = false;
  }

  /// Detecte la main a partir d'une CameraImage.
  ///
  /// [deviceOrientationName] et [lensDirectionName] viennent du [CameraController]
  /// pour aligner l'image avec le modele natif (rotation / miroir).
  Future<HandDetectionResult?> detectFromCameraImage(
    CameraImage image, {
    required int sensorRotation,
    String? deviceOrientationName,
    String? lensDirectionName,
  }) async {
    if (!_isInitialized) {
      return null;
    }
    final Map<String, dynamic> payload = <String, dynamic>{
      'width': image.width,
      'height': image.height,
      'sensorRotation': sensorRotation,
      'deviceOrientation': deviceOrientationName ?? 'portraitUp',
      'lensDirection': lensDirectionName ?? 'back',
      'format': image.format.group.name,
      'planes': image.planes
          .map(
            (Plane plane) => <String, dynamic>{
              'bytesPerRow': plane.bytesPerRow,
              'bytesPerPixel': plane.bytesPerPixel ?? 0,
              'height': plane.height ?? 0,
              'width': plane.width ?? 0,
              'bytes': Uint8List.fromList(plane.bytes),
            },
          )
          .toList(growable: false),
    };

    final dynamic raw = await _channel.invokeMethod<dynamic>('detectHandLandmarks', payload);
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final dynamic listRaw = raw['landmarks'];
    if (listRaw is! List) {
      return null;
    }

    final List<HandLandmark> landmarks = <HandLandmark>[];
    for (final dynamic lm in listRaw) {
      if (lm is! Map) {
        continue;
      }
      final double x = (lm['x'] as num?)?.toDouble() ?? 0.0;
      final double y = (lm['y'] as num?)?.toDouble() ?? 0.0;
      final double z = (lm['z'] as num?)?.toDouble() ?? 0.0;
      landmarks.add(HandLandmark(x: x, y: y, z: z));
    }
    if (landmarks.isEmpty) {
      return null;
    }
    return HandDetectionResult(landmarks: landmarks);
  }
}
