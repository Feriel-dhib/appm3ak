import 'dart:typed_data';
import 'dart:math' as math;

import '../config/detection_config.dart';
import '../models/detection_result.dart';

/// Résultat sérialisable renvoyé par l'isolate (pour SendPort).
class InferenceOutput {
  const InferenceOutput({
    required this.detections,
    this.error,
  });

  final List<DetectionResultSerialized> detections;
  final String? error;
}

/// Détection sérialisée (SendPort ne peut pas envoyer des objets avec enum directement).
class DetectionResultSerialized {
  const DetectionResultSerialized({
    required this.label,
    required this.confidence,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.distanceMeters,
    required this.riskLevelIndex,
    required this.zoneIndex,
  });

  final String label;
  final double confidence;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double distanceMeters;
  final int riskLevelIndex;
  final int zoneIndex;

  DetectionResult toDetectionResult() {
    return DetectionResult(
      label: label,
      confidence: confidence,
      boundingBox: BBoxNorm(left: left, top: top, right: right, bottom: bottom),
      distanceMeters: distanceMeters,
      riskLevel: RiskLevel.values[riskLevelIndex],
      zone: HorizontalZone.values[zoneIndex],
    );
  }
}

/// Parse le tenseur de sortie YOLOv8 et retourne les détections.
/// Supporte [1, 84, N] et [1, N, 84] ; **N = 2100** (imgsz 320) ou **8400** (imgsz 640).
List<DetectionResultSerialized> parseYoloOutput(
  List<double> outputTensor, {
  int? numPredictions,
}) {
  final raw = _parseOutput(outputTensor, numPredictions: numPredictions);
  final filtered = _filterWalkingZone(raw);
  final withDistance = _estimateDistance(filtered);
  final nms = _nms(withDistance, DetectionConfig.iouThreshold);
  return nms.map(_toSerialized).toList();
}

/// Convertit RGB (Uint8List) en structure 4D [1, H, W, 3] pour TFLite.
/// Le modèle attend une entrée 4D ; un Float32List plat est interprété comme 1D.
List<List<List<List<double>>>> preprocessRgbToFloat32_4D(Uint8List rgbBytes) {
  final w = DetectionConfig.inputWidth;
  final h = DetectionConfig.inputHeight;
  final input = List.generate(
    1,
    (_) => List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          final idx = (y * w + x) * 3;
          return [
            rgbBytes[idx] / 255.0,
            rgbBytes[idx + 1] / 255.0,
            rgbBytes[idx + 2] / 255.0,
          ];
        },
      ),
    ),
  );
  return input;
}

/// Convertit RGB (Uint8List) en structure 4D [1, H, W, 3] uint8.
List<List<List<List<int>>>> preprocessRgbToUint8_4D(Uint8List rgbBytes) {
  final w = DetectionConfig.inputWidth;
  final h = DetectionConfig.inputHeight;
  final input = List.generate(
    1,
    (_) => List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          final idx = (y * w + x) * 3;
          return [
            rgbBytes[idx],
            rgbBytes[idx + 1],
            rgbBytes[idx + 2],
          ];
        },
      ),
    ),
  );
  return input;
}

/// Convertit RGB (Uint8List) en structure 4D [1, H, W, 3] int8.
List<List<List<List<int>>>> preprocessRgbToInt8_4D(Uint8List rgbBytes) {
  final w = DetectionConfig.inputWidth;
  final h = DetectionConfig.inputHeight;
  final input = List.generate(
    1,
    (_) => List.generate(
      h,
      (y) => List.generate(
        w,
        (x) {
          final idx = (y * w + x) * 3;
          return [
            rgbBytes[idx] - 128,
            rgbBytes[idx + 1] - 128,
            rgbBytes[idx + 2] - 128,
          ];
        },
      ),
    ),
  );
  return input;
}

/// Ancienne version : Float32List plat (peut causer erreur PAD sur certains modèles).
@Deprecated('Utiliser preprocessRgbToFloat32_4D pour compatibilité TFLite')
Float32List preprocessRgbToFloat32(Uint8List rgbBytes) {
  final w = DetectionConfig.inputWidth;
  final h = DetectionConfig.inputHeight;
  final size = 1 * w * h * 3;
  final inputTensor = Float32List(size);
  for (var i = 0; i < size; i++) {
    inputTensor[i] = rgbBytes[i] / 255.0;
  }
  return inputTensor;
}

