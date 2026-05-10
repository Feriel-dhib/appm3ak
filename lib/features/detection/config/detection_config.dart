import 'coco80_labels.dart';

/// Configuration du pipeline de détection d'obstacles (alignée sur obstacle-detection-assistant,
/// config/settings.py et MODEL_README : entrée float NHWC 0–1, sortie [1, 84, N]).

class DetectionConfig {
  DetectionConfig._();

  /// Fichier TFLite produit par `scripts/export_ma3ak_tflite.py` (copier depuis le dépôt Python).
  /// Renommer l’export en **m3ak_yolov8.tflite** dans ce dossier si besoin.
  static const String modelAssetPath = 'assets/models/m3ak_yolov8.tflite';

  /// Résolution d’entrée : **doit** correspondre à `--imgsz` à l’export (320 ou 640).
  static const int inputWidth = 320;
  static const int inputHeight = 320;

  /// Nombre d’ancres en sortie : **2100** pour imgsz **320**, **8400** pour imgsz **640**
  /// (tensor [1, 84, N] ou [1, N, 84] selon l’export).
  static const int numPredictions = 2100;

  /// `DETECT_ALL_COCO80` : si true, toutes les classes COCO sont traitées ; sinon filtre [obstacleClassIndices].
  /// False = demo salle / faculte (aligné config/settings.py).
  static const bool detectAllCoco80 = false;

  /// Seuil confiance (aligné config/settings.py CONFIDENCE_THRESHOLD).
  static const double confidenceThreshold = 0.48;

  /// IoU NMS (settings Python ~0.50).
  static const double iouThreshold = 0.50;

  /// `MIN_BOX_AREA_FRACTION` : surface min. de la boîte (coords normalisées 0–1).
  static const double minBoxAreaFraction = 0.001;

  static const double focalLengthApprox = 400.0;

  /// `WALKING_ZONE_TOP` = 0.5 → on ne garde que la moitié **basse** (y centre ≥ 0.5).
  static const double walkingZoneYMin = 0.50;

  static const double distanceCriticalMeters = 2.0;
  static const double distanceWarningMeters = 4.0;

  /// Délai minimum **après la fin** d’une annonce vocale avant la suivante (accessibilité).
  static const double cooldownGlobalSeconds = 4.0;
  static const double cooldownZoneSeconds = 2.5;
  /// Pause après chaque phrase pour laisser le moteur TTS terminer et « respirer ».
  static const double postSpeakPauseSeconds = 0.65;

  /// `OBSTACLE_CLASSES` (ids COCO) — salle / faculte (aligné obstacle-detection-assistant config/settings.py).
  static const Set<int> obstacleClassIndices = {
    0, // person
    13, // bench
    24, // backpack
    25, // umbrella
    26, // handbag
    39, // bottle
    41, // cup
    56, // chair
    58, // potted plant
    60, // dining table
    62, // tv
    63, // laptop
    64, // mouse
    65, // remote
    66, // keyboard
    67, // cell phone
    73, // book
    74, // clock
  };

  /// Libellé COCO officiel (avec espaces) pour l’indice, ex. 78 → « hair drier ».
  static String labelForCocoIndex(int classIndex) {
    if (classIndex >= 0 && classIndex < kCoco80ClassNames.length) {
      return kCoco80ClassNames[classIndex];
    }
    return 'object';
  }

  /// Hauteurs de référence (m) pour estimation de distance ; clés = noms COCO [coco80_labels].
  static const Map<String, double> objectHeightsMeters = {
    'person': 1.7,
    'bicycle': 1.2,
    'car': 1.5,
    'motorcycle': 1.5,
    'airplane': 3.0,
    'bus': 3.0,
    'train': 4.0,
    'truck': 2.5,
    'boat': 2.0,
    'traffic light': 3.0,
    'fire hydrant': 0.9,
    'stop sign': 2.2,
    'parking meter': 1.2,
    'bench': 0.8,
    'bird': 0.2,
    'cat': 0.25,
    'dog': 0.5,
    'horse': 1.6,
    'sheep': 0.9,
    'cow': 1.5,
    'elephant': 2.5,
    'bear': 1.2,
    'zebra': 1.5,
    'giraffe': 3.5,
    'backpack': 0.5,
    'umbrella': 1.0,
    'handbag': 0.3,
    'tie': 0.3,
    'suitcase': 0.6,
    'frisbee': 0.3,
    'skis': 1.6,
    'snowboard': 1.4,
    'sports ball': 0.24,
    'kite': 0.5,
    'baseball bat': 0.9,
    'baseball glove': 0.3,
    'skateboard': 0.15,
    'surfboard': 0.5,
    'tennis racket': 0.7,
    'bottle': 0.25,
    'wine glass': 0.2,
    'cup': 0.1,
    'fork': 0.02,
    'knife': 0.02,
    'spoon': 0.02,
    'bowl': 0.08,
    'banana': 0.18,
    'apple': 0.08,
    'sandwich': 0.05,
    'orange': 0.08,
    'broccoli': 0.2,
    'carrot': 0.2,
    'hot dog': 0.05,
    'pizza': 0.03,
    'donut': 0.05,
    'cake': 0.15,
    'chair': 0.9,
    'couch': 0.8,
    'potted plant': 0.5,
    'bed': 0.5,
    'dining table': 0.75,
    'toilet': 0.5,
    'tv': 0.5,
    'laptop': 0.02,
    'mouse': 0.05,
    'remote': 0.03,
    'keyboard': 0.02,
    'cell phone': 0.15,
    'microwave': 0.3,
    'oven': 0.6,
    'toaster': 0.2,
    'sink': 0.3,
    'refrigerator': 1.7,
    'book': 0.25,
    'clock': 0.3,
    'vase': 0.25,
    'scissors': 0.02,
    'teddy bear': 0.25,
    'hair drier': 0.25,
    'toothbrush': 0.02,
  };

