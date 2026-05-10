# Prompt pour l’IA responsable du modèle de détection d’obstacles

Copier-coller le bloc ci-dessous à l’IA qui doit générer ou exporter le modèle TFLite.

---

## Prompt à donner à l’IA

```
Tu es chargé de produire le fichier de modèle TensorFlow Lite utilisé par l’application Flutter "Ma3ak" pour la détection d’obstacles en temps réel (assistance aux personnes malvoyantes).

## Contraintes strictes

1. **Architecture**
   - Modèle : **YOLOv8** (de préférence nano `yolov8n` pour le mobile).
   - Dataset : **COCO 80 classes** (les classes utiles pour l’app sont notamment : person, bicycle, car, motorcycle, bus, truck, chair, couch, potted plant, bed, dining table).

2. **Entrée (input)**
   - Shape : ** [1, 320, 320, 3]**
   - Type : **Float32**
   - Valeurs : pixels RGB normalisés entre **0.0 et 1.0** (l’app fait déjà `/255` sur les RGB 0–255).
   - Ordre : **NHWC** (batch, height, width, channels).

3. **Sortie (output)**
   - Shapes supportées : **`[1, 84, N]`** ou **`[1, N, 84]`** avec **N = 2100** pour **imgsz 320**, **N = 8400** pour **imgsz 640** (voir `assets/models/MODEL_README.txt`).
   - 84 = 4 (x_center, y_center, width, height) + 80 (scores de classes COCO).
   - Type : **Float32** (ou compatible, l’app lit en `Float32List`).
   - Layout « 84 × N » : pour l’ancre `i`, x = tensor[0*N+i], …, scores classe c = tensor[(4+c)*N+i].

4. **Format et fichier**
   - Format : **TensorFlow Lite** (`.tflite`).
   - Quantification : **INT8** recommandée pour la taille et la vitesse sur mobile (le nom du fichier cible inclut `int8`).
   - Nom du fichier à livrer : **m3ak_yolov8.tflite** (renommer l’export si besoin)
   - Emplacement : **assets/models/m3ak_yolov8.tflite**

5. **Export depuis Ultralytics (Python)**
   - Exemple dépôt M3AK : `scripts/export_ma3ak_tflite.py --model <best.pt> --imgsz 320 --verify`.
   - Vérifier **N** (2100 vs 8400) avec la même **imgsz** que dans `detection_config.dart`.

## Livrable

- Un fichier **m3ak_yolov8.tflite** prêt à être copié dans `assets/models/` du projet Flutter.
- Optionnel : un court README ou un fichier texte listant les shapes exactes d’entrée/sortie du modèle livré pour vérification.
```

---

## Référence technique côté app (pour vérification)

- **Config** : `lib/features/detection/config/detection_config.dart` — `inputWidth` / `inputHeight` = 320 ou 640 ; `numPredictions` = **2100** (320) ou **8400** (640) ; `modelAssetPath` = `assets/models/m3ak_yolov8.tflite`.
- **Préprocessing** : `yolo_tflite_runner.dart` — entrée 4D **[1, H, W, 3]** float 0–1 (ou uint8/int8 selon le modèle).
- **Post-processing** : `parseYoloOutput` gère **(1, 84, N)** et **(1, N, 84)** ; **N** inféré à l’exécution depuis le tenseur de sortie.

Utiliser ce prompt pour l’export TFLite aligné avec le dépôt **obstacle-detection-assistant** et l’app Ma3ak.