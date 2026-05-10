import 'package:flutter/foundation.dart';

/// URL de base du backend FastAPI (port 8000 par défaut).
///
/// **Émulateur Android** : par défaut `http://10.0.2.2:8000`.
///
/// **Téléphone / tablette physique** : le PC n’est pas à `10.0.2.2`.
/// - Option A — même Wi‑Fi : lancez avec l’IP locale du PC, par exemple  
///   `flutter run --dart-define=M3AK_API_HOST=192.168.1.42`
/// - Option B — USB : `adb reverse tcp:8000 tcp:8000` puis  
///   `flutter run --dart-define=M3AK_API_BASE_URL=http://127.0.0.1:8000`
///
/// **URL complète** (autre port ou HTTPS) :  
/// `flutter run --dart-define=M3AK_API_BASE_URL=http://192.168.1.42:8000`
///
/// Fichier : copie `dart_defines.example.json` → `dart_defines.json`, puis  
/// `flutter run --dart-define-from-file=dart_defines.json` (voir `INTEGRATION.md`).
String resolveM3akApiBaseUrl() {
  const full = String.fromEnvironment('M3AK_API_BASE_URL', defaultValue: '');
  if (full.isNotEmpty) {
    return full.replaceAll(RegExp(r'/$'), '');
  }

  const hostOnly = String.fromEnvironment('M3AK_API_HOST', defaultValue: '');

  if (kIsWeb) {
    final scheme = Uri.base.scheme.isEmpty ? 'http' : Uri.base.scheme;
    final host = Uri.base.host.isEmpty ? 'localhost' : Uri.base.host;
    return '$scheme://$host:8000';
  }

  if (defaultTargetPlatform == TargetPlatform.android) {
    if (hostOnly.isNotEmpty) {
      return 'http://$hostOnly:8000';
    }
    return 'http://10.0.2.2:8000';
  }

  return 'http://127.0.0.1:8000';
}
