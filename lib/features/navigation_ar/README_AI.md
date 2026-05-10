# Module IA – Navigation AR M3ak

## Contenu (partie IA uniquement)

- **Détection d’obstacles en temps réel**  
  - Service : `ObjectDetectionService` (Google ML Kit sur l’appareil).  
  - Détection : personnes, voitures, deux-roues, autres obstacles.  
  - Sortie : liste d’objets `DetectedObstacle` (label, confiance, bounding box).

- **Instructions vocales bilingues (FR / AR)**  
  - Service : `VoiceGuidanceService` (flutter_tts).  
  - Annonces d’obstacles et de directions (gauche, droite, tout droit, arrivée).  
  - Bascule langue via le bouton FR/AR sur l’écran.

- **Orchestration**  
  - `NavigationAIService` : envoie les images caméra au détecteur, met à jour les obstacles, déclenche la voix pour l’obstacle le plus proche du centre (évite le spam).

- **Écran**  
  - `ArNavigationScreen` : flux caméra, overlay des boîtes de détection, flèche de direction, bouton langue.

## Dépendances ajoutées

- `camera` – flux caméra
- `google_mlkit_object_detection` – détection d’objets (ML Kit)
- `flutter_tts` – synthèse vocale

`google_mlkit_commons` est une dépendance transitive de `google_mlkit_object_detection`.

## Permissions

- **Android** : `CAMERA` dans `AndroidManifest.xml`.
- **iOS** : `NSCameraUsageDescription` dans `Info.plist`.

## Comment lancer

1. À la racine du projet : `flutter pub get`.
2. Lancer sur un appareil réel (caméra) :  
   `flutter run` (ou device iOS/Android).
3. Depuis l’accueil, appuyer sur la carte **Accessibilité** pour ouvrir la **Navigation AR**.

## Améliorations possibles (hors scope actuel)

- Modèle TFLite personnalisé pour arbres / poteaux.
- Direction AR basée sur la boussole / GPS pour la flèche.
- Intégration avec l’itinéraire du backend (NestJS) pour les instructions « tournez à gauche », etc.
