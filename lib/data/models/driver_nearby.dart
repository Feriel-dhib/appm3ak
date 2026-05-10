import 'package:equatable/equatable.dart';

import 'vehicle.dart';

/// Représente un chauffeur à proximité (véhicule validé + propriétaire).
/// Construit à partir de [Vehicle] (avec owner éventuellement populé).
class DriverNearby extends Equatable {
  const DriverNearby({
    required this.vehicleId,
    required this.driverId,
    required this.driverName,
    required this.vehicleName,
    this.rating = 0.0,
    this.fare,
    this.waitMinutes,
    this.photoUrl,
    required this.accessibiliteRampe,
    required this.accessibiliteAssistance,
    required this.accessibiliteChienGuide,
  });

  final String vehicleId;
  final String driverId;
  final String driverName;
  final String vehicleName;
  final double rating;
  final String? fare;
  final int? waitMinutes;
  final String? photoUrl;
  final bool accessibiliteRampe;
  final bool accessibiliteAssistance;
  final bool accessibiliteChienGuide;

  /// Construit à partir d'un véhicule (et son propriétaire si populé).
  static DriverNearby fromVehicle(Vehicle v) {
    final owner = v.owner;
    final name = owner != null
        ? '${owner.prenom} ${owner.nom}'.trim()
        : 'Chauffeur';
    final rampe = v.accessibilite.rampeAcces;
    final assistance = v.accessibilite.siegePivotant;
    final chienGuide = v.accessibilite.animalAccepte;
    return DriverNearby(
      vehicleId: v.id,
      driverId: v.ownerId,
      driverName: name.isNotEmpty ? name : 'Chauffeur',
      vehicleName: v.displayName,
      rating: owner?.noteMoyenne ?? 0.0,
      fare: null,
      waitMinutes: null,
      photoUrl: owner?.photoProfil,
      accessibiliteRampe: rampe,
      accessibiliteAssistance: assistance,
      accessibiliteChienGuide: chienGuide,
    );
  }

  @override
  List<Object?> get props => [vehicleId, driverId];
}
