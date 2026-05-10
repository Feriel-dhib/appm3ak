import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/models/map/route_result.dart';

/// Carte OpenStreetMap réutilisable (départ, destination, itinéraire).
class Ma3akMapWidget extends StatelessWidget {
  const Ma3akMapWidget({
    super.key,
    required this.initialCenter,
    this.initialZoom = 13,
    this.origin,
    this.destination,
    this.routeResult,
    this.height = 220,
    this.onTap,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final LatLng? origin;
  final LatLng? destination;
  final RouteResult? routeResult;
  final double height;
  final void Function(LatLng point)? onTap;

  @override
  Widget build(BuildContext context) {
    final routePoints = routeResult?.geometry.toLatLngList() ?? <LatLng>[];
    final allPoints = <LatLng>[
      if (origin != null) origin!,
      if (destination != null) destination!,
      ...routePoints,
    ];
    final bounds = allPoints.isNotEmpty ? _boundsFromPoints(allPoints) : null;

    return SizedBox(
      height: height,
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: FlutterMap(
          options: MapOptions(
            initialCenter: bounds != null ? _centerOfBounds(bounds) : initialCenter,
            initialZoom: bounds != null ? _zoomForBounds(bounds, context) : initialZoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.flingAnimation,
            ),
            onTap: onTap != null ? (_, point) => onTap!(point) : null,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tn.ma3ak.app',
            ),
            if (routePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 4,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (origin != null)
                  Marker(
                    point: origin!,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.trip_origin, color: Colors.green, size: 36),
                  ),
                if (destination != null)
                  Marker(
                    point: destination!,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_on, color: Colors.red, size: 36),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLon = points.first.longitude, maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return LatLngBounds(
      LatLng(minLat, minLon),
      LatLng(maxLat, maxLon),
    );
  }

  LatLng _centerOfBounds(LatLngBounds bounds) {
    return LatLng(
      (bounds.north + bounds.south) / 2,
      (bounds.east + bounds.west) / 2,
    );
  }

  double _zoomForBounds(LatLngBounds bounds, BuildContext context) {
    final latSpan = bounds.north - bounds.south;
    final lonSpan = bounds.east - bounds.west;
    if (latSpan <= 0 && lonSpan <= 0) return initialZoom;
    final span = latSpan > lonSpan ? latSpan : lonSpan;
    if (span < 0.001) return 16;
    if (span < 0.01) return 14;
    if (span < 0.05) return 12;
    if (span < 0.2) return 10;
    return 8;
  }
}
