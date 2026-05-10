/// Réponse JSON du serveur `/analyze` (forme courte ou étendue).
class VoiceStressApiResult {
  const VoiceStressApiResult({
    required this.score,
    required this.label,
    required this.labelFr,
    required this.detailFr,
    this.fromOfflineFallback = false,
  });

  final int score;
  final String label;
  final String labelFr;
  final String detailFr;

  /// `true` si le score vient de l’heuristique locale (serveur Python indisponible).
  final bool fromOfflineFallback;

  factory VoiceStressApiResult.fromJson(Map<String, dynamic> json) {
    final stressRaw = json['stress'];
    final state = json['state'] as String?;

    if (stressRaw != null && state != null) {
      final stress = (stressRaw as num).toDouble();
      final fromStress =
          stress <= 1.0 ? (stress * 100).round() : stress.round();
      final sField = json['score'];
      final score = (sField != null
              ? (sField is int ? sField : int.tryParse('$sField'))
              : null) ??
          fromStress;

      return VoiceStressApiResult(
        score: score.clamp(0, 100),
        label: json['label'] as String? ?? state,
        labelFr: (json['label_fr'] as String?) ?? _stateLabelFr(state),
        detailFr: (json['detail_fr'] as String?) ??
            'stress=${stress.toStringAsFixed(2)}, state=$state',
        fromOfflineFallback: false,
      );
    }

    final s = json['score'];
    return VoiceStressApiResult(
      score: s is int ? s : int.tryParse('$s') ?? 0,
      label: json['label'] as String? ?? 'unknown',
      labelFr: json['label_fr'] as String? ?? '',
      detailFr: json['detail_fr'] as String? ?? '',
      fromOfflineFallback: false,
    );
  }

  static String _stateLabelFr(String state) {
    switch (state) {
      case 'calm':
        return 'Calme';
      case 'stress':
        return 'Stress';
      case 'panic':
        return 'Panique';
      default:
        return state;
    }
  }
}
