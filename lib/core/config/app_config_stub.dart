import 'resolve_ma3ak_api_base_url.dart';

/// Fallback (plateforme sans `dart:io` ni `dart:html`) — même logique que le web.
String getDefaultApiBaseUrl() {
  const port = String.fromEnvironment('API_PORT', defaultValue: '3000');
  return resolveMa3akApiBaseUrl(defaultLocalUrl: 'http://localhost:$port');
}

String getDefaultStressApiUrl() => 'http://localhost:8000';

String getDefaultAiModuleBaseUrl() => 'https://ai-module-navigation.onrender.com';

String? getDefaultAiModuleSecondaryBaseUrl() => null;

String getDefaultEyeNavigationBaseUrl() =>
    'https://ai-module-navigation.onrender.com';
