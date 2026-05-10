import 'package:dio/dio.dart';

import '../../core/config/api_config.dart';
import 'ai_module_api_key_interceptor.dart';

/// Client HTTP dédié au backend Flask AI, volontairement séparé de l'API Ma3ak.
class AiModuleApiClient {
  /// Connexion TCP + TLS vers Render : le plan gratuit peut **dormir** ; le réveil
  /// dépasse souvent 30–45 s. 120 s limite les faux timeouts au premier appel.
  static const Duration _connectTimeout = Duration(seconds: 120);

  AiModuleApiClient({Dio? dio, String? baseUrl})
    : dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? ApiConfig.aiModuleBaseUrl,
              connectTimeout: _connectTimeout,
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 90),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      AiModuleApiKeyInterceptor(apiKey: ApiConfig.aiModuleApiKey),
    );
    if (const bool.fromEnvironment('dart.vm.product') == false) {
      this.dio.interceptors.add(
        // Les payloads image/base64 peuvent être énormes en mode live.
        LogInterceptor(requestBody: false, responseBody: false, error: true),
      );
    }
  }

  final Dio dio;

  Future<Response<Map<String, dynamic>>> getHealth() {
    return dio.get<Map<String, dynamic>>(
      '/health',
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> listModels() {
    return dio.get<Map<String, dynamic>>(
      '/models',
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> predictJson(
    String modelName,
    Map<String, dynamic> payload, {
    Duration sendTimeout = const Duration(seconds: 25),
    Duration receiveTimeout = const Duration(seconds: 45),
  }) {
    return dio.post<Map<String, dynamic>>(
      '/$modelName/predict',
      data: payload,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> predictMultipart(
    String modelName,
    FormData payload, {
    Duration sendTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 60),
  }) {
    return dio.post<Map<String, dynamic>>(
      '/$modelName/predict',
      data: payload,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: sendTimeout,
        receiveTimeout: receiveTimeout,
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postStt(FormData formData) {
    final key = ApiConfig.aiModuleApiKey?.trim();
    return dio.post<Map<String, dynamic>>(
      '/stt',
      data: formData,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 180),
        // Redondant avec [AiModuleApiKeyInterceptor] : sécurise les uploads multipart
        // si un client Dio sans intercepteur réutilisait cette méthode.
        headers: (key != null && key.isNotEmpty)
            ? <String, dynamic>{'X-API-Key': key}
            : null,
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postTts(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>(
      '/tts',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postAirClick(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/air-click',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postDwellSelect(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/dwell-select',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postDwellReset(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/dwell-reset',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postAdapt(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>(
      '/adapt',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postIntent(Map<String, dynamic> json) {
    return dio.post<Map<String, dynamic>>(
      '/intent',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
  }

  Future<Response<Map<String, dynamic>>> postScreenSummary(
    Map<String, dynamic> json,
  ) {
    return dio.post<Map<String, dynamic>>(
      '/screen-summary',
      data: json,
      options: Options(
        connectTimeout: _connectTimeout,
        sendTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );
  }
}
