/// Une commande envoyée au backend `/intent` : id stable + mots-clés
/// multi-langues. Le backend renvoie l'`id` dont le score est le plus élevé.
class VoiceCommandDescriptor {
  const VoiceCommandDescriptor({required this.id, required this.keywords});

  final String id;
  final List<String> keywords;

  Map<String, dynamic> toJson() => {
    'id': id,
    'keywords': keywords,
  };
}

class VoiceIntentRequest {
  const VoiceIntentRequest({
    required this.text,
    this.commands,
    this.minScore,
  });

  final String text;
  final List<VoiceCommandDescriptor>? commands;
  final double? minScore;

  Map<String, dynamic> toJson() => {
    'text': text,
    if (commands != null)
      'commands': commands!.map((c) => c.toJson()).toList(growable: false),
    if (minScore != null) 'min_score': minScore,
  };
}

class VoiceIntentResponse {
  const VoiceIntentResponse({
    required this.match,
    required this.score,
    required this.normalized,
    required this.matchedKeyword,
  });

  factory VoiceIntentResponse.fromJson(Map<String, dynamic> json) {
    return VoiceIntentResponse(
      match: json['match']?.toString(),
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      normalized: json['normalized']?.toString() ?? '',
      matchedKeyword: json['matched_keyword']?.toString() ?? '',
    );
  }

  /// `null` si aucun intent n'a passé le seuil de score.
  final String? match;
  final double score;
  final String normalized;
  final String matchedKeyword;

  bool get hasMatch => match != null && match!.isNotEmpty;
}

class ScreenSummaryItem {
  const ScreenSummaryItem({required this.label, this.hint});

  final String label;
  final String? hint;

  Map<String, dynamic> toJson() => {
    'label': label,
    if (hint != null && hint!.trim().isNotEmpty) 'hint': hint,
  };
}

class ScreenSummaryRequest {
  const ScreenSummaryRequest({required this.title, required this.items});

  final String title;
  final List<ScreenSummaryItem> items;

  Map<String, dynamic> toJson() => {
    'title': title,
    'items': items.map((i) => i.toJson()).toList(growable: false),
  };
}

class ScreenSummaryResponse {
  const ScreenSummaryResponse({required this.summary});

  factory ScreenSummaryResponse.fromJson(Map<String, dynamic> json) {
    return ScreenSummaryResponse(
      summary: json['summary']?.toString() ?? '',
    );
  }

  final String summary;
}
