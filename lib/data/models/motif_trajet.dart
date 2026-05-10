/// Motif de trajet (aligné backend `MotifTrajet`).
enum MotifTrajet {
  medical('MEDICAL'),
  administratif('ADMINISTRATIF'),
  quotidien('QUOTIDIEN'),
  loisir('LOISIR');

  const MotifTrajet(this.apiValue);

  final String apiValue;

  static MotifTrajet? fromApi(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final v = raw.toUpperCase().trim();
    for (final m in MotifTrajet.values) {
      if (m.apiValue == v) return m;
    }
    return null;
  }
}
