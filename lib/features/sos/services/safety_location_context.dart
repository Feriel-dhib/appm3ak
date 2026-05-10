import 'package:geolocator/geolocator.dart';

/// Contexte lieu / temps (heuristiques simples, pas de carte des zones à risque en base).
class SafetyLocationContext {
  const SafetyLocationContext();

  /// 0–100 : nuit, précision GPS faible, pas de position.
  int riskScore({
    required DateTime now,
    Position? position,
  }) {
    var s = 0;
    if (position == null) {
      s += 25;
      return s.clamp(0, 100);
    }
    final h = now.hour;
    if (h >= 22 || h < 6) s += 38;
    if (position.accuracy > 80) s += 15;
    return s.clamp(0, 100);
  }

  List<String> breakdownFr(DateTime now, Position? position) {
    final lines = <String>[];
    if (position == null) {
      lines.add('Position GPS indisponible (+ risque contextuel).');
      return lines;
    }
    final h = now.hour;
    if (h >= 22 || h < 6) {
      lines.add('Créneau nocturne : vigilance accrue.');
    } else {
      lines.add('Créneau diurne.');
    }
    if (position.accuracy > 80) {
      lines.add('Précision GPS faible — localisation approximative.');
    } else {
      lines.add('Précision GPS correcte.');
    }
    return lines;
  }
}
