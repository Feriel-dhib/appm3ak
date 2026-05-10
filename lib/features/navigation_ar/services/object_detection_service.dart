import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../models/detected_obstacle.dart';

/// Service de détection d'obstacles en temps réel (personnes, voitures, etc.)
/// via Google ML Kit. Tourne sur l'appareil.
class ObjectDetectionService {
  ObjectDetectionService() {
    _detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      ),
    );
  }

  late final ObjectDetector _detector;

  static const double _minConfidence = 0.5;

  /// Labels d'obstacles pertinents pour la navigation (ML Kit / COCO).
  static const Set<String> _obstacleLabels = {
    'person',
    'car',
    'truck',
    'bus',
    'bicycle',
    'motorcycle',
  };

  /// Détecte les obstacles dans une image [InputImage].
  /// Retourne une liste d'obstacles avec label et bounding box.
  Future<List<DetectedObstacle>> processImage(InputImage inputImage) async {
    try {
      final results = await _detector.processImage(inputImage);
      final list = <DetectedObstacle>[];
      for (final d in results) {
        final label = (d.labels.isNotEmpty ? d.labels.first.text : 'object')
            .toLowerCase();
        final confidence = d.labels.isNotEmpty ? d.labels.first.confidence : 0.0;
        if (confidence < _minConfidence) continue;
        if (!_obstacleLabels.contains(label)) continue;
        final b = d.boundingBox;
        list.add(DetectedObstacle(
          label: _mapLabel(label),
          confidence: confidence,
          boundingBox: RectNorm(
            left: b.left / (inputImage.metadata?.size.width ?? 1),
            top: b.top / (inputImage.metadata?.size.height ?? 1),
            right: b.right / (inputImage.metadata?.size.width ?? 1),
            bottom: b.bottom / (inputImage.metadata?.size.height ?? 1),
          ),
          trackingId: d.trackingId,
        ));
      }
      return list;
    } catch (e) {
      return [];
    }
  }

  String _mapLabel(String raw) {
    switch (raw) {
      case 'person':
        return 'person';
      case 'car':
      case 'truck':
      case 'bus':
        return 'car';
      case 'bicycle':
      case 'motorcycle':
        return 'bicycle';
      default:
        return 'obstacle';
    }
  }

  void dispose() {
    _detector.close();
  }
}
