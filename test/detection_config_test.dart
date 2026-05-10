import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:appm3ak/features/detection/config/detection_config.dart';
import 'package:appm3ak/features/detection/models/detection_result.dart';
import 'package:appm3ak/features/detection/services/yolo_tflite_runner.dart';

void main() {
  group('DetectionConfig', () {
    test('obstacle class indices contain expected COCO indices', () {
      expect(DetectionConfig.obstacleClassIndices, contains(0)); // person
      expect(DetectionConfig.obstacleClassIndices, contains(56)); // chair
      expect(DetectionConfig.obstacleClassIndices, contains(39)); // bottle
      expect(DetectionConfig.obstacleClassIndices, contains(73)); // book
      expect(DetectionConfig.obstacleClassIndices, contains(63)); // laptop
    });

    test('COCO label for laptop matches official name', () {
      expect(DetectionConfig.labelForCocoIndex(63), 'laptop');
    });

    test('object heights return default for unknown label', () {
      expect(DetectionConfig.getObjectHeightMeters('person'), 1.7);
      expect(DetectionConfig.getObjectHeightMeters('unknown'), 1.0);
    });

    test('alert messages FR/AR exist for known labels', () {
      expect(DetectionConfig.getAlertMessageFr('person', RiskLevel.critical),
          contains('Personne'));
      expect(DetectionConfig.getAlertMessageFr('chair', RiskLevel.warning),
          contains('Chaise'));
      expect(DetectionConfig.getAlertMessageAr('person', RiskLevel.warning),
          isNotEmpty);
    });
  });

  group('parseYoloOutput', () {
    test('empty tensor returns empty list', () {
      final out = List.filled(1 * 84 * DetectionConfig.numPredictions, 0.0);
      expect(parseYoloOutput(out), isEmpty);
    });

    test('preprocessRgbToFloat32 produces 320*320*3 floats 0-1', () {
      final rgb = List.generate(320 * 320 * 3, (i) => 255).cast<int>();
      final floats = preprocessRgbToFloat32(Uint8List.fromList(rgb));
      expect(floats.length, 1 * 320 * 320 * 3);
      expect(floats[0], 1.0);
    });
  });

  group('DetectionResultSerialized', () {
    test('toDetectionResult maps correctly', () {
      const s = DetectionResultSerialized(
        label: 'person',
        confidence: 0.9,
        left: 0.1,
        top: 0.2,
        right: 0.3,
        bottom: 0.5,
        distanceMeters: 2.5,
        riskLevelIndex: 1,
        zoneIndex: 1,
      );
      final r = s.toDetectionResult();
      expect(r.label, 'person');
      expect(r.confidence, 0.9);
      expect(r.distanceMeters, 2.5);
      expect(r.riskLevel, RiskLevel.warning);
      expect(r.zone, HorizontalZone.center);
    });
  });
}
