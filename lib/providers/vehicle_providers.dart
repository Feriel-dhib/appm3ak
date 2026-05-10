import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/geolocation_utils.dart';
import '../data/models/driver_nearby.dart';
import '../data/models/vehicle.dart';
import 'api_providers.dart';
import 'auth_providers.dart';

/// Provider pour la liste des véhicules d'un propriétaire.
final myVehiclesProvider = FutureProvider.family<List<Vehicle>, String>(
  (ref, ownerId) async {
    final repository = ref.watch(vehicleRepositoryProvider);
    return repository.findByOwner(ownerId);
  },
);

/// Provider pour un véhicule spécifique.
final vehicleProvider = FutureProvider.family<Vehicle, String>(
  (ref, vehicleId) async {
    final repository = ref.watch(vehicleRepositoryProvider);
    return repository.findOne(vehicleId);
  },
);

/// Provider pour la liste paginée des véhicules.
/// Utilise keepAlive pour conserver les données en cache et éviter les rechargements.
final vehiclesListProvider = FutureProvider.family<
    VehicleListResponse,
    VehiclesListParams>((ref, params) async {
  // Garde le provider en vie pour éviter les rechargements inutiles
  ref.keepAlive();
  
  final repository = ref.watch(vehicleRepositoryProvider);
  
  try {
    return await repository.findAll(
      ownerId: params.ownerId,
      statut: params.statut,
      page: params.page,
      limit: params.limit,
      nearLatitude: params.nearLatitude,
      nearLongitude: params.nearLongitude,
      maxDistanceKm: params.maxDistanceKm,
    );
  } catch (e) {
    // En cas d'erreur, on relance l'exception pour que l'UI puisse l'afficher
    rethrow;
  }
});

/// Paramètres pour la liste paginée.
class VehiclesListParams {
  const VehiclesListParams({
    this.ownerId,
    this.statut,
    this.page = 1,
    this.limit = 20,
    this.nearLatitude,
    this.nearLongitude,
    this.maxDistanceKm,
  });

  final String? ownerId;
  final String? statut;
  final int page;
  final int limit;
  final double? nearLatitude;
  final double? nearLongitude;
  /// Rayon km (défaut API 10 si lat/lon fournis sans cette clé).
  final double? maxDistanceKm;

  VehiclesListParams copyWith({
    String? ownerId,
    String? statut,
    int? page,
    int? limit,
    double? nearLatitude,
    double? nearLongitude,
    double? maxDistanceKm,
  }) {
    return VehiclesListParams(
      ownerId: ownerId ?? this.ownerId,
      statut: statut ?? this.statut,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      nearLatitude: nearLatitude ?? this.nearLatitude,
      nearLongitude: nearLongitude ?? this.nearLongitude,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VehiclesListParams &&
        other.ownerId == ownerId &&
        other.statut == statut &&
        other.page == page &&
        other.limit == limit &&
        other.nearLatitude == nearLatitude &&
        other.nearLongitude == nearLongitude &&
        other.maxDistanceKm == maxDistanceKm;
  }

  @override
  int get hashCode {
    return Object.hash(
      ownerId,
      statut,
      page,
      limit,
      nearLatitude,
      nearLongitude,
      maxDistanceKm,
    );
  }
}

/// Chauffeurs à proximité : véhicules VALIDE dont le propriétaire est à ≤ 10 km (bénéficiaire).
final driversNearbyProvider = FutureProvider<List<DriverNearby>>((ref) async {
  ref.keepAlive();
  final user = ref.watch(authStateProvider).valueOrNull;
  final repo = ref.read(vehicleRepositoryProvider);

  if (user?.isBeneficiary != true) {
    final response = await repo.findAll(
      statut: 'VALIDE',
      page: 1,
      limit: 20,
    );
    return response.data.map(DriverNearby.fromVehicle).toList();
  }

  double? lat;
  double? lon;
  try {
    final pos = await resolveUserPosition(
      timeLimit: const Duration(seconds: 12),
    );
    final adj = preferTunisiaProfileWhenGpsMismatch(
      gpsLat: pos.latitude,
      gpsLon: pos.longitude,
      profileLat: user?.latitude,
      profileLon: user?.longitude,
    );
    lat = adj.lat;
    lon = adj.lon;
  } on GeolocationError catch (_) {
    final fb = profileCoordinatesFallback(user?.latitude, user?.longitude);
    lat = fb?.lat;
    lon = fb?.lon;
  } catch (_) {
    final fb = profileCoordinatesFallback(user?.latitude, user?.longitude);
    lat = fb?.lat;
    lon = fb?.lon;
  }

  if (lat == null || lon == null) {
    return [];
  }

  final response = await repo.findAll(
    statut: 'VALIDE',
    page: 1,
    limit: 50,
    nearLatitude: lat,
    nearLongitude: lon,
    maxDistanceKm: 10,
  );
  return response.data.map(DriverNearby.fromVehicle).toList();
});
