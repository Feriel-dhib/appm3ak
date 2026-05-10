# Ma3ak — Documentation technique et fonctionnelle

**Ma3ak** (معاك) est une application mobile Flutter destinée aux **personnes en situation de handicap en Tunisie** et à leurs **accompagnants**. Elle vise à faciliter la mobilité, l’autonomie et l’inclusion sociale.
pw
Ce README est conçu pour être partagé avec l’équipe : il décrit le projet, l’architecture, la configuration et comment démarrer ou contribuer.

---

## Pour les collègues — Démarrage rapide

> **Objectif :** Pouvoir cloner le projet, lancer l’app et comprendre où se trouvent les parties principales du code.

### En bref

1. **Cloner le dépôt** (ou récupérer le dossier du projet).
2. **Prérequis :** Flutter installé (SDK ^3.10), backend API Ma3ak disponible (voir [Configuration](#4-configuration-et-environnement)).
3. **Lancer l’app :**
   ```bash
   flutter pub get
   flutter run
   ```
   Si l’API est sur votre machine et que vous utilisez l’émulateur Android :
   ```bash
   flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000
   ```
4. **Où est le code ?**
   - **Écrans** : `lib/features/` (auth, home, profile, transport, accompagnement, SOS, véhicules, réservations, détection d’obstacles, navigation AR, etc.).
   - **API / données** : `lib/data/` (client HTTP, modèles, repositories).
   - **État global** : `lib/providers/` (auth, thème, router).
   - **Configuration** : `lib/core/config/` (URL API), `lib/core/theme/` (thème clair/sombre).

### Points importants pour la collaboration

- **Authentification :** JWT stocké de façon sécurisée ; après login/register, redirection vers `/home`. L’état « connecté » est géré par `authStateProvider` (Riverpod).
- **Rôles :** Bénéficiaire vs Accompagnant — le contenu de l’accueil change selon le rôle (`HomeTab` vs `HomeCompanionTab`).
- **Thème :** Mode clair/sombre/système, persistant (bouton sur les écrans Login et Inscription, et dans le Profil).
- **Langues :** Français, anglais et arabe (fichiers `.arb` + `AppStrings` dans `lib/core/l10n/`).

---

## Sommaire

1. [Vue d’ensemble fonctionnelle](#1-vue-densemble-fonctionnelle)
2. [Stack technique](#2-stack-technique)
3. [Architecture et structure du projet](#3-architecture-et-structure-du-projet)
4. [Configuration et environnement](#4-configuration-et-environnement)
5. [Authentification et sécurité](#5-authentification-et-sécurité)
6. [API et couche données](#6-api-et-couche-données)
7. [État global et navigation](#7-état-global-et-navigation)
8. [Fonctionnalités par écran](#8-fonctionnalités-par-écran)
9. [Thème et accessibilité](#9-thème-et-accessibilité)
10. [Localisation](#10-localisation)
11. [Installation et exécution](#11-installation-et-exécution)
12. [Tests et qualité](#12-tests-et-qualité)
13. [Comment contribuer](#13-comment-contribuer)

---

## 1. Vue d’ensemble fonctionnelle

> Décrit les rôles utilisateurs et les parcours dans l’app. Utile pour savoir quel écran correspond à quel usage.

### Rôles utilisateurs

| Rôle | Constante | Description |
|------|-----------|-------------|
| **Bénéficiaire** | `UserRole.beneficiary` | Personne en situation de handicap ; utilise les services (trajets, lieux, SOS, transport adapté, etc.). |
| **Accompagnant** | `UserRole.companion` | Accompagne un ou plusieurs bénéficiaires ; voit demandes d’assistance, planning, utilisateurs suivis. |
| **Admin** | `UserRole.admin` | Administrateur (hors scope mobile initial). |

### Parcours typiques

- **Bénéficiaire** : Splash → Login/Register → Home (services, SOS, assistant actuel, carte) → Transport / Milieux / Profil. Accès à « Mes accompagnants ».
- **Accompagnant** : Même entrée ; Home dédié (utilisateurs suivis, demandes d’assistance, mon planning, ressources). Accès à « Mes bénéficiaires ».

---

## 2. Stack technique

> Liste des technologies utilisées. Permet de savoir quelles librairies sont déjà en place (Riverpod, GoRouter, Dio, etc.).

| Domaine | Technologie |
|---------|-------------|
| **Framework** | Flutter (SDK ^3.10) |
| **Langage** | Dart |
| **State management** | Riverpod (`flutter_riverpod`) |
| **Navigation** | GoRouter (`go_router`) |
| **HTTP** | Dio |
| **Stockage sécurisé** | `flutter_secure_storage` (JWT) |
| **Préférences** | `shared_preferences` (thème, etc.) |
| **Connexion Google** | `google_sign_in` |
| **Images** | `image_picker` (photo de profil) |
| **Modèles** | `equatable` |
| **i18n** | Fichiers `.arb` (fr/en/ar) + `AppStrings` manuel |

Backend attendu : API REST (Node.js/Express ou équivalent) avec JWT, hébergée sur une URL configurable.

---

## 3. Architecture et structure du projet

> Où se trouve chaque responsabilité. Les commentaires dans l’arborescence indiquent le rôle des dossiers/fichiers principaux.

### Arborescence `lib/`

```
lib/
├── main.dart                 # Point d'entrée : WidgetsBinding, ProviderScope, runApp(Ma3akApp)
├── app.dart                  # MaterialApp.router, thème light/dark, themeMode, GoRouter
├── core/                     # Code partagé (config, thème, services, widgets réutilisables)
│   ├── config/               # URL API : lecture dart-define ou valeur par défaut selon plateforme
│   │   ├── app_config.dart       # API_BASE_URL, apiBaseUrl, uploadsBaseUrl
│   │   ├── app_config_io.dart    # Android → 10.0.2.2:3000, iOS/autre → localhost
│   │   └── app_config_stub.dart # Web → localhost
│   ├── theme/
│   │   └── app_theme.dart    # Thème Material 3 : light (bleu #1976D2) et dark (accent #5DDDF9)
│   ├── l10n/
│   │   └── app_strings.dart # Chaînes FR/AR manuelles (createAccount, loginButton, etc.)
│   ├── services/
│   │   └── token_storage_service.dart  # Lecture/écriture JWT via FlutterSecureStorage
│   ├── utils/
│   │   └── storage_keys.dart # Clés de stockage (JWT, userId, etc.)
│   └── widgets/
│       ├── app_logo.dart     # Logo asset ou icône accessibilité en fallback
│       ├── accessible_button.dart
│       └── loading_overlay.dart
├── data/                     # Couche données : API, modèles, repositories
│   ├── api/
│   │   ├── api_client.dart   # Instance Dio, baseUrl, timeouts, intercepteurs
│   │   ├── auth_interceptor.dart  # Ajout Bearer JWT (sauf login/register)
│   │   └── endpoints.dart    # Constantes des routes API (/auth/login, /user/me, etc.)
│   ├── models/
│   │   ├── user_model.dart   # UserModel, UserRole, HandicapType, PreferredLanguage
│   │   └── auth_response.dart # accessToken, user
│   └── repositories/
│       ├── auth_repository.dart, user_repository.dart, transport_repository.dart, …
│       # Voir `lib/data/repositories/` pour la liste complète (véhicules, réservations, SOS, etc.)
├── providers/                # État global (Riverpod)
│   ├── api_providers.dart    # tokenStorage, apiClient (injection)
│   ├── auth_providers.dart   # authRepository, userRepository, authStateProvider
│   └── theme_provider.dart   # themeModeProvider (light/dark/system, persistant SharedPreferences)
├── router/
│   └── app_router.dart       # GoRouter : /, /login, /register, /home, /profile, /profile-edit, etc.
├── features/                 # Écrans et logique par fonctionnalité
│   ├── auth/
│   │   └── screens/          # SplashScreen, LoginScreen, RegisterScreen (inscription multi-étapes)
│   ├── home/
│   │   └── screens/          # MainShell (bottom nav), HomeTab, HomeCompanionTab
│   ├── profile/
│   │   └── screens/          # ProfileTab, ProfileScreen (édition + photo)
│   ├── transport/, vehicles/, reservations/, sos/, accompaniment/ (contacts urgence, relations),
│   ├── detection/, navigation_ar/, map/, …        # détail : `lib/features/`
└── l10n/
    ├── app_fr.arb, app_en.arb, app_ar.arb   # Chaînes générées (Flutter l10n)
    └── app_localizations*.dart  # Générés par Flutter
```

### Logique des couches

- **UI** : écrans dans `features/*/screens/`, widgets partagés dans `core/widgets/`.
- **État** : Riverpod dans `providers/` ; `authStateProvider` pilote la redirection (Splash, MainShell).
- **Données** : `AuthRepository` + `UserRepository` ; pas de couche « use case » explicite.
- **API** : `ApiClient` (Dio) + `AuthInterceptor` ; endpoints centralisés dans `Endpoints`.

---

## 4. Configuration et environnement

> Comment pointer l’app vers la bonne API (locale ou distante). Important pour les collègues qui lancent l’app en local.

### URL de l’API

- **Variable** : `API_BASE_URL` (compile-time via `--dart-define` ou valeur par défaut).
- **Défaut** :
  - **Android (émulateur)** : `http://10.0.2.2:3000` (10.0.2.2 = machine hôte depuis l’émulateur).
  - **iOS / Desktop / Web** : `http://localhost:3000` (stub pour le web).

Exemples :

```bash
# API de production ou staging
flutter run --dart-define=API_BASE_URL=https://api.ma3ak.tn

# Émulateur Android : API tournant sur le PC
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

Fichiers concernés : `lib/core/config/app_config.dart`, `app_config_io.dart`, `app_config_stub.dart`.

### Photo de profil (`photoProfil`)

- **Après login** ou `GET /user/me` : le champ `photoProfil` est soit une **URL absolue** (`http://` / `https://`, ex. avatar Google), soit un **chemin relatif** servi par l’API : `uploads/<fichier>`.
- **Affichage** : URL absolue utilisée telle quelle ; si la valeur commence par `uploads/`, l’app construit l’URL `API_BASE_URL` + `/` + ce chemin (ex. `https://api.example.com/uploads/profile-….jpg`). Voir `UserRepository.photoUrl` et `lib/core/utils/profile_photo_rules.dart`.
- **Upload** : `PATCH /user/me/photo` avec `multipart/form-data`, nom de champ **`image`**. **Suppression** : `DELETE /user/me/photo` (préféré pour retirer la photo plutôt que d’envoyer `null` en JSON).

### Logo

- Image attendue : `assets/images/logo.png`.
- Si absent : affichage d’un pictogramme accessibilité (voir `lib/core/widgets/app_logo.dart`).
- Dans `pubspec.yaml` : section `flutter.assets` avec `assets/images/`.

---

## 5. Authentification et sécurité

> Flux login/logout et où est stocké le token. Utile pour déboguer les problèmes de connexion ou modifier le flux d’auth.

### Flux

1. **Splash** : lecture de `authStateProvider` (token + `GET /user/me`). Si token valide et user OK → `/home`, sinon → `/login`.
2. **Login** : email + mot de passe → `POST /auth/login` ; réponse `access_token` + `user` → token enregistré via `TokenStorageService`, état mis à jour, puis `context.go('/home')`.
3. **Google** : `google_sign_in` → `idToken` → `POST /auth/google` → même traitement que login.
4. **Logout** : suppression du token (secure storage), `authStateProvider` à `null` ; l’UI redirige vers login si nécessaire.

### Stockage du token

- **Service** : `TokenStorageService` (package `flutter_secure_storage`).
- **Clé** : `StorageKeys.accessToken` (`'access_token'`).
- **Android** : `AndroidOptions(encryptedSharedPreferences: true)`.

### Intercepteur HTTP

- **AuthInterceptor** : pour chaque requête, si le chemin **n’est pas** dans la liste « sans auth », ajout de `Authorization: Bearer <token>`.
- **Chemins sans token** : `/auth/login`, `/auth/google`, `/auth/register`, `/user/register`.
- En cas de **401**, l’erreur est propagée ; l’app (et éventuellement un listener global) peut déconnecter et rediriger vers login.

---

## 6. API et couche données

> Liste des endpoints et des modèles. Référence pour ajouter une nouvelle route ou un nouveau champ.

### Client HTTP

- **ApiClient** : instance Dio avec `baseUrl: AppConfig.apiBaseUrl`, timeouts 30 s, headers `Content-Type` / `Accept` JSON.
- Intercepteurs : `AuthInterceptor`, `LogInterceptor` (request/response/error en debug).

### Endpoints utilisés

| Méthode | Chemin | Usage |
|--------|--------|--------|
| POST | `/auth/login` | Connexion email/password |
| POST | `/auth/google` | Connexion Google (id_token) |
| GET | `/auth/config-test` | Vérif config JWT/Google (optionnel) |
| POST | `/user/register` | Inscription |
| GET | `/user/me` | Profil courant |
| PATCH | `/user/me` | Mise à jour profil (JSON ; champ optionnel `photoProfil` pour URL ou `uploads/...`) |
| DELETE | `/user/me` | Suppression compte |
| PATCH | `/user/me/photo` | Upload photo de profil (multipart, champ fichier `image`, max 5 Mo, jpeg/png/gif/webp) |
| DELETE | `/user/me/photo` | Supprime la photo (fichier sous `uploads/` si applicable) ; `photoProfil` → `null` |
| GET | `/user/me/accompagnants` | Liste accompagnants (bénéficiaire) |
| PATCH | `/user/me/accompagnants` | Ajout/retrait accompagnant |
| GET | `/user/me/beneficiaires` | Liste bénéficiaires (accompagnant) |

### Modèles principaux

- **UserModel** : `id`, `nom`, `email`, `role`, `contact`, `image`, `ville`, `preferredLanguage`, `handicapTypes`, `bio`, `accompagnantsIds`, `createdAt`, `updatedAt`. Méthodes `fromJson` / `toJson`, `copyWith`, getters `isBeneficiary` / `isCompanion`.
- **UserRole** : `beneficiary`, `companion`, `admin` (sérialisation API en majuscules).
- **HandicapType** : `mobilityWheelchair`, `mobilityCrutches`, `visual`, `hearing`, `cognitive`, `other` (API : snake_case).
- **PreferredLanguage** : `ar`, `fr`.
- **AuthResponse** : `accessToken`, `user` (UserModel).

### Inscription (payload)

Champs envoyés à `POST /user/register` : `nom`, `email`, `password`, `contact`, et optionnellement `role`, `ville`, `preferredLanguage`, `handicapTypes` (liste), `bio`.

---

## 7. État global et navigation

> Où est géré l’état (connecté, thème) et quelles routes existent. Utile pour ajouter un écran ou un provider.

### Providers Riverpod

| Provider | Type | Rôle |
|----------|------|------|
| `tokenStorageProvider` | `TokenStorageService` | Lecture/écriture du JWT |
| `apiClientProvider` | `ApiClient` | Client Dio avec callback `getAccessToken` |
| `authRepositoryProvider` | `AuthRepository` | Login, logout, stockage token |
| `userRepositoryProvider` | `UserRepository` | Register, getMe, updateMe, photo (`PATCH`/`DELETE` `/user/me/photo`), etc. |
| `authStateProvider` | `StateNotifierProvider<..., AsyncValue<UserModel?>>` | État connecté (user ou null) ; initialise avec token + getMe |
| `themeModeProvider` | `StateNotifierProvider<..., ThemeMode>` | Clair / Sombre / Système, persistant (SharedPreferences) |
| `appRouterProvider` | `GoRouter` | Configuration des routes |

### Routes GoRouter

| Chemin | Écran | Remarque |
|--------|--------|----------|
| `/` | `SplashScreen` | Redirection selon auth |
| `/login` | `LoginScreen` | Bouton bascule thème en haut à droite |
| `/register` | `RegisterScreen` | Inscription multi-étapes ; bouton thème dans l’AppBar |
| `/home` | `MainShell(initialIndex: 0)` | Query `tab` optionnel |
| `/profile` | `MainShell(initialIndex: 3)` | Onglet Profil |
| `/profile-edit` | `ProfileScreen` | Édition profil (nom, contact, photo, etc.) |
| `/accompagnants` | `EmergencyContactsScreen` | Contacts d’urgence (ordre de priorité) |
| `/beneficiaires` | `TransportRequestsScreen` | Accompagnant : demandes liées aux bénéficiaires |

### MainShell (après connexion)

- **Barre de navigation (utilisateur standard)** : **4 onglets** — Accueil **(0)**, Transport **(1)**, Milieux **(2)**, Profil **(3)**.  
  *(Le module Santé — onglet dédié, dossier médical, rappels médicaments, alertes risque, paramètres d’urgence API — a été retiré de l’application.)*
- **Chauffeur solidaire** : 3 onglets — Accueil, Transport, Profil (voir `main_shell.dart` pour le mapping des indices).
- **Contenu Accueil** : selon `user.isBeneficiary` → `HomeTab` (bénéficiaire) ou `HomeCompanionTab` (accompagnant).
- Si `authStateProvider` donne `null` (ex. après logout), redirection vers `/welcome` ou `/login` selon l’écran.

---

## 8. Fonctionnalités par écran

> Résumé de ce que fait chaque écran et où se trouve la logique. Aide à retrouver rapidement le code d’une fonctionnalité.

### Splash

- Affiche logo + titre + indicateur de chargement.
- Après un court délai, lit `authStateProvider` : `data(user)` → `/home` si user non null, sinon `/welcome` ; `loading` / `error` → `/welcome`.

### Login

- Champs : email (ou téléphone), mot de passe.
- Bouton « Connexion » → `AuthStateNotifier.login` ; en cas de succès → `/home`.
- **Bouton mode clair/sombre** en haut à droite (icône lune/soleil).
- Lien « Mot de passe oublié » (UI prévue, logique à brancher).
- « Se connecter avec Google » → `loginWithGoogle(idToken)` (à connecter avec `google_sign_in`).
- Lien vers inscription → `/register`.

### Register

- Formulaire **multi-étapes** (4 étapes) : rôle (Handicap / Accompagnant), nom, types de handicap, email/téléphone ; mot de passe, ville, langue ; bio.
- Design thème sombre dédié (couleurs fixes pour l’écran d’inscription).
- **Bouton mode clair/sombre** dans l’AppBar.
- Envoi via `UserRepository.register` ; après succès → redirection vers `/login`.
- Chaînes et champs alignés avec l’API (voir `UserRepository.register` et modèles).

### Home (bénéficiaire – HomeTab)

- En-tête : logo/titre, recherche (placeholder).
- Sections type : Services principaux (cartes), À proximité, Carte « Autour de vous ».
- FAB ou bouton SOS (selon maquette) pour alerte.
- Couleurs et cartes basées sur le thème (dark/light).

### Home (accompagnant – HomeCompanionTab)

- Utilisateurs suivis (liste horizontale), « Voir tout ».
- Demandes d’assistance (cartes avec Accepter / Ignorer).
- Mon planning (cartes date + libellé).
- Ressources & Guide (cartes liens).
- Même cohérence thème (surfaces, textes).

### Profil (ProfileTab)

- Photo, nom, badge « Utilisateur vérifié », date d’adhésion.
- Cartes statistiques (ex. trajets assistés, note).
- Blocs : Informations personnelles (e-mail, téléphone), Sécurité et support (Thème, Contacts d’urgence, Historique, Paramètres).
- **Choix de thème** : dialogue Clair / Sombre / Système → `themeModeProvider.setThemeMode`.
- Bouton Déconnexion → `logout` puis redirection.
- Lien vers écran d’édition → `/profile-edit`.

### ProfileScreen (édition)

- Formulaire : nom, contact, ville, langue, types de handicap, bio.
- Changement de photo → `UserRepository.updateProfileImage` (multipart).
- Sauvegarde → `updateMe` puis `authStateProvider.refreshUser()`.

### Mes accompagnants / Mes bénéficiaires

- Listes issues de `getAccompagnants()` / `getBeneficiaires()`.
- Ajout/retrait accompagnant via `updateAccompagnant` (action + accompagnantId).

---

## 9. Thème et accessibilité

> Comment le thème est appliqué et où sont définies les couleurs. Utile pour modifier le design ou l’accessibilité.

### Thème

- **Fichier** : `lib/core/theme/app_theme.dart`.
- **Light** : primary bleu (#1976D2), surface claire, contraste lisible.
- **Dark** : fond #000000, surface #1E1E1E, surfaceContainerHighest #2C2C2C, primary accent #5DDDF9, textes blancs/gris.
- **Application** : `MaterialApp.router` dans `app.dart` avec `theme: AppTheme.light`, `darkTheme: AppTheme.dark`, `themeMode: ref.watch(themeModeProvider)` (persistant via `theme_provider.dart`).

Les écrans Home et Profil utilisent `theme.colorScheme` (surface, onSurface, etc.) pour respecter le dark mode. L’écran d’inscription utilise un design sombre fixe (couleurs dédiées dans `register_screen.dart`).

### Accessibilité

- Contraste : ratios WCAG 4.5:1 visés.
- **Semantics** : labels sur les éléments clés (logo, boutons, champs) pour TalkBack / VoiceOver.
- Cibles tactiles : minimum 44×44 points (widgets dédiés si besoin).
- Support du redimensionnement des polices système.
- RTL : pris en charge pour l’arabe selon `preferredLanguage` et locale.

---

## 10. Localisation

> Où sont les textes FR/AR et comment ajouter une nouvelle chaîne.

- **Fichiers** : `lib/l10n/app_fr.arb`, `app_en.arb`, `app_ar.arb` ; config `l10n.yaml` (template `app_fr.arb`, output `app_localizations.dart`). Régénérer avec `flutter gen-l10n` après modification des `.arb`.
- **Classe manuelle** : `lib/core/l10n/app_strings.dart` — `AppStrings.fr()`, `AppStrings.ar()`, `AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)` pour les écrans qui s’appuient sur la langue utilisateur.
- Utilisation : mélange de `AppLocalizations.of(context)` (généré) et `AppStrings` selon les écrans.

---

## 11. Installation et exécution

### Prérequis

- Flutter (SDK ^3.10, dernière stable recommandée).
- Backend API Ma3ak démarré (ex. `http://localhost:3000` ou URL définie).
- Pour Google Sign-In : projet Google Cloud, identifiants OAuth 2.0 (Android/iOS), configuration backend.

### Commandes

```bash
# Dépendances
flutter pub get

# Lancer (défaut : localhost ou 10.0.2.2 sur Android)
flutter run

# Avec URL API personnalisée
flutter run --dart-define=API_BASE_URL=https://ton-api.example.com

# Émulateur Android vers API sur la machine hôte
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

### Build

```bash
flutter build apk
flutter build ios
flutter build web
```

---

## 12. Tests et qualité

- **Tests** : `flutter test` (ex. `test/user_model_test.dart`, `widget_test.dart`).
- **Lints** : `flutter_lints` dans `pubspec.yaml` ; `analysis_options.yaml` pour les règles d’analyse.

---

## 13. Comment contribuer

> Recommandations pour que les collègues puissent contribuer de façon cohérente.

1. **Avant de coder**
   - Vérifier que l’API backend est accessible (URL dans [Configuration](#4-configuration-et-environnement)).
   - Lire la section [Architecture](#3-architecture-et-structure-du-projet) pour placer le code au bon endroit.

2. **Conventions**
   - **Nouvel écran** : dans `lib/features/<nom_feature>/screens/`.
   - **Nouvelle route** : ajouter dans `lib/router/app_router.dart` et documenter dans ce README (section 7).
   - **Nouvelle chaîne UI** : ajouter dans `lib/core/l10n/app_strings.dart` (FR/EN/AR) et/ou dans les `.arb`, puis `flutter gen-l10n` si besoin.
   - **Nouvel endpoint** : constante dans `lib/data/api/endpoints.dart`, appel dans le repository concerné.

3. **État (Riverpod)**
   - État global (auth, thème) : dans `lib/providers/`.
   - État local à un écran : `StatefulWidget` ou `ConsumerStatefulWidget` avec `setState` / ref.

4. **Après modification**
   - Lancer `flutter analyze` (ou l’analyse IDE).
   - Tester sur un émulateur ou un appareil (auth, changement de thème, navigation).

5. **Partage**
   - Mettre à jour ce README si vous ajoutez une route, un provider ou une config importante.
   - Documenter les décisions importantes (ex. pourquoi un écran a un thème fixe) en commentaire dans le code ou dans le README.

---

## Résumé — Où trouver quoi

| Besoin | Fichier / dossier |
|--------|-------------------|
| Changer l’URL de l’API | `lib/core/config/`, `--dart-define=API_BASE_URL=...` |
| Modifier les couleurs (light/dark) | `lib/core/theme/app_theme.dart` |
| Ajouter une route | `lib/router/app_router.dart` |
| Modifier le flux login/logout | `lib/providers/auth_providers.dart`, `lib/features/auth/screens/login_screen.dart` |
| Modifier l’inscription | `lib/features/auth/screens/register_screen.dart`, `lib/data/repositories/user_repository.dart` |
| Modifier l’accueil (bénéficiaire) | `lib/features/home/screens/home_tab.dart` |
| Modifier l’accueil (accompagnant) | `lib/features/home/screens/home_companion_tab.dart` |
| Modifier le profil | `lib/features/profile/screens/profile_tab.dart`, `profile_screen.dart` |
| Ajouter un texte (FR/EN/AR) | `lib/core/l10n/app_strings.dart` et/ou `lib/l10n/app_*.arb` |
| Modifier les endpoints API | `lib/data/api/endpoints.dart`, `lib/data/repositories/` |

---

**Projet Ma3ak — Documentation à jour pour partage avec l’équipe.**  
*Dernière mise à jour notable : retrait du module Santé côté app (pas d’onglet ni d’écrans dossier médical / rappels / alertes risque ; SOS et contacts d’urgence restent disponibles.)*
# appm3ak
