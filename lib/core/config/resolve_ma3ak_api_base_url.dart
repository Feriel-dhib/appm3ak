import 'package:flutter/foundation.dart';

import 'ma3ak_api_origins.dart';

bool _isExplicitLocalEnv(String env) {
  switch (env) {
    case 'local':
    case 'development':
    case 'dev':
      return true;
    default:
      return false;
  }
}

/// Résout l’URL de base de l’API quand `API_BASE_URL` n’est pas fournie via
/// `--dart-define`.
///
/// Priorité implicite :
/// - `MA3AK_ENV=staging|production` → [kMa3akNestJsBaseUrl]
/// - `MA3AK_ENV=local|development|dev` → URL locale (émulateur / LAN / web dev)
/// - sinon : tout build **non debug** (release **et** profile) → Render
/// - sinon : **debug** → URL locale, sauf [useRemoteWhenPhysicalDebug] (téléphone réel
///   sans `DEV_LAN_HOST` : localhost / `10.0.2.2` ne menent pas au Mac)
///
/// (`kProfileMode` n’est pas `kReleaseMode` : un APK profile doit aussi viser Render.)
String resolveMa3akApiBaseUrl({
  required String defaultLocalUrl,
  bool useRemoteWhenPhysicalDebug = false,
}) {
  const ma3akEnv = String.fromEnvironment('MA3AK_ENV', defaultValue: '');
  final normalized = ma3akEnv.trim().toLowerCase();

  if (normalized == 'staging' || normalized == 'production') {
    return kMa3akNestJsBaseUrl;
  }
  if (_isExplicitLocalEnv(normalized)) {
    return defaultLocalUrl;
  }
  if (!kDebugMode) {
    return kMa3akNestJsBaseUrl;
  }
  if (useRemoteWhenPhysicalDebug) {
    return kMa3akNestJsBaseUrl;
  }
  return defaultLocalUrl;
}