class _RawDet {
  int classIndex;
  double confidence;
  double xCenter;
  double yCenter;
  double width;
  double height;

  _RawDet({
    required this.classIndex,
    required this.confidence,
    required this.xCenter,
    required this.yCenter,
    required this.width,
    required this.height,
  });
}

List<_RawDet> _parseOutput(List<double> output, {int? numPredictions}) {
  final inferred = output.length ~/ 84;
  final n = numPredictions ?? inferred;
  // Essayer layout (1, 84, 8400) puis (1, 8400, 84) si aucun résultat
  final list = _parseOutputLayout84x8400(output, n);
  if (list.isNotEmpty) return list;
  return _parseOutputLayout8400x84(output, n);
}

/// Layout : (1, 84, numAnchors) — vecteur par dimension puis par ancre.
List<_RawDet> _parseOutputLayout84x8400(List<double> output, int numAnchors) {
  final list = <_RawDet>[];
  for (var i = 0; i < numAnchors; i++) {
    final x = _normalizeCoord(output[0 * numAnchors + i], DetectionConfig.inputWidth);
    final y = _normalizeCoord(output[1 * numAnchors + i], DetectionConfig.inputHeight);
    final w = _normalizeSize(output[2 * numAnchors + i], DetectionConfig.inputWidth);
    final h = _normalizeSize(output[3 * numAnchors + i], DetectionConfig.inputHeight);
    var maxScore = 0.0;
    var maxClass = 0;
    for (var c = 0; c < 80; c++) {
      final score = _toProbability(output[(4 + c) * numAnchors + i]);
      if (score > maxScore) {
        maxScore = score;
        maxClass = c;
      }
    }
    if (maxScore < DetectionConfig.confidenceThreshold) continue;
    if (!DetectionConfig.detectAllCoco80 &&
        !DetectionConfig.obstacleClassIndices.contains(maxClass)) {
      continue;
    }
    if (!_isValidBbox(x, y, w, h)) continue;
    list.add(_RawDet(
      classIndex: maxClass,
      confidence: maxScore,
      xCenter: x,
      yCenter: y,
      width: w,
      height: h,
    ));
  }
  return list;
}

/// Layout transposé : (1, numAnchors, 84) -> [anchor][dim]
List<_RawDet> _parseOutputLayout8400x84(List<double> output, int numAnchors) {
  const numBoxAndClass = 84;
  final list = <_RawDet>[];
  for (var i = 0; i < numAnchors; i++) {
    final base = i * numBoxAndClass;
    final x = _normalizeCoord(output[base + 0], DetectionConfig.inputWidth);
    final y = _normalizeCoord(output[base + 1], DetectionConfig.inputHeight);
    final w = _normalizeSize(output[base + 2], DetectionConfig.inputWidth);
    final h = _normalizeSize(output[base + 3], DetectionConfig.inputHeight);
    var maxScore = 0.0;
    var maxClass = 0;
    for (var c = 0; c < 80; c++) {
      final score = _toProbability(output[base + 4 + c]);
      if (score > maxScore) {
        maxScore = score;
        maxClass = c;
      }
    }
    if (maxScore < DetectionConfig.confidenceThreshold) continue;
    if (!DetectionConfig.detectAllCoco80 &&
        !DetectionConfig.obstacleClassIndices.contains(maxClass)) {
      continue;
    }
    if (!_isValidBbox(x, y, w, h)) continue;
    list.add(_RawDet(
      classIndex: maxClass,
      confidence: maxScore,
      xCenter: x,
      yCenter: y,
      width: w,
      height: h,
    ));
  }
  return list;
}

bool _isValidBbox(double x, double y, double w, double h) {
  final area = w * h;
  final ratio = w > h ? (w / h) : (h / w);
  final minA = DetectionConfig.minBoxAreaFraction;
  return x.isFinite &&
      y.isFinite &&
      w.isFinite &&
      h.isFinite &&
      w > 0 &&
      h > 0 &&
      w <= 1.0 &&
      h <= 1.0 &&
      area >= minA &&
      area <= 0.95 &&
      ratio <= 8.0;
}

