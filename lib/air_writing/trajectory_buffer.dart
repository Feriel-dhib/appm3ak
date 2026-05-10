import 'dart:ui';

/// Gere les points de trajectoire avec lissage et detection de pause.
class TrajectoryBuffer {
  TrajectoryBuffer({
    this.pauseThreshold = const Duration(milliseconds: 1500),
    this.smoothingWindow = 7,
    this.minDistancePx = 2.0,
    this.minPointsForInference = 15,
  });

  final Duration pauseThreshold;
  final int smoothingWindow;
  final double minDistancePx;
  final int minPointsForInference;

  final List<Offset> _rawPoints = <Offset>[];
  final List<Offset> _smoothedPoints = <Offset>[];
  final List<DateTime> _timestamps = <DateTime>[];

  DateTime? _lastPointAt;

  List<Offset> get points => List<Offset>.unmodifiable(_smoothedPoints);
  int get length => _smoothedPoints.length;
  bool get hasEnoughPoints => _smoothedPoints.length >= minPointsForInference;

  void reset() {
    _rawPoints.clear();
    _smoothedPoints.clear();
    _timestamps.clear();
    _lastPointAt = null;
  }

  /// Ajoute un point en appliquant un filtre anti-bruit et un lissage glissant.
  bool add(Offset point, {DateTime? timestamp}) {
    final DateTime ts = timestamp ?? DateTime.now();
    if (_smoothedPoints.isNotEmpty) {
      final Offset prev = _smoothedPoints.last;
      final double distance = (point - prev).distance;
      if (distance < minDistancePx) {
        return false;
      }
    }

    _rawPoints.add(point);
    _timestamps.add(ts);
    _lastPointAt = ts;
    _smoothedPoints.add(_computeMovingAverage());
    return true;
  }

  /// Retourne true si la pause depasse le seuil configure.
  bool detectPause({DateTime? now}) {
    if (_lastPointAt == null || _smoothedPoints.isEmpty) {
      return false;
    }
    final DateTime current = now ?? DateTime.now();
    final Duration elapsed = current.difference(_lastPointAt!);
    return elapsed >= pauseThreshold;
  }

  /// Retourne une progression [0..1] de la pause visuelle.
  double pauseProgress({DateTime? now}) {
    if (_lastPointAt == null || _smoothedPoints.isEmpty) {
      return 0.0;
    }
    final DateTime current = now ?? DateTime.now();
    final int elapsedMs = current.difference(_lastPointAt!).inMilliseconds;
    return (elapsedMs / pauseThreshold.inMilliseconds).clamp(0.0, 1.0);
  }

  Offset _computeMovingAverage() {
    final int start = (_rawPoints.length - smoothingWindow).clamp(0, _rawPoints.length);
    final List<Offset> window = _rawPoints.sublist(start);
    double sumX = 0.0;
    double sumY = 0.0;
    for (final Offset p in window) {
      sumX += p.dx;
      sumY += p.dy;
    }
    return Offset(sumX / window.length, sumY / window.length);
  }
}
