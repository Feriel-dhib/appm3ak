# Air Writing Flutter (local TFLite)

## 1) Export du modele

Depuis `/Users/Apple/air_writing` :

```bash
cd /Users/Apple/air_writing
.venv/bin/python convert_to_tflite.py --input model/model.h5 --output model/model.tflite --quantize
```

Puis copier les assets dans Flutter :

```bash
cp /Users/Apple/air_writing/model/model.tflite /Users/Apple/Desktop/appm3ak/assets/models/air_writing.tflite
cp /Users/Apple/air_writing/model/hand_landmarker.task /Users/Apple/Desktop/appm3ak/assets/models/hand_landmarker.task
```

## 2) Lancer l'application

```bash
cd /Users/Apple/Desktop/appm3ak
flutter pub get
flutter run
```

## 3) Checklist tests manuels

- Ouvrir **Air Writing** (`/air-writing` ou module `flutter run -t lib/main_air_writing.dart`).
- **iOS** et **Android** : caméra + landmarks (overlay trajectoire + point index).
- Geste d’écriture : index tendu, autres doigts repliés → état « Écriture ».
- Après une pause (défaut ~1,5 s) : prédiction top-k ; si confiance inférieure au seuil, pas d’ajout au texte.
- Boutons : reset trajectoire, backspace, clear, espace.
- Sliders : `minConfidence`, `pauseMs`, `minPoints`, **lissage (fenêtre)**.
- Activer **Debug** (AppBar) : logs `points accumulés`, pause, prédiction / confiance / acceptée.
