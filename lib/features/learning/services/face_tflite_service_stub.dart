import 'dart:typed_data';

import 'package:appm3ak/features/learning/models/face_detection_result.dart';

/// Sur **web**, TensorFlow Lite (`dart:ffi`) n'existe pas : pas de modèle local.
/// [FaceAiService] utilise alors uniquement le serveur FastAPI.
class FaceTfliteService {
  FaceTfliteService();

  static const String assetPath = 'assets/models/face_model.tflite';

  bool get isReady => false;

  Future<void> initialize() async {}

  Future<void> dispose() async {}

  Future<FaceDetectionResult> detectFace(Uint8List imageBytes) async {
    return FaceDetectionResult(faceDetected: false);
  }

  Future<FaceEncodingResult> encodeFace(Uint8List imageBytes) async {
    return FaceEncodingResult(
      success: false,
      error: 'TFLite indisponible sur le navigateur (utilisez Android/iOS/Desktop ou le serveur)',
    );
  }
}
