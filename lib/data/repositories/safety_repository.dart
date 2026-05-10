import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';
import '../models/voice_emergency_result.dart';

/// Alerte sécurité vocale + matching intelligent (côté serveur).
class SafetyRepository {
  SafetyRepository({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Le backend choisit le contact (priorité, disponibilité), enregistre l’alerte
  /// et peut envoyer notifications — renvoie le numéro à composer.
  Future<VoiceEmergencyResult> triggerVoiceEmergency({
    required String transcript,
    required String locale,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      Endpoints.safetyVoiceEmergency,
      data: {
        'transcript': transcript,
        'locale': locale,
        'source': 'health_chat_voice',
      },
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Empty safety response',
      );
    }
    return VoiceEmergencyResult.fromJson(data);
  }
}
