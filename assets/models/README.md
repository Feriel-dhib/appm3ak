# Modèle pour la détection d’obstacles (M3AK / YOLOv8)

L’écran **Détection d’obstacles** charge un fichier **TensorFlow Lite** exporté depuis le dépôt Python **obstacle-detection-assistant** (`scripts/export_ma3ak_tflite.py`).

---

## Fichier attendu

| | |
|--|--|
| **Nom** | `m3ak_yolov8.tflite` |
| **Chemin** | `appm3ak/assets/models/m3ak_yolov8.tflite` |

Après export, copiez ou renommez le `.tflite` produit en **`m3ak_yolov8.tflite`** dans ce dossier.

---

## Alignement avec `MODEL_README.txt` (repo Python)

- **Entrée :** `[1, H, W, 3]` float **NHWC**, valeurs **0–1** (ou uint8/int8 selon l’export ; l’app adapte le prétraitement).
- **Sortie YOLOv8 :** `[1, 84, N]` ou `[1, N, 84]` avec **N = 2100** si **imgsz = 320**, **N = 8400** si **imgsz = 640**.
- Dans le code Flutter (`lib/features/detection/config/detection_config.dart`), réglez **`inputWidth`**, **`inputHeight`** et **`numPredictions`** pour correspondre à votre export.
- Référence commande côté Python :  
  `python scripts/export_ma3ak_tflite.py --model <chemin_vers_best.pt> --imgsz 320 --verify`

---

## Comportement (équivalent `config/settings.py`)

- **`detectAllCoco80`** : `true` → les 80 classes COCO sont utilisées ; `false` → filtre sur **`obstacleClassIndices`** (obstacles explicites + bottle, book, hair drier, etc.).
- Seuils typiques : confiance **~0.40**, NMS IoU **~0.50**, **zone de marche** = moitié basse de l’image (**y** centre ≥ **0.5**).

---

## Après ajout du fichier

Faire un **run complet** (`flutter run`), pas seulement un hot reload.

---

**Résumé :** placez **`m3ak_yolov8.tflite`** dans **`assets/models/`**, avec **imgsz / N** cohérents avec `det detection_config.dart`.