double _normalizeCoord(double value, int inputSize) {
  if (!value.isFinite) return value;
  // Certains exports renvoient des coordonnées en pixels [0..inputSize].
  if (value > 1.5) return value / inputSize;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

double _normalizeSize(double value, int inputSize) {
  if (!value.isFinite) return value;
  if (value > 1.5) return value / inputSize;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

double _toProbability(double rawScore) {
  // Si déjà en [0,1], on garde ; sinon on applique sigmoid (logits).
  if (rawScore >= 0 && rawScore <= 1) return rawScore;
  return 1.0 / (1.0 + math.exp(-rawScore));
}

List<_RawDet> _filterWalkingZone(List<_RawDet> list) {
  return list.where((d) => d.yCenter >= DetectionConfig.walkingZoneYMin).toList();
}

class _DetWithDistance {
  _RawDet det;
  double distanceMeters;
  String label;
  RiskLevel riskLevel;
  HorizontalZone zone;

  _DetWithDistance({
    required this.det,
    required this.distanceMeters,
    required this.label,
    required this.riskLevel,
    required this.zone,
  });
}

List<_DetWithDistance> _estimateDistance(List<_RawDet> list) {
  final hNorm = DetectionConfig.inputHeight.toDouble();
  final focal = DetectionConfig.focalLengthApprox;
  final result = <_DetWithDistance>[];
  for (final d in list) {
    final label = DetectionConfig.labelForCocoIndex(d.classIndex);
    final realH = DetectionConfig.getObjectHeightMeters(label);
    final heightPx = d.height * hNorm;
    if (heightPx <= 0) continue;
    final dist = (realH * focal) / heightPx;
    RiskLevel level = RiskLevel.safe;
    if (dist <= DetectionConfig.distanceCriticalMeters) level = RiskLevel.critical;
    else if (dist <= DetectionConfig.distanceWarningMeters) level = RiskLevel.warning;
    final zone = horizontalZoneFromCenterX(d.xCenter);
    result.add(_DetWithDistance(
      det: d,
      distanceMeters: dist,
      label: label,
      riskLevel: level,
      zone: zone,
    ));
  }
  return result;
}

List<_DetWithDistance> _nms(List<_DetWithDistance> list, double iouThreshold) {
  if (list.isEmpty) return [];
  final sorted = List<_DetWithDistance>.from(list)
    ..sort((a, b) => b.det.confidence.compareTo(a.det.confidence));
  final kept = <_DetWithDistance>[];
  for (final cand in sorted) {
    var overlap = false;
    for (final k in kept) {
      if (_iou(cand.det, k.det) > iouThreshold) {
        overlap = true;
        break;
      }
    }
    if (!overlap) kept.add(cand);
  }
  return kept;
}

double _iou(_RawDet a, _RawDet b) {
  final ax1 = a.xCenter - a.width / 2;
  final ay1 = a.yCenter - a.height / 2;
  final ax2 = a.xCenter + a.width / 2;
  final ay2 = a.yCenter + a.height / 2;
  final bx1 = b.xCenter - b.width / 2;
  final by1 = b.yCenter - b.height / 2;
  final bx2 = b.xCenter + b.width / 2;
  final by2 = b.yCenter + b.height / 2;
  final ix1 = ax1 > bx1 ? ax1 : bx1;
  final iy1 = ay1 > by1 ? ay1 : by1;
  final ix2 = ax2 < bx2 ? ax2 : bx2;
  final iy2 = ay2 < by2 ? ay2 : by2;
  final iw = ix2 - ix1;
  final ih = iy2 - iy1;
  if (iw <= 0 || ih <= 0) return 0;
  final inter = iw * ih;
  final areaA = a.width * a.height;
  final areaB = b.width * b.height;
  return inter / (areaA + areaB - inter);
}

DetectionResultSerialized _toSerialized(_DetWithDistance d) {
  final det = d.det;
  final left = (det.xCenter - det.width / 2).clamp(0.0, 1.0);
  final top = (det.yCenter - det.height / 2).clamp(0.0, 1.0);
  final right = (det.xCenter + det.width / 2).clamp(0.0, 1.0);
  final bottom = (det.yCenter + det.height / 2).clamp(0.0, 1.0);
  return DetectionResultSerialized(
    label: d.label,
    confidence: det.confidence,
    left: left,
    top: top,
    right: right,
    bottom: bottom,
    distanceMeters: d.distanceMeters,
    riskLevelIndex: d.riskLevel.index,
    zoneIndex: d.zone.index,
  );
}
