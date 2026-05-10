import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Géométrie de l'itinéraire (GeoJSON LineString : [lon, lat]).
class RouteGeometry extends Equatable {
  const RouteGeometry({
    required this.type,
    required this.coordinates,
  });

  factory RouteGeometry.fromJson(Map<String, dynamic> json) {
    final coords = json['coordinates'] as List<dynamic>?;
    final list = coords
        ?.map((e) => (e as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList())
        .toList();
    return RouteGeometry(
      type: json['type'] as String? ?? 'LineString',
      coordinates: list ?? [],
    );
  }

  final String type;
  /// GeoJSON: chaque élément est [longitude, latitude].
  final List<List<double>> coordinates;

  /// Pour flutter_map / polyline : liste de LatLng (lat, lon).
  List<LatLng> toLatLngList() => coordinates
      .map((c) => LatLng(c[1], c[0]))
      .toList();

  @override
  List<Object?> get props => [type, coordinates];
}

/// Résultat du calcul d'itinéraire (POST /map/route).
class RouteResult extends Equatable {
  const RouteResult({
    required this.distance,
    required this.duration,
    required this.geometry,
    required this.waypoints,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) {
    final waypointsRaw = json['waypoints'] as List<dynamic>?;
    final waypoints = waypointsRaw
        ?.map((e) {
          final m = e as Map<String, dynamic>;
          return LatLng(
            (m['lat'] as num).toDouble(),
            (m['lon'] as num).toDouble(),
          );
        })
        .toList() ?? [];
    return RouteResult(
      distance: (json['distance'] as num).toDouble(),
      duration: (json['duration'] as num).toDouble(),
      geometry: RouteGeometry.fromJson(
        json['geometry'] as Map<String, dynamic>? ?? {},
      ),
      waypoints: waypoints,
    );
  }

  /// Distance en mètres.
  final double distance;
  /// Durée en secondes.
  final double duration;
  final RouteGeometry geometry;
  final List<LatLng> waypoints;

  String get distanceFormatted {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toInt()} m';
  }

  String get durationFormatted {
    final minutes = (duration / 60).round();
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m > 0 ? '${h}h ${m}min' : '${h}h';
    }
    return '$minutes min';
  }

  @override
  List<Object?> get props => [distance, duration, geometry, waypoints];
}
