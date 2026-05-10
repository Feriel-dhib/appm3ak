/// Représente un obstacle détecté par le module IA (ML Kit).
class DetectedObstacle {
  const DetectedObstacle({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    this.trackingId,
  });

  /// Label brut du modèle (ex: person, car, bicycle).
  final String label;

  /// Score de confiance entre 0 et 1.
  final double confidence;

  /// Rectangle de détection normalisé (left, top, right, bottom) entre 0 et 1.
  final RectNorm boundingBox;

  /// ID de suivi en mode stream (optionnel).
  final int? trackingId;

  /// Position horizontale du centre de l'obstacle (0 = gauche, 1 = droite).
  double get centerX =>
      (boundingBox.left + boundingBox.right) / 2;

  /// Position verticale du centre (0 = haut, 1 = bas).
  double get centerY =>
      (boundingBox.top + boundingBox.bottom) / 2;

  /// Zone approximative (pour prioriser les obstacles proches du centre = devant).
  double get area =>
      (boundingBox.right - boundingBox.left) *
      (boundingBox.bottom - boundingBox.top);
}

/// Rectangle normalisé (valeurs 0–1).
class RectNorm {
  const RectNorm({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
}