  /// Messages vocaux FR par nom de classe COCO (aligné ALERT_MESSAGES côté Python quand applicable).
  static const Map<String, String> alertMessagesFr = {
    'person': 'Personne devant.',
    'bicycle': 'Vélo devant.',
    'car': 'Voiture devant.',
    'motorcycle': 'Deux-roues motorisé devant.',
    'airplane': 'Avion devant.',
    'bus': 'Bus devant.',
    'train': 'Train devant.',
    'truck': 'Poids lourd devant.',
    'boat': 'Bateau devant.',
    'traffic light': 'Feu de signalisation devant.',
    'fire hydrant': 'Bouche à incendie devant.',
    'stop sign': 'Panneau stop devant.',
    'parking meter': 'Parcmètre devant.',
    'bench': 'Banc devant.',
    'bird': 'Oiseau devant.',
    'cat': 'Chat devant.',
    'dog': 'Chien devant.',
    'horse': 'Cheval devant.',
    'sheep': 'Mouton devant.',
    'cow': 'Vache devant.',
    'elephant': 'Éléphant devant.',
    'bear': 'Ours devant.',
    'zebra': 'Zèbre devant.',
    'giraffe': 'Girafe devant.',
    'backpack': 'Sac à dos devant.',
    'umbrella': 'Parapluie devant.',
    'handbag': 'Sac à main devant.',
    'tie': 'Cravate devant.',
    'suitcase': 'Valise devant.',
    'frisbee': 'Frisbee devant.',
    'skis': 'Skis devant.',
    'snowboard': 'Snowboard devant.',
    'sports ball': 'Balle devant.',
    'kite': 'Cerf-volant devant.',
    'baseball bat': 'Batte de baseball devant.',
    'baseball glove': 'Gant de baseball devant.',
    'skateboard': 'Skateboard devant.',
    'surfboard': 'Planche de surf devant.',
    'tennis racket': 'Raquette de tennis devant.',
    'bottle': 'Bouteille devant.',
    'wine glass': 'Verre à vin devant.',
    'cup': 'Tasse devant.',
    'fork': 'Fourchette devant.',
    'knife': 'Couteau devant.',
    'spoon': 'Cuillère devant.',
    'bowl': 'Bol devant.',
    'banana': 'Banane devant.',
    'apple': 'Pomme devant.',
    'sandwich': 'Sandwich devant.',
    'orange': 'Orange devant.',
    'broccoli': 'Brocoli devant.',
    'carrot': 'Carotte devant.',
    'hot dog': 'Hot-dog devant.',
    'pizza': 'Pizza devant.',
    'donut': 'Beignet devant.',
    'cake': 'Gâteau devant.',
    'chair': 'Chaise devant.',
    'couch': 'Canapé devant.',
    'potted plant': 'Plante en pot devant.',
    'bed': 'Lit devant.',
    'dining table': 'Table devant.',
    'toilet': 'Toilettes devant.',
    'tv': 'Télévision devant.',
    'laptop': 'Ordinateur portable devant.',
    'mouse': 'Souris devant.',
    'remote': 'Télécommande devant.',
    'keyboard': 'Clavier devant.',
    'cell phone': 'Téléphone portable devant.',
    'microwave': 'Four à micro-ondes devant.',
    'oven': 'Four devant.',
    'toaster': 'Grille-pain devant.',
    'sink': 'Évier devant.',
    'refrigerator': 'Réfrigérateur devant.',
    'book': 'Livre devant.',
    'clock': 'Horloge devant.',
    'vase': 'Vase devant.',
    'scissors': 'Ciseaux devants.',
    'teddy bear': 'Nounours devant.',
    'hair drier': 'Sèche-cheveux devant.',
    'toothbrush': 'Brosse à dents devant.',
  };

