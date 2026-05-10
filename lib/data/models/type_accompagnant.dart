/// Types d'accompagnant reconnus par le backend.
/// Ces valeurs sont envoyées telles quelles à l'API (en français).
enum TypeAccompagnant {
  membresFamille('Membres de la famille'),
  aidesSoignants('Aides-soignants'),
  benevoles('Bénévoles'),
  chauffeursSolidaires('Chauffeurs solidaires');

  const TypeAccompagnant(this.backendValue);

  /// Valeur envoyée au backend (toujours en français).
  final String backendValue;

  /// Retourne le TypeAccompagnant correspondant à une valeur backend,
  /// ou null si invalide.
  static TypeAccompagnant? fromBackendValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in TypeAccompagnant.values) {
      if (t.backendValue == value) return t;
    }
    return null;
  }
}
