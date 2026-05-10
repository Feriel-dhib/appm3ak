import 'dart:math';

/// Analyse mouvement type accéléromètre (choc / secousse).
/// Remplaceable plus tard par pipeline ML sur série temporelle.
class SafetyMotionAnalyzer {
  SafetyMotionAnalyzer();

  double? _lastMag;
  DateTime? _lastImpact;

  /// À appeler pour chaque échantillon accéléromètre (m/s²).
  /// Retourne un score ponctuel 0–100.
  int onAccelerometer(double x, double y, double z) {
    final mag = sqrt(x * x + y * y + z * z);
    var score = 0;

    if (mag > 22) {
      score = 90;
      _lastImpact = DateTime.now();
    } else if (_lastMag != null) {
      final delta = (mag - _lastMag!).abs();
      if (delta > 14) score = 55;
    }
    _lastMag = mag;

    if (_lastImpact != null) {
      final ago = DateTime.now().difference(_lastImpact!);
      if (ago.inSeconds < 8) score = max(score, 85);
    }

    return min(100, score);
  }

  void reset() {
    _lastMag = null;
    _lastImpact = null;
  }

  String get lastImpactHintFr =>
      'Choc ou secousse forte récente — possible chute ou mouvement brutal.';
}
