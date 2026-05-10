import 'dart:math' as math;

import '../hand_tracker.dart';

/// Détecte le geste « index tendu, autres doigts repliés ».
///
/// Comparaison **géométrique** (distance au poignet) plutôt que sur l’axe Y seul,
/// pour rester fiable quand la main est penchée ou que le téléphone est pivoté.
class GestureService {
  const GestureService();

  static const double _marginScale = 0.06;

  bool isWritingGesture(HandDetectionResult result, {required double imageHeight}) {
    if (result.landmarks.length < 21 || imageHeight <= 0) return false;
    final w = result.landmarks[0];
    final scale = _handScale(result);
    if (scale <= 1e-6) return false;
    final margin = _marginScale * scale;
    final indexExtended = _isFingerExtended(result, tip: 8, pip: 6, wrist: w, margin: margin);
    final middleFolded = _isFingerFolded(result, tip: 12, pip: 10, wrist: w, margin: margin);
    final ringFolded = _isFingerFolded(result, tip: 16, pip: 14, wrist: w, margin: margin);
    final pinkyFolded = _isFingerFolded(result, tip: 20, pip: 18, wrist: w, margin: margin);
    return indexExtended && middleFolded && ringFolded && pinkyFolded;
  }

  double _handScale(HandDetectionResult result) {
    final w = result.landmarks[0];
    double m = 0;
    for (final i in <int>[5, 9, 13, 17]) {
      final d = _dist2(w, result.landmarks[i]);
      if (d > m) m = d;
    }
    return math.sqrt(m);
  }

  double _dist2(HandLandmark a, HandLandmark b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  bool _isFingerExtended(
    HandDetectionResult result, {
    required int tip,
    required int pip,
    required HandLandmark wrist,
    required double margin,
  }) {
    final dTip = math.sqrt(_dist2(wrist, result.landmarks[tip]));
    final dPip = math.sqrt(_dist2(wrist, result.landmarks[pip]));
    return dTip > dPip + margin * 0.35;
  }

  bool _isFingerFolded(
    HandDetectionResult result, {
    required int tip,
    required int pip,
    required HandLandmark wrist,
    required double margin,
  }) {
    final dTip = math.sqrt(_dist2(wrist, result.landmarks[tip]));
    final dPip = math.sqrt(_dist2(wrist, result.landmarks[pip]));
    return dTip <= dPip + margin * 0.55;
  }
}
