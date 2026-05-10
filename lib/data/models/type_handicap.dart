/// Types de handicap reconnus par le backend.
/// Ces valeurs sont envoyées telles quelles à l'API (en français).
enum TypeHandicap {
  moteur('Handicap moteur'),
  visuel('Handicap visuel'),
  auditif('Handicap auditif');

  const TypeHandicap(this.backendValue);

  /// Valeur envoyée au backend (toujours en français).
  final String backendValue;

  /// Retourne le TypeHandicap correspondant à une valeur backend,
  /// ou null si invalide.
  static TypeHandicap? fromBackendValue(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final t in TypeHandicap.values) {
      if (t.backendValue == value) return t;
    }
    return null;
  }

  /// Profil utilisateur / API hétérogènes (camelCase, texte libre).
  static TypeHandicap? fromApiString(String? value) {
    final direct = fromBackendValue(value);
    if (direct != null) return direct;
    if (value == null || value.isEmpty) return null;
    final v = value.toLowerCase();
    if (v.contains('visuel') || v.contains('malvoy') || v.contains('aveugle')) {
      return TypeHandicap.visuel;
    }
    if (v.contains('auditif')) return TypeHandicap.auditif;
    if (v.contains('moteur') || v.contains('mobil')) return TypeHandicap.moteur;
    return null;
  }
}
