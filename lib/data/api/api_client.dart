import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import 'auth_interceptor.dart';

/// Client HTTP Dio configuré pour l'API Ma3ak.
class ApiClient {
  ApiClient({
    required this.getAccessToken,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      // Débogage iPhone en sans-fil : la poignée TCP peut dépasser 20 s. Réseau partagé / VPN idem.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(getAccessToken: getAccessToken),
      // LogInterceptor désactivé en production pour améliorer les performances
      if (const bool.fromEnvironment('dart.vm.product') == false)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
    ]);
  }

  late final Dio _dio;
  final Future<String?> Function() getAccessToken;

  Dio get dio => _dio;
}
