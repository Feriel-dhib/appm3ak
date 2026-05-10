import 'dart:math';

/// Analyse heuristique de texte (NLP léger) — pas un modèle cloud.
/// Détecte urgence, peur, fatigue, demande d’aide (FR + quelques EN).
class SafetyTextAnalyzer {
  const SafetyTextAnalyzer();

  static final _panic = <String>[
    'aidez-moi',
    'au secours',
    'urgence',
    'j\'ai peur',
    'j ai peur',
    'panique',
    'help me',
    'emergency',
    'je vais m\'évanouir',
    'je vais m evanouir',
    'je ne peux plus respirer',
    'douleur insupportable',
    'chute',
    'je suis tombé',
    'je suis tombe',
    'violence',
    'agression',
  ];

  static final _stress = <String>[
    'fatigué',
    'fatigue',
    'angoisse',
    'stress',
    'j\'ai mal',
    'j ai mal',
    'triste',
    'seul',
    'peur',
    'anxieux',
    'anxieuse',
    'scared',
    'tired',
    'afraid',
  ];

  static final _calm = <String>[
    'ça va',
    'ca va',
    'tranquille',
    'bien',
    'ok',
    'merci',
    'fine',
    'good',
  ];

  /// Retourne un score 0–100 (alerte).
  int analyze(String raw) {
    final q = raw.toLowerCase().trim();
    if (q.isEmpty) return 0;

    var score = 5;
    for (final w in _panic) {
      if (q.contains(w)) score += 45;
    }
    for (final w in _stress) {
      if (q.contains(w)) score += 18;
    }
    for (final w in _calm) {
      if (q.contains(w)) score -= 12;
    }
    if (q.contains('!')) score += 8;
    if (q.length > 80 && score > 30) score += 10;
    return max(0, min(100, score));
  }

  /// [raw] : texte utilisateur ; si vide, ne pas afficher « rassurant » (incohérent avec la voix).
  String summaryFr(int score, {String raw = ''}) {
    if (raw.trim().isEmpty) {
      return 'Aucun texte saisi — le bilan repose sur la voix, le mouvement et le lieu.';
    }
    if (score >= 75) {
      return 'Texte très préoccupant — mots d’urgence ou de détresse détectés.';
    }
    if (score >= 40) {
      return 'Signes de stress ou d’inconfort dans le message.';
    }
    if (score >= 15) {
      return 'Message neutre à légèrement négatif.';
    }
    return 'Message plutôt rassurant.';
  }
}
