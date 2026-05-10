/// Analyse locale du texte (transcription vocale ou saisie) pour détecter
/// stress, peur ou danger — sans serveur. Complète les mots-clés SOS déjà
/// gérés côté assistant.
class VoiceSafetyAnalyzer {
  VoiceSafetyAnalyzer._();

  static final RegExp _calmShortMessage = RegExp(
    r"^(ça va|ca va|je vais bien|tout va bien|tranquille|calme|pas de stress|"
    r"i am ok|i'm fine|i am fine|feeling fine|all good|just testing)\.?!?\s*$",
    caseSensitive: false,
  );

  /// Retourne true si une alerte sécurité / appel proche doit être déclenchée.
  static bool isEmergency(String raw) {
    final q = raw.toLowerCase().trim();
    if (q.isEmpty) return false;
    if (_calmShortMessage.hasMatch(q.trim())) return false;

    var score = 0;
    if (_sosHeavy(q)) score += 100;
    score += _stressHits(q) * 18;
    score += _fearHits(q) * 16;
    if (_arabicDistress(q)) score += 40;
    if (_calmPhrasesInMessage(q)) score -= 35;
    return score >= 36;
  }

  static bool _sosHeavy(String q) {
    const keys = [
      'sos',
      'urgence',
      'urgent',
      'emergency',
      'douleur forte',
      'severe pain',
      "can't breathe",
      "can't breath",
      'cannot breathe',
      'inconscient',
      'unconscious',
      'saigne beaucoup',
      'bleeding heavily',
      'au secours',
      'help me',
      'save me',
      'call someone',
      'appelez',
      'appelez quelqu',
      'j\'ai besoin d\'aide',
      'j ai besoin d aide',
      'besoin d\'aide',
      'need help',
    ];
    if (keys.any(q.contains)) return true;
    if (q.contains('j\'ai mal') || q.contains('j ai mal')) {
      return q.contains('poitrine') ||
          q.contains('thorax') ||
          q.contains('chest') ||
          q.contains('souffle') ||
          q.contains('breath');
    }
    return false;
  }

  static int _stressHits(String q) {
    const keys = [
      'stress',
      'angoiss',
      'panique',
      'anxiété',
      'anxiete',
      'anxiety',
      'hyperventil',
      'étouffe',
      'etouffe',
      'suffocat',
      'crise',
      'terrif',
      'overwhelmed',
    ];
    return keys.where((k) => q.contains(k)).length;
  }

  static int _fearHits(String q) {
    const keys = [
      'peur',
      'j\'ai peur',
      'j ai peur',
      'peur de',
      'effray',
      'danger',
      'violence',
      'agress',
      'malaise',
      'je tombe',
      'je vais m\'évanouir',
      'évanouir',
      'evanouir',
      'scared',
      'fear',
      'afraid',
      'unsafe',
      'hurt me',
      'attacked',
    ];
    return keys.where((k) => q.contains(k)).length;
  }

  static bool _arabicDistress(String q) {
    const keys = [
      'خطر',
      'مساعدة',
      'ألم',
      'وجع',
      'خوف',
      'طوارئ',
      'نجدة',
    ];
    return keys.any(q.contains);
  }

  static bool _calmPhrasesInMessage(String q) {
    const calm = [
      'je suis calme',
      'je reste calme',
      'i am calm',
      'staying calm',
      'ça va aller',
      'ca va aller',
      'no danger',
      'pas de danger',
    ];
    return calm.any(q.contains);
  }
}
