import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../models/voice_stress_api_result.dart';

/// Client HTTP vers le service Python (sans JWT Ma3ak).
class VoiceStressApiClient {
  VoiceStressApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.stressAudioApiUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Accept': 'application/json'},
      ),
    );
  }

  late final Dio _dio;

  Future<bool> isHealthy() async {
    try {
      final r = await _dio.get<Map<String, dynamic>>(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      return r.data?['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<VoiceStressApiResult> analyzeWavFile(String filePath) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        filename: 'stress_sample.wav',
      ),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '/analyze',
      data: form,
    );
    final data = res.data;
    if (data == null) {
      throw DioException(
        requestOptions: res.requestOptions,
        message: 'Réponse vide du serveur stress audio',
      );
    }
    return VoiceStressApiResult.fromJson(data);
  }
}
