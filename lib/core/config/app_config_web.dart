import 'resolve_ma3ak_api_base_url.dart';

/// Web : pas de `dart:io` ; défaut local `localhost:3000` (adapter via `API_PORT` si besoin).
String getDefaultApiBaseUrl() {
  const port = String.fromEnvironment('API_PORT', defaultValue: '3000');
  final local = 'http://localhost:$port';
  return resolveMa3akApiBaseUrl(defaultLocalUrl: local);
}

String getDefaultStressApiUrl() => 'http://localhost:8000';

String getDefaultAiModuleBaseUrl() => 'https://ai-module-navigation.onrender.com';

String? getDefaultAiModuleSecondaryBaseUrl() => null;

String getDefaultEyeNavigationBaseUrl() =>
    'https://ai-module-navigation.onrender.com';
