import 'package:latlong2/latlong.dart';

/// Calculs pour le guidage sur une polyline (itinéraire backend / OSRM).
class RouteGuidanceUtils {
  RouteGuidanceUtils._();

  static const Distance _distance = Distance();

  static double bearing(LatLng from, LatLng to) => _distance.bearing(from, to);

  static double distanceMeters(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);

  /// Avance l’index tant que le point courant est atteint (rayon [arrivalM] m).
  static int advanceIndex(
    LatLng user,
    List<LatLng> polyline,
    int startIndex, {
    double arrivalM = 22,
  }) {
    if (polyline.isEmpty) return 0;
    var i = startIndex.clamp(0, polyline.length - 1);
    while (i < polyline.length - 1) {
      if (distanceMeters(user, polyline[i]) < arrivalM) {
        i++;
      } else {
        break;
      }
    }
    return i;
  }

  /// Point à viser : sommet courant de la polyline (ou dernier si fin).
  static LatLng? targetWaypoint(List<LatLng> polyline, int index) {
    if (polyline.isEmpty) return null;
    final i = index.clamp(0, polyline.length - 1);
    return polyline[i];
  }

  /// Normalise un angle différence en degrés dans ]-180, 180].
  static double deltaDegrees(double from, double to) {
    var d = to - from;
    while (d > 180) {
      d -= 360;
    }
    while (d < -180) {
      d += 360;
    }
    return d;
  }
}