  static const Map<String, String> alertMessagesAr = {
    'person': 'شخص أمامك.',
    'bicycle': 'دراجة أمامك.',
    'car': 'سيارة أمامك.',
    'motorcycle': 'دراجة نارية أمامك.',
    'airplane': 'طائرة أمامك.',
    'bus': 'حافلة أمامك.',
    'train': 'قطار أمامك.',
    'truck': 'شاحنة أمامك.',
    'boat': 'قارب أمامك.',
    'traffic light': 'إشارة مرور أمامك.',
    'fire hydrant': 'صنبور إطفاء أمامك.',
    'stop sign': 'علامة توقف أمامك.',
    'parking meter': 'عداد وقوف أمامك.',
    'bench': 'مقعد أمامك.',
    'bird': 'طائر أمامك.',
    'cat': 'قطة أمامك.',
    'dog': 'كلب أمامك.',
    'horse': 'حصان أمامك.',
    'sheep': 'خروف أمامك.',
    'cow': 'بقرة أمامك.',
    'elephant': 'فيل أمامك.',
    'bear': 'دب أمامك.',
    'zebra': 'حمار وحشي أمامك.',
    'giraffe': 'زرافة أمامك.',
    'backpack': 'حقيبة ظهر أمامك.',
    'umbrella': 'مظلة أمامك.',
    'handbag': 'حقيبة يد أمامك.',
    'tie': 'ربطة عنق أمامك.',
    'suitcase': 'حقيبة سفر أمامك.',
    'frisbee': 'قرص أمامك.',
    'skis': 'زلاجات أمامك.',
    'snowboard': 'لوح تزلج أمامك.',
    'sports ball': 'كرة أمامك.',
    'kite': 'طائرة ورقية أمامك.',
    'baseball bat': 'مضرب بيسبول أمامك.',
    'baseball glove': 'قفاز بيسبول أمامك.',
    'skateboard': 'لوح تزلج بعجلات أمامك.',
    'surfboard': 'لوح ركوب أمامك.',
    'tennis racket': 'مضرب تنس أمامك.',
    'bottle': 'زجاجة أمامك.',
    'wine glass': 'كأس نبيذ أمامك.',
    'cup': 'فنجان أمامك.',
    'fork': 'شوكة أمامك.',
    'knife': 'سكين أمامك.',
    'spoon': 'ملعقة أمامك.',
    'bowl': 'وعاء أمامك.',
    'banana': 'موزة أمامك.',
    'apple': 'تفاحة أمامك.',
    'sandwich': 'ساندويتش أمامك.',
    'orange': 'برتقالة أمامك.',
    'broccoli': 'بروكلي أمامك.',
    'carrot': 'جزر أمامك.',
    'hot dog': 'هوت دوغ أمامك.',
    'pizza': 'بيتزا أمامك.',
    'donut': 'دونات أمامك.',
    'cake': 'كعكة أمامك.',
    'chair': 'كرسي أمامك.',
    'couch': 'أريكة أمامك.',
    'potted plant': 'نبتة في أصيص أمامك.',
    'bed': 'سرير أمامك.',
    'dining table': 'طاولة أمامك.',
    'toilet': 'مرحاض أمامك.',
    'tv': 'تلفاز أمامك.',
    'laptop': 'حاسوب محمول أمامك.',
    'mouse': 'فأرة أمامك.',
    'remote': 'جهاز تحكم أمامك.',
    'keyboard': 'لوحة مفاتيح أمامك.',
    'cell phone': 'هاتف محمول أمامك.',
    'microwave': 'ميكروويف أمامك.',
    'oven': 'فرن أمامك.',
    'toaster': 'محمصة أمامك.',
    'sink': 'حوض أمامك.',
    'refrigerator': 'ثلاجة أمامك.',
    'book': 'كتاب أمامك.',
    'clock': 'ساعة أمامك.',
    'vase': 'مزهرية أمامك.',
    'scissors': 'مقص أمامك.',
    'teddy bear': 'دب دمية أمامك.',
    'hair drier': 'مجفف شعر أمامك.',
    'toothbrush': 'فرشاة أسنان أمامك.',
  };

  static const Map<RiskLevel, String> riskPrefixFr = {
    RiskLevel.critical: 'Attention, très proche : ',
    RiskLevel.warning: 'Attention : ',
    RiskLevel.safe: '',
  };

  static const Map<RiskLevel, String> riskPrefixAr = {
    RiskLevel.critical: 'انتباه، قريب جداً: ',
    RiskLevel.warning: 'انتباه: ',
    RiskLevel.safe: '',
  };

  static String getAlertMessageFr(String label, RiskLevel level) {
    final msg = alertMessagesFr[label] ?? 'Obstacle devant.';
    final prefix = riskPrefixFr[level] ?? '';
    return prefix + msg;
  }

  static String getAlertMessageAr(String label, RiskLevel level) {
    final msg = alertMessagesAr[label] ?? 'عائق أمامك.';
    final prefix = riskPrefixAr[level] ?? '';
    return prefix + msg;
  }

  static double getObjectHeightMeters(String label) {
    return objectHeightsMeters[label] ?? 1.0;
  }
}

enum RiskLevel {
  critical,
  warning,
  safe,
}
