# Causes de retard et optimisations (appm3ak)

Ce document résume les **causes identifiées** des temps d’attente dans l’application et les **correctifs** appliqués ou recommandés.

---

## 1. Écran de splash (démarrage)

### Cause
- Délai **fixe de 800 ms** avant de lire l’état d’auth et de rediriger vers `/home` ou `/login`.
- Délai de **sécurité de 3 s** après la redirection (au cas où la navigation échoue).

### Correctif appliqué
- Délai initial réduit à **400 ms** pour limiter l’attente perçue.
- Délai de secours réduit à **2 s** (suffisant si la navigation a déjà eu lieu).

**Fichier :** `lib/features/auth/screens/splash_screen.dart`

---

## 2. Vérification d’auth au démarrage

### Comportement
- `AuthStateNotifier` appelle `getMe()` avec un **timeout de 8 secondes** (`auth_providers.dart`).
- Le splash **n’attend pas** la fin de cette requête : après 400 ms il lit l’état (souvent encore `loading`) et redirige.
- L’utilisateur ne reste donc pas bloqué sur le splash à cause de l’API, mais en cas de **login** ou d’**appels API** ensuite, un réseau lent peut faire attendre jusqu’à **10 s (connexion)** et **15 s (réception)** (Dio dans `api_client.dart`).

### L’internet peut-il causer le retard ?
**Oui.** Dès qu’une action appelle l’API (login, profil, transport, véhicules, etc.), une connexion lente ou instable fait attendre jusqu’à :
- **10 s** pour établir la connexion (timeout Dio),
- **15 s** pour recevoir la réponse.

Écrans / actions concernés : **Login**, **Inscription**, **Profil** (chargement / sauvegarde), **Centre Transport**, **Demandes de transport**, **Véhicules**, **Réservations**, **Suivi de course**, **Notifications**, etc. En Wi‑Fi faible ou 4G capricieuse, l’app peut donc sembler lente ou « bloquée » pendant ces appels.

### Recommandation
- Garder les timeouts Dio actuels (10 s / 15 s) pour éviter des échecs trop rapides.
- Sur l’écran de login, afficher un indicateur de chargement et éventuellement un message du type « Vérification du compte… » si la requête dépasse 2–3 s.

---

## 3. Écran « Détection d’obstacles »

### Causes
1. **Init séquentielle**  
   La caméra était initialisée, puis le modèle TFLite (asset + isolate + chargement Interpreter). Tout s’enchaînait, ce qui allongeait le temps avant d’afficher la préview.

2. **Conversion YUV → RGB sur le thread principal**  
   À chaque image (throttlée à ~50 ms), les boucles de conversion YUV→RGB et de redimensionnement en 320×320 s’exécutaient sur le **main isolate**. Cela pouvait prendre plusieurs dizaines de millisecondes par frame et provoquer **saccades / sensation de retard**.

### Correctifs appliqués
- **Init en parallèle**  
  `_cameraService.initialize()` et `_detectionService.initialize()` sont lancés ensemble avec `Future.wait([...])`. Le temps perçu avant d’être prêt est réduit (souvent proche du maximum des deux, au lieu de la somme).

- **Conversion YUV → RGB dans un isolate**  
  La conversion est déléguée à une fonction top-level exécutée via `compute()` (`yuv_converter.dart`). Elle ne bloque plus l’UI ; l’inférence TFLite reste dans l’isolate dédié.

**Fichiers :**
- `lib/features/detection/screens/obstacle_detection_screen.dart` (init parallèle)
- `lib/features/detection/services/yolo_tflite_service.dart` (utilisation de `compute` + `yuv_converter.dart`)
- `lib/features/detection/services/yuv_converter.dart` (nouveau)

---

## 4. Autres délais (référence)

| Endroit | Délai | Rôle |
|--------|--------|------|
| `transport_dynamic_screen` | Debounce 450 ms | Recherche |
| `alert_engine` | Cooldown global 2,5 s, zone 1,5 s | Éviter spam TTS |
| `yolo_tflite_service` | Throttle 50 ms, timeout inférence 5 s | Cadence et sécurité |
| `transport_suivi_screen` | Poll 15 s | Rafraîchissement suivi |
| `transport_detail_screen` | Poll ETA 30 s | Mise à jour ETA |
| `auth_providers` | Timeout getMe 8 s | Éviter blocage infini |

Ces valeurs sont volontaires (UX ou robustesse) et n’ont pas été modifiées dans le cadre des correctifs de retard.

---

## Résumé

- **Splash :** délai réduit (400 ms + secours 2 s).
- **Détection d’obstacles :** init caméra + modèle en parallèle, conversion YUV→RGB hors thread principal.
- **Auth / API :** pas de changement ; en cas de lenteur réseau, l’amélioration passera par indicateurs de chargement et messages clairs plutôt que par une réduction des timeouts.

En testant à nouveau l’app (splash puis écran détection), les attentes devraient être plus courtes et l’écran de détection plus fluide.

---

## 5. Build : erreur tflite_flutter `UnmodifiableUint8ListView`

### Cause
Avec les SDK Dart 3.x récents, `UnmodifiableUint8ListView` (dart:typed_data) n’est plus disponible, ce qui provoque une erreur de compilation dans `tflite_flutter` 0.10.4 (`tensor.dart`).

### Correctif appliqué
Le getter `data` dans le fichier `tensor.dart` du package en cache a été modifié pour utiliser `Uint8List.view(...)` à la place de `UnmodifiableUint8ListView`.

**Emplacement du fichier patché :**  
`~/.pub-cache/hosted/pub.dev/tflite_flutter-0.10.4/lib/src/tensor.dart`

**Remarque :** Un `flutter clean` suivi de `flutter pub get` peut réinstaller le package et annuler ce correctif. Dans ce cas, réappliquer le remplacement ci‑dessus dans `tensor.dart`, ou passer à `tflite_flutter: ^0.12.1` dans `pubspec.yaml` (version qui peut inclure le correctif selon l’environnement).
