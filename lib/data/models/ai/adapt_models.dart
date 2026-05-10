enum AiUserType {
  blind,
  deaf,
  motor;

  static AiUserType? fromJson(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'blind' ||
      'visual' ||
      'visuel' ||
      'malvoyant' ||
      'aveugle' => AiUserType.blind,
      'deaf' || 'hearing' || 'auditif' || 'sourd' => AiUserType.deaf,
      'motor' || 'motricite' || 'moteur' || 'mobility' => AiUserType.motor,
      _ => null,
    };
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
