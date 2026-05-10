M3AK — Modèle TFLite YOLOv8 (sync obstacle-detection-assistant)
================================================================

Fichier attendu par l’app Flutter : assets/models/m3ak_yolov8.tflite

Entrée typique (float) : [1, H, W, 3] NHWC, 0–1, H=W=imgsz (320 ou 640).
Sortie typique : [1, 84, N] ou [1, N, 84], N=2100 @ imgsz 320 ; N=8400 @ imgsz 640.

Flutter : lib/features/detection/config/detection_config.dart
  - modelAssetPath, inputWidth, inputHeight, numPredictions
  - detectAllCoco80, obstacleClassIndices, confidenceThreshold, iouThreshold,
    minBoxAreaFraction, walkingZoneYMin

Export Python :
  scripts/export_ma3ak_tflite.py --model <best.pt|m3ak_val2017.pt> --imgsz 320 --verify
