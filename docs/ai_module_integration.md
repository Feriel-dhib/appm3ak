# Intégration AI Module Flask

Ce document décrit l’intégration entre l’app Flutter Ma3ak et le backend local
`/Users/Apple/ai_module`.

## Fichiers Flutter ajoutés

- `lib/data/api/ai_module_api_client.dart` : client `Dio` dédié, sans JWT.
- `lib/data/models/ai/` : modèles typés pour `/health`, `/stt`, `/tts`, `/air-click`, `/adapt`.
- `lib/data/repositories/ai_module_repository.dart` : couche métier et normalisation des erreurs.
- `lib/providers/ai_module_providers.dart` : providers Riverpod pour santé du service et mode adapté.
- `lib/core/errors/ai_module_exception.dart` : erreurs AI standardisées.
- `test/data/ai_module_models_test.dart` et `test/data/ai_module_repository_test.dart` : tests unitaires ciblés.

## Configuration

Le backend Flask est configuré séparément de l’API Ma3ak principale.

```bash
flutter run \
  --dart-define=AI_MODULE_BASE_URL=https://ai-module-navigation.onrender.com \
  --dart-define=MA3AK_API_KEY=...
```

Défauts:

- Par défaut (dev/prod): `https://ai-module-navigation.onrender.com`
- Override utile: `AI_MODULE_BASE_URL` (ex: backend local)
- Clé API: `MA3AK_API_KEY` injectée via `--dart-define`

Authentification:

- Endpoint public: `GET /health` (sans clé)
- Routes protégées (ex: `POST /adapt`): header `X-API-Key` requis

## Lancer le backend

Depuis le parent du dossier `ai_module`:

```bash
cd /Users/Apple
python -m ai_module.api.app
```

Le service expose par défaut:

- `GET /health`
- `POST /stt`
- `POST /tts`
- `POST /air-click`
- `POST /adapt`

## Contrats API

### `GET /health`

Réponse:

```json
{ "status": "ok" }
```

### `POST /stt`

Requête `multipart/form-data`, champ obligatoire `audio`.

Réponse:

```json
{ "text": "..." }
```

### `POST /tts`

Requête:

```json
{ "text": "..." }
```

Réponse:

```json
{ "message": "Text spoken successfully." }
```

Important: le backend déclenche pyttsx3 sur la machine serveur. Il ne renvoie pas de fichier audio au téléphone. L’app conserve donc `flutter_tts` comme voix principale.

### `POST /air-click`

Classifie un geste de la main à partir de landmarks normalisés MediaPipe.

Requête:

```json
{
  "landmarks": {
    "0": { "x": 0.50, "y": 0.50, "z": 0.0 },
    "4": { "x": 0.10, "y": 0.20, "z": 0.0 },
    "8": { "x": 0.12, "y": 0.21, "z": 0.0 }
  },
  "client_id": "motor-XYZ"
}
```

- `landmarks` (**requis**) : dictionnaire `id -> {x, y, z}`. Les ids `4`
  (pouce) et `8` (index) sont obligatoires. L'id `0` (poignet) est optionnel
  mais fortement recommandé : il permet la détection de mouvement.
- `client_id` (optionnel) : identifiant stable par appareil/session. Le
  backend conserve un état (compteur de pinch, historique de positions)
  par client. Si absent, l'IP du client est utilisée comme fallback.

Réponse:

```json
{ "action": "click", "confidence": 0.78 }
```

Actions possibles :

| Action | Signification | Logique |
|--------|---------------|---------|
| `idle` | Main visible mais aucun geste | Fingers ouverts ET poignet immobile, ou landmarks invalides (`0,0,0`) |
| `move` | La main bouge (curseur / focus) | Fingers ouverts ET déplacement du poignet ≥ `AIR_MOVE_THRESHOLD` |
| `click` | Pinch détecté | Distance pouce-index < `AIR_CLICK_THRESHOLD` |
| `hold` | Pinch maintenu | `click` stable pendant ≥ `AIR_HOLD_FRAMES` frames |

`confidence` est une valeur dans `[0, 1]` :

- Pour `click` : plus le pinch est serré, plus la valeur est proche de 1.
- Pour `hold` : plus le pinch est maintenu longtemps, plus la valeur grandit.
- Pour `move` : plus le mouvement est ample, plus la valeur grandit.
- Pour `idle` : toujours `0.0`.

Notes d'implémentation :

- Les landmarks dont `x` et `y` sont `~0` sont considérés comme manquants
  (le tracker n'a pas pu localiser ce joint) et **ne déclenchent pas** de
  pinch fantôme.
- L'état est par client : un appareil A qui maintient un pinch ne fait pas
  basculer un appareil B en mode `hold`.
- L'état d'un client absent depuis ~600 requêtes est purgé automatiquement.

### `POST /adapt`

Requête:

```json
{ "user_type": "blind" }
```

Réponse:

```json
{ "mode": "voice_mode" }
```

Mappings attendus:

- `blind` -> `voice_mode`
- `deaf` -> `text_mode`
- `motor` -> `gesture_mode`

## Flux accessibilité intégrés

- Déficience visuelle : le mode `voice_mode` active un appel best-effort à `/tts` dans le chat santé, tout en gardant le TTS local.
- Déficience auditive : l’écran captions affiche l’état du module AI et conserve les captions locales si le backend est indisponible.
- Déficience motrice : `MotorGestureModeScreen` est **autonome** (switch-scanning + boutons), avec appels manuels `/air-click` pour tester. Il ne dépend pas du plugin natif MediaPipe.

## air-click vs air-writing (à ne pas confondre)

| | **air-click** (`MotorGestureModeScreen`) | **air-writing** (`AirWritingPage`) |
|---|---|---|
| But | Naviguer (move / click / hold) | Écrire des lettres en l'air |
| Plugin natif MediaPipe (`ma3ak/air_writing_hand_tracker`) | **Non requis** | Requis |
| TFLite `air_writing.tflite` | Non requis | Requis |
| Endpoint | `/air-click` (manuel, optionnel) | `/air-click` (best-effort, optionnel) |
| Statut | Stable | Expérimental |

Conséquence : si le plugin natif MediaPipe ou le modèle TFLite ne sont pas
disponibles, **seul** `AirWritingPage` est affecté. Le mode gestes
(`MotorGestureModeScreen`) reste 100 % fonctionnel.

## Limitations connues

- `/stt` nécessite un fichier audio; les écrans existants utilisent encore majoritairement `speech_to_text` en streaming local.
- `/tts` parle côté serveur et n’est pas une vraie sortie audio mobile.
- `/air-click` suppose des landmarks MediaPipe normalisés; l’app normalise les coordonnées image avant l’envoi.
- Whisper `base` peut être lent sur machine faible; préférer des extraits audio courts.
- `AirWritingPage` dépend d'un canal natif iOS/Android non implémenté par défaut. Tant qu'il n'est pas porté, la page reste expérimentale.

## Tests

```bash
flutter test test/data/ai_module_models_test.dart test/data/ai_module_repository_test.dart
```
