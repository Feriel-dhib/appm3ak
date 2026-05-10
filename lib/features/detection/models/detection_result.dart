import 'package:equatable/equatable.dart';

import '../config/detection_config.dart';

/// Résultat d'une détection d'obstacle avec estimation de distance et zone.
class DetectionResult extends Equatable {
  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.distanceMeters,
    required this.riskLevel,
    required this.zone,
  });

  /// Clé de classe (ex: person, car, chair).
  final String label;

  /// Score de confiance du modèle (0–1).
  final double confidence;

  /// Bounding box normalisée (0–1) : left, top, right, bottom.
  final BBoxNorm boundingBox;

  /// Distance estimée en mètres (monoculaire).
  final double distanceMeters;

  /// Niveau de risque selon les seuils config.
  final RiskLevel riskLevel;

  /// Zone horizontale (gauche / centre / droite) pour le cooldown par zone.
  final HorizontalZone zone;

  double get centerX => (boundingBox.left + boundingBox.right) / 2;
  double get centerY => (boundingBox.top + boundingBox.bottom) / 2;

  @override
  List<Object?> get props => [label, confidence, boundingBox, distanceMeters, riskLevel, zone];
}

/// Bounding box normalisée (valeurs 0–1).
class BBoxNorm extends Equatable {
  const BBoxNorm({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  @override
  List<Object?> get props => [left, top, right, bottom];
}

/// Zone horizontale pour le cooldown (éviter de répéter la même zone).
enum HorizontalZone {
  left,   // centreX < 0.33
  center, // 0.33 <= centreX <= 0.66
  right,  // centreX > 0.66
}

/// Calcule la zone horizontale à partir du centre X normalisé (0–1).
HorizontalZone horizontalZoneFromCenterX(double centerX) {
  if (centerX < 1 / 3) return HorizontalZone.left;
  if (centerX <= 2 / 3) return HorizontalZone.center;
  return HorizontalZone.right;
}
