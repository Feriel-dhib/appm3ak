import 'package:dio/dio.dart';

/// Ajoute `X-API-Key` uniquement sur les routes AI protégées.
class AiModuleApiKeyInterceptor extends Interceptor {
  AiModuleApiKeyInterceptor({required this.apiKey});

  final String? apiKey;

  static const Set<String> _publicPaths = {'/health'};

  /// Chemin HTTP normalisé (ex. `/stt`). Dio peut remplir [RequestOptions.path]
  /// ou seulement [RequestOptions.uri] selon le type d’appel.
  static String _normalizedPath(RequestOptions options) {
    String raw = options.uri.path;
    if (raw.isEmpty || raw == '/') {
      raw = options.path;
    }
    if (raw.isEmpty) return '/';
    return raw.startsWith('/') ? raw : '/$raw';
  }

  bool _isProtected(RequestOptions options) {
    final normalized = _normalizedPath(options);
    return !_publicPaths.contains(normalized);
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    final key = apiKey?.trim();
    if (key != null && key.isNotEmpty && _isProtected(options)) {
      options.headers['X-API-Key'] = key;
    }
    handler.next(options);
  }
}
