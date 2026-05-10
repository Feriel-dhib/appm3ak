enum AirClickAction {
  click,
  hold,
  move,
  idle;

  static AirClickAction fromJson(String? value) {
    return switch (value) {
      'click' => AirClickAction.click,
      'hold' => AirClickAction.hold,
      'move' => AirClickAction.move,
      'idle' => AirClickAction.idle,
      _ => AirClickAction.idle,
    };
  }

  String toJson() => name;
}

/// Profil de sensibilité pour la détection de gestes — adapte les seuils
/// au degré de mobilité de l'utilisateur (mode geste / handicap moteur).
enum MotorSensitivity {
  /// Mobilité réduite : exige des gestes amples (utilisateur peu précis).
  low,

  /// Profil par défaut.
  normal,

  /// Mobilité limitée : accepte des gestes minimes (handicap moteur sévère).
  high;

  String toApiValue() => name;

  String localizedLabel() {
    switch (this) {
      case MotorSensitivity.low:
        return 'Gestes amples';
      case MotorSensitivity.normal:
        return 'Sensibilité normale';
      case MotorSensitivity.high:
        return 'Gestes minimes';
    }
  }

  String localizedHint() {
    switch (this) {
      case MotorSensitivity.low:
        return 'Pour mouvements imprécis, il faut bouger franchement.';
      case MotorSensitivity.normal:
        return 'Réglage par défaut, équilibré.';
      case MotorSensitivity.high:
        return 'Détecte les petits gestes, pour mobilité très limitée.';
    }
  }
}

class AirClickRequest {
  const AirClickRequest({
    required this.landmarks,
    this.clientId,
    this.sensitivity,
  });

  final Map<String, dynamic> landmarks;
  final String? clientId;
  final MotorSensitivity? sensitivity;

  Map<String, dynamic> toJson() => {
    'landmarks': landmarks,
    if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
    if (sensitivity != null) 'sensitivity': sensitivity!.toApiValue(),
  };
}

class AirClickResponse {
  const AirClickResponse({
    required this.action,
    this.confidence = 0.0,
    this.sensitivity,
  });

  factory AirClickResponse.fromJson(Map<String, dynamic> json) {
    return AirClickResponse(
      action: AirClickAction.fromJson(json['action']?.toString()),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      sensitivity: json['sensitivity']?.toString(),
    );
  }

  final AirClickAction action;
  final double confidence;
  final String? sensitivity;
}

/// Requête de **sélection par maintien** (dwell) côté API.
/// L'app envoie l'index focalisé en continu, l'API renvoie quand le maintien
/// dépasse `dwellMs`.
class DwellSelectRequest {
  const DwellSelectRequest({
    required this.focusIndex,
    this.clientId,
    this.dwellMs,
  });

  /// `-1` = aucun item focalisé.
  final int focusIndex;
  final String? clientId;
  final int? dwellMs;

  Map<String, dynamic> toJson() => {
    'focus_index': focusIndex,
    if (clientId != null && clientId!.isNotEmpty) 'client_id': clientId,
    if (dwellMs != null) 'dwell_ms': dwellMs,
  };
}

class DwellSelectResponse {
  const DwellSelectResponse({
    required this.selected,
    required this.selectedIndex,
    required this.elapsedMs,
    required this.remainingMs,
    required this.progress,
  });

  factory DwellSelectResponse.fromJson(Map<String, dynamic> json) {
    return DwellSelectResponse(
      selected: json['selected'] == true,
      selectedIndex: (json['selected_index'] as num?)?.toInt(),
      elapsedMs: (json['elapsed_ms'] as num?)?.toInt() ?? 0,
      remainingMs: (json['remaining_ms'] as num?)?.toInt() ?? 0,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final bool selected;
  final int? selectedIndex;
  final int elapsedMs;
  final int remainingMs;

  /// 0..1 — utile pour afficher une barre de progression du dwell.
  final double progress;
}
