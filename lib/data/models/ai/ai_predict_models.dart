class AiModelDescriptor {
  const AiModelDescriptor({required this.name});

  factory AiModelDescriptor.fromDynamic(Object? value) {
    if (value is Map<String, dynamic>) {
      final name = value['name']?.toString().trim() ?? '';
      return AiModelDescriptor(name: name);
    }
    return AiModelDescriptor(name: value?.toString().trim() ?? '');
  }

  final String name;
}

class AiModelsResponse {
  const AiModelsResponse({required this.models});

  factory AiModelsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['models'] as List<dynamic>? ?? const <dynamic>[])
        .map(AiModelDescriptor.fromDynamic)
        .where((e) => e.name.isNotEmpty)
        .toList();
    return AiModelsResponse(models: list);
  }

  final List<AiModelDescriptor> models;
}

double _asDouble(Object? value, [double fallback = 0]) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

/// Réponses Flask du type `{ "ok": true, "result": { ... } }`.
Map<String, dynamic> unwrapAiPredictResult(Map<String, dynamic> json) {
  final inner = json['result'] ?? json['data'];
  if (inner is Map<String, dynamic>) return inner;
  return json;
}

class ScannerProResponse {
  const ScannerProResponse({
    required this.isKnown,
    required this.identityLabel,
    required this.dominantEmotion,
    required this.stressScore,
    required this.suspiciousSignals,
    required this.raw,
  });

  factory ScannerProResponse.fromJson(Map<String, dynamic> json) {
    final j = unwrapAiPredictResult(json);
    final known = j['known'] == true ||
        j['is_known'] == true ||
        j['status']?.toString().toLowerCase() == 'known';
    final suspicious = (j['suspicious_signals'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return ScannerProResponse(
      isKnown: known,
      identityLabel: j['name']?.toString() ??
          j['identity']?.toString() ??
          j['label']?.toString() ??
          (known ? 'Personne connue' : 'Inconnu'),
      dominantEmotion: j['dominant_emotion']?.toString() ??
          j['emotion']?.toString() ??
          'indisponible',
      stressScore: _asDouble(j['stress_score']),
      suspiciousSignals: suspicious,
      raw: json,
    );
  }

  final bool isKnown;
  final String identityLabel;
  final String dominantEmotion;
  final double stressScore;
  final List<String> suspiciousSignals;
  final Map<String, dynamic> raw;
}

class RecognizeResponse {
  const RecognizeResponse({
    required this.isKnown,
    required this.identityLabel,
    required this.dominantEmotion,
    required this.estimatedAge,
    required this.estimatedGender,
    required this.raw,
  });

  factory RecognizeResponse.fromJson(Map<String, dynamic> json) {
    final j = unwrapAiPredictResult(json);
    final known = j['known'] == true ||
        j['is_known'] == true ||
        j['status']?.toString().toLowerCase() == 'known';
    return RecognizeResponse(
      isKnown: known,
      identityLabel: j['name']?.toString() ??
          j['identity']?.toString() ??
          (known ? 'Personne connue' : 'Inconnu'),
      dominantEmotion:
          j['dominant_emotion']?.toString() ?? j['emotion']?.toString() ?? '',
      estimatedAge: j['age']?.toString() ?? '',
      estimatedGender: j['gender']?.toString() ?? '',
      raw: json,
    );
  }

  final bool isKnown;
  final String identityLabel;
  final String dominantEmotion;
  final String estimatedAge;
  final String estimatedGender;
  final Map<String, dynamic> raw;
}

class ScannerFerResponse {
  const ScannerFerResponse({
    required this.dominantEmotion,
    required this.emotions,
    required this.summary,
    required this.raw,
  });

  factory ScannerFerResponse.fromJson(Map<String, dynamic> json) {
    final j = unwrapAiPredictResult(json);
    final emotions = (j['emotions'] as Map<String, dynamic>? ?? const {})
        .map((key, value) => MapEntry(key, _asDouble(value)));
    return ScannerFerResponse(
      dominantEmotion: j['dominant_emotion']?.toString() ??
          j['emotion']?.toString() ??
          'indisponible',
      emotions: emotions,
      summary: j['analysis']?.toString() ??
          j['summary']?.toString() ??
          j['message']?.toString() ??
          '',
      raw: json,
    );
  }

  final String dominantEmotion;
  final Map<String, double> emotions;
  final String summary;
  final Map<String, dynamic> raw;
}

class SignExplainResponse {
  const SignExplainResponse({
    required this.signLabel,
    required this.confidence,
    required this.explanation,
    required this.detectedFingers,
    required this.raw,
  });

  factory SignExplainResponse.fromJson(Map<String, dynamic> json) {
    final fingers = (json['fingers'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return SignExplainResponse(
      signLabel:
          json['sign']?.toString() ?? json['label']?.toString() ?? 'Inconnu',
      confidence: _asDouble(json['confidence']),
      explanation: json['explanation']?.toString() ??
          json['message']?.toString() ??
          '',
      detectedFingers: fingers,
      raw: json,
    );
  }

  final String signLabel;
  final double confidence;
  final String explanation;
  final List<String> detectedFingers;
  final Map<String, dynamic> raw;
}

class SignTextResponse {
  const SignTextResponse({
    required this.inputText,
    required this.visualSequence,
    required this.raw,
  });

  factory SignTextResponse.fromJson(Map<String, dynamic> json) {
    final seq = (json['sequence'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .toList();
    return SignTextResponse(
      inputText: json['text']?.toString() ?? json['input']?.toString() ?? '',
      visualSequence: seq,
      raw: json,
    );
  }

  final String inputText;
  final List<String> visualSequence;
  final Map<String, dynamic> raw;
}

class AdaptiveDifficultyRequest {
  const AdaptiveDifficultyRequest({
    required this.avgLast5Scores,
    required this.errorsCount,
    required this.successStreak,
    required this.exerciseId,
  });

  final double avgLast5Scores;
  final int errorsCount;
  final int successStreak;
  final int exerciseId;

  Map<String, dynamic> toJson() => {
        'avg_last_5_scores': avgLast5Scores,
        'errors_count': errorsCount,
        'success_streak': successStreak,
        'exercise_id': exerciseId,
      };
}

class AdaptiveDifficultyResponse {
  const AdaptiveDifficultyResponse({
    required this.recommendedDifficulty,
    required this.feedback,
    required this.nextExerciseId,
    required this.raw,
  });

  factory AdaptiveDifficultyResponse.fromJson(Map<String, dynamic> json) {
    return AdaptiveDifficultyResponse(
      recommendedDifficulty:
          int.tryParse(json['recommended_difficulty']?.toString() ?? '') ??
              int.tryParse(json['difficulty']?.toString() ?? '') ??
              1,
      feedback: json['feedback']?.toString() ??
          json['message']?.toString() ??
          'Aucun feedback.',
      nextExerciseId:
          int.tryParse(json['next_exercise_id']?.toString() ?? '') ?? 0,
      raw: json,
    );
  }

  final int recommendedDifficulty;
  final String feedback;
  final int nextExerciseId;
  final Map<String, dynamic> raw;
}
