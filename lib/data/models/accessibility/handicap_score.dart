import 'package:equatable/equatable.dart';

/// Score d'accessibilité détaillé pour un type de handicap donné.
///
/// Retourné par `POST /accessibility/analyze` (Groq + OSM) dans chacune des
/// rubriques : `fauteuil_roulant`, `surdite`, `cecite`, `mobilite_reduite`,
/// `cognitif`.
class HandicapScore extends Equatable {
  const HandicapScore({
    required this.score,
    required this.niveau,
    required this.details,
    required this.sources,
  });

  /// Score entier 0–100 (normalisé côté backend).
  final int score;

  /// Libellé qualitatif : `Excellent`, `Bon`, `Partiel`, `Non adapté`.
  final String niveau;

  /// Liste de phrases expliquant le calcul (tags OSM, commentaires…).
  final List<String> details;

  /// Sources utilisées (OpenStreetMap, Groq, avis utilisateurs…).
  final List<String> sources;

  factory HandicapScore.fromJson(Map<String, dynamic> json) => HandicapScore(
        score: (json['score'] as num?)?.toInt() ?? 0,
        niveau: json['niveau'] as String? ?? 'Non adapté',
        details: _stringList(json['details']),
        sources: _stringList(json['sources']),
      );

  Map<String, dynamic> toJson() => {
        'score': score,
        'niveau': niveau,
        'details': details,
        'sources': sources,
      };

  /// Couleurs de référence utilisées par l'UI (AARRGGBB).
  static const Map<String, int> _colors = {
    'Excellent': 0xFF2A9F58,
    'Bon': 0xFF4A90D9,
    'Partiel': 0xFFE69D2A,
    'Non adapté': 0xFFD24C4C,
  };

  /// Couleur de badge associée au niveau (fallback gris).
  int get colorValue => _colors[niveau] ?? 0xFF888888;

  static const HandicapScore empty = HandicapScore(
    score: 0,
    niveau: 'Non adapté',
    details: <String>[],
    sources: <String>[],
  );

  @override
  List<Object?> get props => [score, niveau, details, sources];
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw.whereType<String>().toList(growable: false);
  }
  return const <String>[];
}
