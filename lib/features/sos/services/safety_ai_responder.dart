import '../models/safety_risk_models.dart';

/// Réponse « assistant IA » en français à partir du texte + fusion (hors cloud).
class SafetyAiResponder {
  const SafetyAiResponder();

  String buildReply({
    required String userMessage,
    required FusionResult fusion,
  }) {
    final msg = userMessage.trim();
    final tier = fusion.tier;
    final g = fusion.globalScore;
    final v = fusion.signals.voiceStress;

    final intro = msg.isEmpty
        ? (v != null && v >= 40
            ? 'Sans texte saisi, le signal vocal dominant est pris en compte pour le bilan. '
            : 'Vous n’avez pas encore décrit votre ressenti. '
                'Écrivez quelques mots (peur, fatigue, douleur…) pour affiner l’analyse.')
        : 'D’après ce que vous avez écrit (« $msg »), ';
    final voiceClause = v != null
        ? ' L’analyse vocale (MFCC, énergie, rythme) sur votre dernier enregistrement '
            'estime une tension d’environ $v % (${_voiceLabelHint(v)}).'
        : '';

    switch (tier) {
      case SafetyRiskTier.calm:
        return '$intro'
            'l’analyse est plutôt rassurante (score global environ $g %). '
            'Vous semblez dans un état stable au regard des signaux disponibles.$voiceClause '
            'Si un doute persiste, vous pouvez tout de même parler à un proche ou à un professionnel de santé. '
            'Rappel : cet outil ne remplace pas un diagnostic médical.';

      case SafetyRiskTier.lightStress:
        return '$intro'
            'je détecte un léger stress ou une gêne (score ~$g %).$voiceClause '
            'Respirez calmement, asseyez-vous si possible, et contactez une personne de confiance si vous en ressentez le besoin. '
            'Le bouton SOS intelligent peut prévenir votre premier accompagnant enregistré.';

      case SafetyRiskTier.mediumDanger:
        return '$intro'
            'les signaux combinés (texte, mouvement éventuel, contexte) suggèrent une situation à surveiller (score ~$g %).$voiceClause '
            'Je vous recommande de prévenir un accompagnant tout de suite et de ne pas rester seul·e si vous vous sentez mal. '
            'Utilisez « SOS intelligent » pour envoyer votre position et lancer l’appel.';

      case SafetyRiskTier.critical:
        return '$intro'
            'le niveau estimé est élevé (score ~$g %).$voiceClause '
            'Contactez les secours (190) si vous êtes en danger immédiat, et utilisez SOS intelligent pour alerter tous vos contacts enregistrés avec votre localisation. '
            'Restez au téléphone si vous le pouvez.';
    }
  }

  static String _voiceLabelHint(int score) {
    if (score < 22) return 'voix plutôt calme';
    if (score < 40) return 'légère tension vocale';
    if (score < 60) return 'stress vocal marqué';
    if (score < 78) return 'forte tension / danger modéré';
    return 'signaux vocaux d’urgence';
  }
}
