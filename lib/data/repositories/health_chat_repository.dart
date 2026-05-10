import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../api/endpoints.dart';

/// Appel optionnel à `POST /health/chat` (OpenAI côté serveur si configuré).
class HealthChatRepository {
  HealthChatRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Retourne la réponse texte, ou `null` si l’IA cloud est indisponible / non configurée.
  Future<String?> sendMessage({
    required String message,
    required String lang,
    String? profileHint,
  }) async {
    try {
      final res = await _apiClient.dio.post<Map<String, dynamic>>(
        Endpoints.healthChat,
        data: {
          'message': message,
          'lang': lang,
          if (profileHint != null && profileHint.trim().isNotEmpty)
            'profileHint': profileHint.trim(),
        },
        options: Options(
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 30),
        ),
      );
      final data = res.data;
      if (data == null) return null;
      final reply = data['reply'];
      if (reply is String && reply.trim().isNotEmpty) {
        return reply.trim();
      }
      return null;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }
}
