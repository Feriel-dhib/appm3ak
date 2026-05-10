import 'app_config.dart';

/// Configuration centralisée des endpoints API externes (dev/prod).
class ApiConfig {
  ApiConfig._();

  static const String _renderAiModuleBaseUrl =
      'https://ai-module-navigation.onrender.com';

  static const String _envAiModuleBaseUrl = String.fromEnvironment(
    'AI_MODULE_BASE_URL',
    defaultValue: '',
  );

  static const String _envAiModuleApiKey = String.fromEnvironment(
    'MA3AK_API_KEY',
    defaultValue: '',
  );

  /// URL du backend AI. Priorité au `--dart-define`, sinon Render.
  static String get aiModuleBaseUrl {
    if (_envAiModuleBaseUrl.isNotEmpty) return _envAiModuleBaseUrl;
    final fallback = AppConfig.aiModuleBaseUrl;
    if (fallback.trim().isNotEmpty) return fallback;
    return _renderAiModuleBaseUrl;
  }

  /// Clé API injectée via `--dart-define=MA3AK_API_KEY=...`.
  /// Vide au build → 401 sur les routes protégées ; voir `AiModuleApiKeyInterceptor`.
  /// Timeouts réseau : `lib/data/api/ai_module_api_client.dart` (cold start Render).
  static String? get aiModuleApiKey {
    final value = _envAiModuleApiKey.trim();
    return value.isEmpty ? null : value;
  }
}
