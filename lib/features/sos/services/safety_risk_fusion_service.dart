import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

import '../models/safety_risk_models.dart';
import 'safety_location_context.dart';
import 'safety_text_analyzer.dart';

/// Fusion pondérée : le « cerveau » qui combine texte, mouvement, lieu, (voix).
/// La **voix** ne peut pas être « noyée » : si le score vocal est élevé, le score
/// global reflète au minimum ce niveau (accessibilité / panic réel).
class SafetyRiskFusionService {
  const SafetyRiskFusionService({
    this.textWeight = 0.22,
    this.motionWeight = 0.28,
    this.locationWeight = 0.18,
    this.voiceWeight = 0.32,
  });

  final double textWeight;
  final double motionWeight;
  final double locationWeight;
  final double voiceWeight;

  static const _textAnalyzer = SafetyTextAnalyzer();
  static const _loc = SafetyLocationContext();

  FusionResult fuse({
    required String userText,
    required int motionScore,
    required DateTime now,
    Position? position,
    int? voiceScore,
  }) {
    final textScore = _textAnalyzer.analyze(userText);
    final locScore = _loc.riskScore(now: now, position: position);

    var wSum = textWeight + motionWeight + locationWeight;
    var fused = textScore * textWeight +
        motionScore * motionWeight +
        locScore * locationWeight;

    if (voiceScore != null) {
      fused += voiceScore * voiceWeight;
      wSum += voiceWeight;
    }

    var global = wSum > 0 ? (fused / wSum).round() : 0;
    if (voiceScore != null) {
      // Ne jamais afficher « calme » si la voix indique un stress fort (ex. 66 %).
      global = math.max(global, voiceScore);
    }
    final g = global.clamp(0, 100);

    final tier = _tierFromScore(g);
    final breakdown = <String>[
      'Texte : $textScore % — ${_textAnalyzer.summaryFr(textScore, raw: userText)}',
      'Mouvement (capteurs) : $motionScore %',
      'Lieu & temps : $locScore %',
      if (voiceScore != null)
        'Voix (IA audio / Python) : $voiceScore %'
      else
        'Voix : lancez « Analyser ma voix » après démarrage du serveur stress_audio_api',
      ..._loc.breakdownFr(now, position),
    ];

    return FusionResult(
      globalScore: g,
      tier: tier,
      signals: SignalScores(
        text: textScore,
        motion: motionScore,
        location: locScore,
        voiceStress: voiceScore,
      ),
      breakdownFr: breakdown,
    );
  }

  SafetyRiskTier _tierFromScore(int g) {
    if (g >= 72) return SafetyRiskTier.critical;
    if (g >= 48) return SafetyRiskTier.mediumDanger;
    if (g >= 28) return SafetyRiskTier.lightStress;
    return SafetyRiskTier.calm;
  }
}
