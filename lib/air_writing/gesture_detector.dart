import 'hand_tracker.dart';

/// Detecte si la main est en mode "ecriture aerienne".
class GestureDetector {
  const GestureDetector();

  /// Regle: index tendu + majeur/annulaire/auriculaire replies.
  bool isWritingGesture(HandDetectionResult result) {
    if (result.landmarks.length < 21) {
      return false;
    }

    final bool indexExtended = _isFingerExtended(result, tip: 8, pip: 6);
    final bool middleFolded = _isFingerFolded(result, tip: 12, pip: 10);
    final bool ringFolded = _isFingerFolded(result, tip: 16, pip: 14);
    final bool pinkyFolded = _isFingerFolded(result, tip: 20, pip: 18);
    return indexExtended && middleFolded && ringFolded && pinkyFolded;
  }

  bool _isFingerExtended(HandDetectionResult result, {required int tip, required int pip}) {
    return result.landmarks[tip].y < result.landmarks[pip].y;
  }

  bool _isFingerFolded(HandDetectionResult result, {required int tip, required int pip}) {
    return result.landmarks[tip].y >= result.landmarks[pip].y;
  }
}
