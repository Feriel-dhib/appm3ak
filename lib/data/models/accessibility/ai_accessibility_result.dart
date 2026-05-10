import 'package:equatable/equatable.dart';

import 'handicap_score.dart';

/// Réponse complète de `POST /accessibility/analyze`.
///
/// Fusionne les données OpenStreetMap, les avis utilisateurs et l'inférence
/// Groq pour produire un score global + un score par handicap.
class AIAccessibilityResult extends Equatable {
  const AIAccessibilityResult({
    required this.placeName,
    required this.scoreGlobal,
    required this.fauteuilRoulant,
    required this.surdite,
    required this.cecite,
    required this.mobiliteReduite,
    required this.cognitif,
    required this.resumeIA,
    required this.confiance,
    required this.sourcesUtilisees,
    required this.osmTags,
  });

  final String placeName;
  final int scoreGlobal;
  final HandicapScore fauteuilRoulant;
  final HandicapScore surdite;
  final HandicapScore cecite;
  final HandicapScore mobiliteReduite;
  final HandicapScore cognitif;

  /// Résumé en langage naturel produit par l'IA.
  final String resumeIA;

  /// Niveau de confiance global : `Elevee` / `Moyenne` / `Faible`
  /// (accepte aussi la variante accentuée `Élevée`).
  final String confiance;

  /// Sources ayant contribué (OpenStreetMap, Groq, commentaires…).
  final List<String> sourcesUtilisees;

  /// Tags OSM bruts tels qu'ils ont été collectés.
  final Map<String, dynamic> osmTags;

  factory AIAccessibilityResult.fromJson(Map<String, dynamic> json) =>
      AIAccessibilityResult(
        placeName: json['place_name'] as String? ?? '',
        scoreGlobal: (json['score_global'] as num?)?.toInt() ?? 0,
        fauteuilRoulant:
            HandicapScore.fromJson(_asMap(json['fauteuil_roulant'])),
        surdite: HandicapScore.fromJson(_asMap(json['surdite'])),
        cecite: HandicapScore.fromJson(_asMap(json['cecite'])),
        mobiliteReduite:
            HandicapScore.fromJson(_asMap(json['mobilite_reduite'])),
        cognitif: HandicapScore.fromJson(_asMap(json['cognitif'])),
        resumeIA: json['resume_ia'] as String? ?? '',
        confiance: json['confiance'] as String? ?? 'Faible',
        sourcesUtilisees:
            (json['sources_utilisees'] as List?)?.whereType<String>().toList() ??
                const [],
        osmTags: _asMap(json['osm_tags']),
      );

  /// Accès dynamique au score d'un type de handicap.
  HandicapScore scoreFor(String type) {
    switch (type.toLowerCase()) {
      case 'fauteuil':
      case 'fauteuil_roulant':
        return fauteuilRoulant;
      case 'surdite':
      case 'auditif':
        return surdite;
      case 'cecite':
      case 'visuel':
        return cecite;
      case 'mobilite':
      case 'mobilite_reduite':
      case 'moteur':
        return mobiliteReduite;
      case 'cognitif':
        return cognitif;
      default:
        return fauteuilRoulant;
    }
  }

  @override
  List<Object?> get props => [
        placeName,
        scoreGlobal,
        fauteuilRoulant,
        surdite,
        cecite,
        mobiliteReduite,
        cognitif,
        resumeIA,
        confiance,
        sourcesUtilisees,
        osmTags,
      ];
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return raw.map((k, v) => MapEntry(k.toString(), v));
  return const <String, dynamic>{};
}
