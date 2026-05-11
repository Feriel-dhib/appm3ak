import 'app_config.dart';

/// Configuration centralisée des endpoints API externes (dev/prod).
class ApiConfig {
  ApiConfig._();

  static const String _renderAiModuleBaseUrl =
      'https://ai-module-navigation.onrender.com';

  static const String _renderAirWritingApiBaseUrl =
      'https://air-writing-api.onrender.com';

  /// Fallback de la clé API du module IA Render — utilisé si aucun
  /// `--dart-define=MA3AK_API_KEY=...` n'est passé au build (oubli du launch
  /// config VS Code, build sur une autre machine, etc.). Reste surchargeable
  /// par dart-define pour rotation de clé en prod / staging.
  static const String _fallbackAiModuleApiKey =
      '86b7d784fb40db6a6e1f417b56a456537c4305fbde71bc10133cab970478a796';

  static const String _envAiModuleBaseUrl = String.fromEnvironment(
    'AI_MODULE_BASE_URL',
    defaultValue: '',
  );

  static const String _envAirWritingApiBaseUrl = String.fromEnvironment(
    'AIR_WRITING_API_BASE_URL',
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

  /// URL du backend Air Writing (FastAPI Render).
  /// Surcharge : `--dart-define=AIR_WRITING_API_BASE_URL=...`.
  static String get airWritingApiBaseUrl {
    if (_envAirWritingApiBaseUrl.isNotEmpty) return _envAirWritingApiBaseUrl;
    return _renderAirWritingApiBaseUrl;
  }

  /// Clé API : `--dart-define=MA3AK_API_KEY=...` en priorité, sinon
  /// [_fallbackAiModuleApiKey] (évite les 401 quand le dart-define est oublié).
  /// Timeouts réseau : `lib/data/api/ai_module_api_client.dart` (cold start Render).
  static String? get aiModuleApiKey {
    final value = _envAiModuleApiKey.trim();
    if (value.isNotEmpty) return value;
    final fallback = _fallbackAiModuleApiKey.trim();
    return fallback.isEmpty ? null : fallback;
  }
}
