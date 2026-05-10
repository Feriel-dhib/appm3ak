import 'package:latlong2/latlong.dart';

import 'route_guidance_utils.dart';

/// Une étape de guidage vocal alignée sur un sommet de la polyline d’itinéraire.
class TurnStep {
  const TurnStep({
    required this.vertexIndex,
    required this.voiceKey,
  });

  /// Indice du point de l’itinéraire où la manœuvre a lieu.
  final int vertexIndex;

  /// Clé TTS : [left], [right], [straight], [uturn].
  final String voiceKey;
}

/// Construit les étapes « pas à pas » à partir des changements de direction le long de la ligne.
///
/// [minBendDeg] : angle minimal pour créer une étape (réduit le bruit des polylignes denses).
/// Les virages marqués sont classés en gauche / droite ; les courbes légères donnent [straight]
/// (« Continuez tout droit »).
List<TurnStep> computeTurnSteps(
  List<LatLng> polyline, {
  double minBendDeg = 20,
  double sharpTurnDeg = 38,
  double uturnDeg = 130,
}) {
  if (polyline.length < 3) return [];

  final out = <TurnStep>[];
  for (var i = 1; i < polyline.length - 1; i++) {
    final bIn = RouteGuidanceUtils.bearing(polyline[i - 1], polyline[i]);
    final bOut = RouteGuidanceUtils.bearing(polyline[i], polyline[i + 1]);
    final raw = RouteGuidanceUtils.deltaDegrees(bIn, bOut);
    final mag = raw.abs();
    if (mag < minBendDeg) continue;

    String voiceKey;
    if (mag >= uturnDeg) {
      voiceKey = 'uturn';
    } else if (mag < sharpTurnDeg) {
      voiceKey = 'straight';
    } else if (raw > 0) {
      voiceKey = 'right';
    } else {
      voiceKey = 'left';
    }

    if (out.isNotEmpty && out.last.vertexIndex == i && out.last.voiceKey == voiceKey) {
      continue;
    }
    out.add(TurnStep(vertexIndex: i, voiceKey: voiceKey));
  }
  return out;
}
