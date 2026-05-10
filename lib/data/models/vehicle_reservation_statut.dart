/// Statut d'une réservation de véhicule.
enum VehicleReservationStatut {
  enAttente,
  confirmee,
  annulee,
  terminee;

  static VehicleReservationStatut? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    for (final s in VehicleReservationStatut.values) {
      if (s.toApiString() == v) return s;
    }
    return null;
  }

  String toApiString() {
    switch (this) {
      case VehicleReservationStatut.enAttente:
        return 'EN_ATTENTE';
      case VehicleReservationStatut.confirmee:
        return 'CONFIRMEE';
      case VehicleReservationStatut.annulee:
        return 'ANNULEE';
      case VehicleReservationStatut.terminee:
        return 'TERMINEE';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleReservationStatut.enAttente:
        return 'En attente';
      case VehicleReservationStatut.confirmee:
        return 'Confirmée';
      case VehicleReservationStatut.annulee:
        return 'Annulée';
      case VehicleReservationStatut.terminee:
        return 'Terminée';
    }
  }
}
