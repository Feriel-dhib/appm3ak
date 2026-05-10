import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/route_guidance_utils.dart';

/// Flèche de guidage superposée à la caméra ; [bearingDegrees] = cap vers la cible (0 = nord).
/// [deviceHeadingDegrees] = orientation du téléphone (0 = haut de l’écran vers le nord), si null : flèche fixe vers le haut.
class GuidanceArrowOverlay extends StatelessWidget {
  const GuidanceArrowOverlay({
    super.key,
    required this.bearingDegrees,
    this.deviceHeadingDegrees,
    this.size = 72,
  });

  final double bearingDegrees;
  final double? deviceHeadingDegrees;
  final double size;

  @override
  Widget build(BuildContext context) {
    final heading = deviceHeadingDegrees;
    // Avec boussole : flèche = cap cible − orientation téléphone. Sans boussole : mode « nord en haut ».
    final rotationRad = heading != null
        ? RouteGuidanceUtils.deltaDegrees(heading, bearingDegrees) * math.pi / 180
        : bearingDegrees * math.pi / 180;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Transform.rotate(
          angle: rotationRad,
          child: Icon(
            Icons.navigation,
            size: size,
            color: Colors.white,
            shadows: const [
              Shadow(blurRadius: 8, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }
}
