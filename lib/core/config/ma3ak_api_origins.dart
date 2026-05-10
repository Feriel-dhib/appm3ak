/// Origine publique de l’API NestJS Ma3ak (déploiement Render).
///
/// Pour **Flutter Web**, l’origine du front (ex. `http://localhost:8080` ou l’URL
/// d’hébergement) doit figurer dans **`CORS_ORIGINS`** côté backend Render ;
/// sinon le navigateur bloque les appels malgré une [apiBaseUrl] correcte.
const String kMa3akNestJsBaseUrl = 'https://backend-m3ak.onrender.com';
