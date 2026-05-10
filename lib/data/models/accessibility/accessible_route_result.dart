import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

/// Résultat d'un calcul d'itinéraire accessible.
///
/// Source principale : `POST /accessibility/accessible_route_full`
/// (graphe A* pondéré par les scores d'accessibilité des nœuds OSM).
class AccessibleRouteResult extends Equatable {
  const AccessibleRouteResult._({
    this.coordinates = const [],
    this.bestPath = const [],
    this.accessibilityScore = 0,
    this.distanceMeters = 0,
    this.durationSeconds = 0,
    this.errorMessage,
  });

  /// Tracé géographique (points WGS84) ordonné du départ vers l'arrivée.
  final List<LatLng> coordinates;

  /// Liste des IDs de nœuds OSM traversés (peut être vide sur fallback).
  final List<int> bestPath;

  /// Score moyen d'accessibilité du trajet (0.0 → 1.0).
  final double accessibilityScore;

  /// Distance totale du tracé en mètres.
  final double distanceMeters;

  /// Durée estimée (pédestre) en secondes.
  final double durationSeconds;

  /// Message d'erreur lisible pour l'UI (null si succès).
  final String? errorMessage;

  bool get isSuccess => errorMessage == null && coordinates.length >= 2;

  factory AccessibleRouteResult.success({
    required List<LatLng> coordinates,
    required List<int> bestPath,
    required double accessibilityScore,
    double distanceMeters = 0,
    double durationSeconds = 0,
  }) =>
      AccessibleRouteResult._(
        coordinates: coordinates,
        bestPath: bestPath,
        accessibilityScore: accessibilityScore,
        distanceMeters: distanceMeters,
        durationSeconds: durationSeconds,
      );

  factory AccessibleRouteResult.failure(String message) =>
      AccessibleRouteResult._(errorMessage: message);

  @override
  List<Object?> get props => [
        coordinates,
        bestPath,
        accessibilityScore,
        distanceMeters,
        durationSeconds,
        errorMessage,
      ];
}
