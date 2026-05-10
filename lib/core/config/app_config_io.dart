import 'dart:io';

import 'ma3ak_device_context.dart';
import 'resolve_ma3ak_api_base_url.dart';

/// Défauts : Android émulateur → `http://10.0.2.2:3000`, iOS simulateur → `http://localhost:3000`.
///
/// **Téléphone réel** sans `DEV_LAN_HOST` : en debug, préférence pour l’API Render
/// ([Ma3akDeviceContext]) car `localhost` / `10.0.2.2` ne joignent pas le Mac.
/// Backend local sur appareil réel : `--dart-define=DEV_LAN_HOST=<IP Wi‑Fi du Mac>`.
///
/// Port : `--dart-define=API_PORT=3000`. URL complète : `API_BASE_URL` dans [AppConfig].
///
/// **Profile / release** : sans surcharges, l’API pointe vers Render
/// (`resolve_ma3ak_api_base_url.dart`).
String getDefaultApiBaseUrl() {
  const host = String.fromEnvironment('DEV_LAN_HOST', defaultValue: '');
  const port = String.fromEnvironment('API_PORT', defaultValue: '3000');

  final String local;
  if (host.isNotEmpty) {
    local = 'http://$host:$port';
  } else if (Platform.isAndroid) {
    local = 'http://10.0.2.2:$port';
  } else {
    local = 'http://localhost:$port';
  }

  final physicalNoLan =
      Ma3akDeviceContext.isPhysicalMobileDevice == true && host.isEmpty;

  return resolveMa3akApiBaseUrl(
    defaultLocalUrl: local,
    useRemoteWhenPhysicalDebug: physicalNoLan,
  );
}

/// Serveur stress audio (ex. Python sur :8000). Émulateur Android → `10.0.2.2`.
String getDefaultStressApiUrl() {
  if (Platform.isAndroid) return 'http://10.0.2.2:8000';
  return 'http://127.0.0.1:8000';
}

/// Backend Flask AI (Whisper/TTS/air-click/adapt), port 5001 par défaut.
String getDefaultAiModuleBaseUrl() {
  const deployed = 'https://ai-module-navigation.onrender.com';
  const host = String.fromEnvironment('AI_MODULE_HOST', defaultValue: '');
  const port = String.fromEnvironment('AI_MODULE_PORT', defaultValue: '5001');

  if (host.isNotEmpty) return 'http://$host:$port';
  return deployed;
}

/// Deuxième backend IA optionnel (vide par défaut).
String? getDefaultAiModuleSecondaryBaseUrl() {
  const direct = String.fromEnvironment('AI_MODULE_2_HOST', defaultValue: '');
  const port = String.fromEnvironment('AI_MODULE_2_PORT', defaultValue: '8080');
  if (direct.isNotEmpty) {
    return 'http://$direct:$port';
  }
  return null;
}

/// Flask eye-navigation — même origine que le module IA en prod Render.
String getDefaultEyeNavigationBaseUrl() {
  const deployed = 'https://ai-module-navigation.onrender.com';
  const host = String.fromEnvironment('EYE_NAVIGATION_HOST', defaultValue: '');
  const port = String.fromEnvironment('EYE_NAVIGATION_PORT', defaultValue: '5001');

  if (host.isNotEmpty) return 'http://$host:$port';
  return deployed;
}
