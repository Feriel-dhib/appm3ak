# Prompt Backend — Historique des déplacements & Évaluation après trajet

**Contexte :** Application Ma3ak — Module Transport Adapté Intelligent. Le moyen de transport est le **véhicule** ; chaque trajet est une **réservation de véhicule** (vehicle-reservation) avec un véhicule et un chauffeur (propriétaire du véhicule) identifiés.

---

## 1. Historique des déplacements

**Besoin :** L’utilisateur (bénéficiaire) doit pouvoir consulter l’**historique de ses déplacements** : trajets déjà effectués avec **véhicule et chauffeur** identifiés.

**Source des données côté app :** L’app affiche les **réservations de véhicules** dont le statut est **TERMINEE** (tri par date/heure décroissant). Pour chaque entrée on affiche :
- Date et heure du trajet
- Lieu de départ, lieu de destination
- **Véhicule** (marque, modèle)
- **Chauffeur** (nom du propriétaire du véhicule)

**Côté backend :**

- **Aucune modification obligatoire** si vous exposez déjà :
  - **GET /vehicle-reservations/me** : liste des réservations de l’utilisateur connecté.
  - Chaque réservation doit pouvoir être **peuplée** avec :
    - `vehicleId` → objet **Vehicle** (avec au minimum : `_id`, `marque`, `modele`, `ownerId` ou `ownerId` peuplé en **User** pour afficher le nom du chauffeur).
  - Les réservations ont un champ **statut** avec la valeur `TERMINEE` pour les trajets terminés.

- **Optionnel / amélioration :**
  - Endpoint dédié **GET /vehicle-reservations/me/history** (ou paramètre `?statut=TERMINEE`) qui retourne uniquement les réservations terminées, triées par date décroissante, avec `vehicle` (et si possible `vehicle.ownerId` peuplé en User) pour limiter la taille de la réponse.
  - Champ **dureeTrajet** (nombre de minutes) ou **dateHeureFin** sur la réservation une fois le trajet terminé, pour afficher la durée dans l’historique (l’app pourra l’afficher si vous l’ajoutez).

**Résumé :** S’assurer que **GET /vehicle-reservations/me** retourne bien les réservations avec `vehicle` (et de préférence `vehicle.ownerId` peuplé en User) pour que l’app puisse afficher véhicule + chauffeur dans l’historique.

---

## 2. Évaluation après trajet (véhicule + chauffeur)

**Besoin :** Après un trajet (réservation en statut **TERMINEE**), l’utilisateur peut **évaluer le trajet** : note (1 à 5) + commentaire optionnel. L’évaluation porte sur le **trajet / véhicule / chauffeur** (pas un “transport” abstrait).

**Côté backend :** Il faut exposer **deux endpoints** liés à la réservation de véhicule.

### 2.1 Envoyer une évaluation (après trajet)

- **Méthode :** `POST`
- **URL :** `/vehicle-reservations/:id/review`
- **Authentification :** JWT (utilisateur connecté = auteur de l’évaluation).
- **Règles métier :**
  - La réservation `id` doit appartenir à l’utilisateur connecté (il est le bénéficiaire du trajet).
  - La réservation doit être en statut **TERMINEE**.
  - Une seule évaluation par réservation (idempotent : si une review existe déjà pour cette réservation, vous pouvez retourner 409 ou mettre à jour et retourner 200, au choix).
- **Body (JSON) :**
  ```json
  {
    "note": 5,
    "comment": "Très bon trajet, chauffeur à l'écoute.",
    "vehicleId": "id_du_vehicule_optionnel",
    "driverId": "id_du_chauffeur_optionnel"
  }
  ```
  - **note** (obligatoire) : entier entre 1 et 5.
  - **comment** (optionnel) : chaîne, pour améliorer la qualité du service.
  - **vehicleId** / **driverId** (optionnels) : envoyés par l’app pour tracer explicitement véhicule et chauffeur évalués.
- **Réponse attendue (201 ou 200) :**
  ```json
  {
    "id": "review_id",
    "reservationId": "vehicle_reservation_id",
    "vehicleReservationId": "vehicle_reservation_id",
    "note": 5,
    "comment": "Très bon trajet...",
    "vehicleId": "...",
    "driverId": "...",
    "createdAt": "2025-02-23T12:00:00.000Z"
  }
  ```
  - L’app s’attend à au moins : `id`, `reservationId` ou `vehicleReservationId`, `note`, `comment` (optionnel), `createdAt` (optionnel).

### 2.2 Récupérer l’évaluation d’une réservation

- **Méthode :** `GET`
- **URL :** `/vehicle-reservations/:id/review`
- **Authentification :** JWT.
- **Règles métier :**
  - Retourner l’évaluation associée à la réservation `id` si l’utilisateur connecté en est l’auteur (ou si c’est sa réservation).
  - Si aucune évaluation n’existe : **404** ou body vide / `null` (l’app gère les deux : 404 = pas d’évaluation).
- **Réponse attendue (200) :**
  ```json
  {
    "id": "review_id",
    "reservationId": "vehicle_reservation_id",
    "note": 5,
    "comment": "Très bon trajet...",
    "vehicleId": "...",
    "driverId": "...",
    "createdAt": "2025-02-23T12:00:00.000Z"
  }
  ```

**Résumé :**
- **POST /vehicle-reservations/:id/review** : créer (ou mettre à jour) une évaluation pour la réservation terminée (note 1–5, commentaire optionnel, optionnellement vehicleId/driverId).
- **GET /vehicle-reservations/:id/review** : récupérer l’évaluation de cette réservation (404 ou null si aucune).

---

## 3. Récapitulatif des modifications backend

| Élément | Action |
|--------|--------|
| **Historique des déplacements** | S’assurer que **GET /vehicle-reservations/me** retourne les réservations avec `vehicle` peuplé et de préférence `vehicle.ownerId` peuplé en User (chauffeur). Optionnel : filtre `?statut=TERMINEE`, tri date décroissante, champ `dureeTrajet` ou `dateHeureFin`. |
| **Évaluation après trajet** | Ajouter **POST /vehicle-reservations/:id/review** (body : note, comment, optionnel vehicleId/driverId) et **GET /vehicle-reservations/:id/review** (retourner l’évaluation ou 404). Une seule évaluation par réservation, réservation obligatoirement TERMINEE. |

---

## 4. Ce que l’app fait déjà (côté front)

- **Historique :** Écran « Historique des déplacements » qui liste les réservations **TERMINEE** de `GET /vehicle-reservations/me`, avec affichage véhicule + chauffeur (à partir de `vehicle` et `vehicle.owner`).
- **Évaluation :** Sur l’écran détail d’une réservation **TERMINEE**, bouton « Évaluer ce trajet » ; ouverture d’un dialogue (note 1–5 étoiles + commentaire optionnel) puis appel **POST /vehicle-reservations/:id/review**. Si une évaluation existe déjà (**GET /vehicle-reservations/:id/review**), affichage « Déjà évalué » avec la note et le commentaire.

Si vous avez des contraintes différentes (ex. nom des champs, un seul endpoint “reviews” global), indiquez-les et on adaptera l’app en conséquence.
