import 'app_config_stub.dart'
    if (dart.library.html) 'app_config_web.dart'
    if (dart.library.io) 'app_config_io.dart'
    as impl;

/// Configuration de l'application Ma3ak.
/// Les valeurs peuvent être surchargées via --dart-define ou environnement.
class AppConfig {
  AppConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _envStressApiUrl = String.fromEnvironment(
    'STRESS_API_URL',
    defaultValue: '',
  );

  static const String _envAiBaseUrl = String.fromEnvironment(
    'AI_BASE_URL',
    defaultValue: '',
  );

  static const String _envAccessibilityAiBaseUrl = String.fromEnvironment(
    'ACCESSIBILITY_AI_BASE_URL',
    defaultValue: '',
  );

  static const String _envAiModuleBaseUrl = String.fromEnvironment(
    'AI_MODULE_BASE_URL',
    defaultValue: '',
  );
  static const String _envAiModuleBaseUrlSecondary = String.fromEnvironment(
    'AI_MODULE_BASE_URL_2',
    defaultValue: '',
  );

  static const String _envEyeNavigationBaseUrl = String.fromEnvironment(
    'EYE_NAVIGATION_BASE_URL',
    defaultValue: '',
  );

  /// **BASE_URL_API** (origine NestJS, sans chemin `/api` sauf si déjà inclus dans l’URL).
  ///
  /// Utilisée par Dio pour les routes (`/user/me`, …) et pour résoudre les photos
  /// relatives `uploads/...` : URL affichée = `apiBaseUrl` + `/` + `photoProfil`.
  ///
  /// **Développement (debug)** : défauts locaux (`app_config_io.dart` / web) ou
  /// `--dart-define=API_BASE_URL=...` / `--dart-define=DEV_LAN_HOST=...` /
  /// `--dart-define=API_PORT=3000`.
  ///
  /// **Production / staging (release)** : par défaut l’URL Render (`kMa3akNestJsBaseUrl`).
  /// Surcharges :
  /// `--dart-define=API_BASE_URL=...` ou `--dart-define=MA3AK_ENV=production|staging`.
  ///
  /// **Flutter Web** : l’origine du front doit être autorisée dans `CORS_ORIGINS` sur Render.
  static String get apiBaseUrl {
    if (_envApiBaseUrl.isNotEmpty) return _envApiBaseUrl;
    return impl.getDefaultApiBaseUrl();
  }

  /// Base FastAPI / IA (port 8002 par défaut). Surcharge : `--dart-define=AI_BASE_URL=...`.
  static String get aiBaseUrl {
    if (_envAiBaseUrl.isNotEmpty) {
      return _envAiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    return impl.getDefaultAiBaseUrl().replaceAll(RegExp(r'/+$'), '');
  }

  /// Backend FastAPI analyse d'accessibilité (Groq + OSM).
  static String get accessibilityAiBaseUrl {
    if (_envAccessibilityAiBaseUrl.isNotEmpty) {
      return _envAccessibilityAiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    }
    return impl.getDefaultAccessibilityAiBaseUrl();
  }

  /// Alias sémantique (Socket.IO, URLs publiques).
  static String get baseUrl => apiBaseUrl;

  /// Service Python d’analyse stress vocal (MFCC). Surcharge : `--dart-define=STRESS_API_URL=...`.
  static String get stressAudioApiUrl {
    if (_envStressApiUrl.isNotEmpty) return _envStressApiUrl;
    return impl.getDefaultStressApiUrl();
  }

  /// Backend Flask AI local (Whisper, pyttsx3, air-click, adaptation).
  /// Surcharge : `--dart-define=AI_MODULE_BASE_URL=...`.
  static String get aiModuleBaseUrl {
    if (_envAiModuleBaseUrl.isNotEmpty) return _envAiModuleBaseUrl;
    return impl.getDefaultAiModuleBaseUrl();
  }

  /// Deuxième backend IA optionnel (ex: ai-model).
  /// Surcharge : `--dart-define=AI_MODULE_BASE_URL_2=...`.
  static String? get aiModuleSecondaryBaseUrl {
    if (_envAiModuleBaseUrlSecondary.isNotEmpty) {
      return _envAiModuleBaseUrlSecondary;
    }
    return impl.getDefaultAiModuleSecondaryBaseUrl();
  }

  /// Backend Flask **navigation par regard** (`POST /eye-navigation`, multipart).
  /// Surcharge : `--dart-define=EYE_NAVIGATION_BASE_URL=http://10.0.2.2:5001`.
  static String get eyeNavigationBaseUrl {
    if (_envEyeNavigationBaseUrl.isNotEmpty) return _envEyeNavigationBaseUrl;
    return impl.getDefaultEyeNavigationBaseUrl();
  }

  /// Identique à [apiBaseUrl] ; les chemins `uploads/...` sont concaténés à cette base
  /// pour l’affichage des photos de profil.
  static String get uploadsBaseUrl => apiBaseUrl;

  /// Mode démo : navigation sans compte (`--dart-define=ALLOW_GUEST=true`).
  static const bool allowGuest = bool.fromEnvironment(
    'ALLOW_GUEST',
    defaultValue: false,
  );

  /// Forcer l’écran de connexion au démarrage (`--dart-define=FORCE_LOGIN_ON_START=true`).
  static const bool forceLoginOnStart = bool.fromEnvironment(
    'FORCE_LOGIN_ON_START',
    defaultValue: false,
  );

  /// Résumés post/commentaires via `/ai/community/*` (`--dart-define=AI_COMMUNITY_REMOTE=true`).
  static const bool aiCommunityRemoteEnabled = bool.fromEnvironment(
    'AI_COMMUNITY_REMOTE',
    defaultValue: false,
  );
}
