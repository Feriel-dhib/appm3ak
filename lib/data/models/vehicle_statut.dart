/// Statut d'un véhicule.
enum VehicleStatut {
  enAttente,
  valide,
  refuse;

  static VehicleStatut? fromString(String? value) {
    if (value == null) return null;
    final v = value.toUpperCase();
    for (final s in VehicleStatut.values) {
      if (s.toApiString() == v) return s;
    }
    return null;
  }

  String toApiString() {
    switch (this) {
      case VehicleStatut.enAttente:
        return 'EN_ATTENTE';
      case VehicleStatut.valide:
        return 'VALIDE';
      case VehicleStatut.refuse:
        return 'REFUSE';
    }
  }

  String get displayName {
    switch (this) {
      case VehicleStatut.enAttente:
        return 'En attente';
      case VehicleStatut.valide:
        return 'Validé';
      case VehicleStatut.refuse:
        return 'Refusé';
    }
  }
}
