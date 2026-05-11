enum AiUserType {
  blind,
  deaf,
  motor;

  /// Parse une chaîne API hétérogène. Accepte aussi bien les codes courts
  /// (`"motor"`, `"visuel"`) que les libellés complets backend
  /// (`"Handicap moteur"`, `"Handicap visuel"`, etc.) en faisant un
  /// `contains` sur des mots-clés. Aligné sur `TypeHandicap.fromApiString`
  /// pour garantir une seule source de vérité.
  static AiUserType? fromJson(String? value) {
    final v = value?.trim().toLowerCase();
    if (v == null || v.isEmpty) return null;
    if (v.contains('visuel') ||
        v.contains('visual') ||
        v.contains('blind') ||
        v.contains('malvoy') ||
        v.contains('aveugle')) {
      return AiUserType.blind;
    }
    if (v.contains('auditif') ||
        v.contains('hearing') ||
        v.contains('deaf') ||
        v.contains('sourd')) {
      return AiUserType.deaf;
    }
    if (v.contains('moteur') ||
        v.contains('motor') ||
        v.contains('mobil') ||
        v.contains('motricite')) {
      return AiUserType.motor;
    }
    return null;
  }

  String toJson() => name;
}

enum AiInteractionMode {
  voiceMode,
  textMode,
  gestureMode;

  static AiInteractionMode fromJson(String? value) {
    return switch (value) {
      'voice_mode' => AiInteractionMode.voiceMode,
      'text_mode' => AiInteractionMode.textMode,
      'gesture_mode' => AiInteractionMode.gestureMode,
      _ => AiInteractionMode.textMode,
    };
  }

  String toJson() {
    return switch (this) {
      AiInteractionMode.voiceMode => 'voice_mode',
      AiInteractionMode.textMode => 'text_mode',
      AiInteractionMode.gestureMode => 'gesture_mode',
    };
  }
}

class AdaptRequest {
  const AdaptRequest({required this.userType});

  final AiUserType userType;

  Map<String, dynamic> toJson() => {'user_type': userType.toJson()};
}

class AdaptResponse {
  const AdaptResponse({required this.mode});

  factory AdaptResponse.fromJson(Map<String, dynamic> json) {
    return AdaptResponse(
      mode: AiInteractionMode.fromJson(json['mode']?.toString()),
    );
  }

  final AiInteractionMode mode;
}
