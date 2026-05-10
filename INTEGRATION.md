# Integration Air Writing - Ma3ak

Ce document explique comment brancher la page `AirWritingPage` dans la navigation existante.

## 1) Fichiers ajoutes

- `air_writing/convert_to_tflite.py`
- `lib/air_writing/hand_tracker.dart`
- `lib/air_writing/gesture_detector.dart`
- `lib/air_writing/trajectory_buffer.dart`
- `lib/air_writing/renderer.dart`
- `lib/air_writing/predictor.dart`
- `lib/air_writing/air_writing_page.dart`
- `lib/main_air_writing.dart`

## 2) Conversion du modele (Keras → TFLite)

Les sources du CNN sont dans le dépôt Python séparé `air_writing` (ex. `/Users/Apple/air_writing`).

Commande exacte utilisée pour produire le `.tflite` quantifié (dynamic range) à partir de `model/model.h5` :

```bash
cd /Users/Apple/air_writing
.venv/bin/python convert_to_tflite.py --input model/model.h5 --output model/model.tflite --quantize
```

Puis copie vers les assets Flutter Ma3ak :

```bash
cp model/model.tflite /chemin/vers/appm3ak/assets/models/air_writing.tflite
```

Sans quantification (fichier plus lourd) :

```bash
.venv/bin/python convert_to_tflite.py --input model/model.h5 --output model/model.tflite
```

Le fichier attendu dans l’app est `assets/models/air_writing.tflite`.

## 3) Ajouter la route dans GoRouter

Dans `lib/router/app_router.dart`:

1. Ajouter l'import:

```dart
import '../air_writing/air_writing_page.dart';
```

2. Ajouter une route:

```dart
GoRoute(
  path: '/air-writing',
  builder: (_, __) => const AirWritingPage(),
),
```

## 4) Ajouter un point d'acces UI

Exemples:

- Bouton dans `home_screen.dart`
- Item dans `main_shell.dart`
- Carte d'outil d'accessibilite

Navigation:

```dart
context.go('/air-writing');
```

## 5) Test rapide hors navigation Ma3ak

Pour lancer juste le module:

```bash
flutter run -t lib/main_air_writing.dart
```

## 6) Important: plugin natif de landmarks main

Le tracker est base sur `MethodChannel` (même nom sur **iOS** et **Android**) :

- **iOS** : `ios/Runner/HandTrackerPlugin.swift` — Apple Vision `VNDetectHumanHandPoseRequest`.
- **Android** : `android/.../HandTrackerPlugin.kt` — MediaPipe `HandLandmarker` (dépendance `com.google.mediapipe:tasks-vision`), copie de `assets/models/hand_landmarker.task` vers le stockage interne au premier `initialize`.

- Channel: `ma3ak/air_writing_hand_tracker`
- Methodes attendues:
  - `initialize`
  - `detectHandLandmarks`
  - `dispose`

Le code Dart attend une reponse `detectHandLandmarks` de la forme:

```json
{
  "landmarks": [
    { "x": 123.4, "y": 456.7, "z": -0.02 }
  ]
}
```

avec 21 landmarks minimum pour appliquer le geste d'ecriture.

## 7) Assets requis

- `assets/models/air_writing.tflite`
- Optionnel mais recommande pour MediaPipe Tasks:
  - `assets/models/hand_landmarker.task`

Si vous embarquez `hand_landmarker.task`, ajoutez-le dans le dossier `assets/models/`.

## 8) Parametres metier deja configures

- Seuil pause: 1.5 s
- Confiance minimale: 0.40
- Minimum points inferes: 15
- Lissage: moving average fenetre 5
- Filtrage bruit: < 2 px ignore
- Effacement trajectoire apres prediction
- Haptique a chaque caractere valide
- Annonce vocale (toggle UI)
