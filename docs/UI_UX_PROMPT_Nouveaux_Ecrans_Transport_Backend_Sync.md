# Prompt UI/UX — Nouveaux écrans Transport (synchronisation backend)

**À transmettre à l’IA responsable du design UI/UX** pour concevoir ou affiner les maquettes des écrans suivants dans l’application **Ma3ak** (mobilité inclusive, Tunisie, FR + AR). Ces écrans sont liés aux nouvelles fonctionnalités du module Transport adapté (API NestJS).

---

## Contexte produit

- **Application :** Ma3ak — application mobile pour personnes en situation de handicap et leurs accompagnants (Tunisie).
- **Module :** Transport adapté intelligent. Chaque demande de transport peut être **acceptée** par un accompagnant (chauffeur), avec **véhicule** optionnel, **ETA**, **suivi en direct**, et **clôture** (trajet terminé avec durée).
- **Utilisateurs :** Bénéficiaires (demandeurs) et Accompagnants (chauffeurs). Les deux peuvent consulter le détail d’un trajet, terminer le trajet, et voir l’historique avec durée.
- **Langues :** Français et Arabe (RTL). Tous les libellés en bilingue.
- **Accessibilité :** Contraste WCAG 4.5:1, zones de touch min 44pt, ne pas s’appuyer uniquement sur la couleur.

---

## Design system existant (à respecter)

- **Thème :** Material 3, mode clair par défaut, dark mode supporté.
- **Couleur primaire :** Bleu `#1976D2` ; urgence : rouge (ex. `#C62828` ou teinte rouge Material).
- **Surfaces :** Fond `#FAFAFA`, cartes blanches, `borderRadius: 12`.
- **Typographie :** Titres 20–24px bold, corps 14–16px, labels 14px.
- **Navigation :** AppBar avec titre centré, bouton retour à gauche.

---

## Écran 1 — Détail d’une demande de transport

### Objectif
Afficher **toutes les informations** d’une demande de transport (GET /transport/:id) : statut, trajet (départ / arrivée), demandeur, accompagnant/chauffeur, **véhicule** (si assigné), types d’assistance. Si le trajet est **accepté** : ETA en temps quasi réel, bouton **Terminer le trajet**, accès au **Suivi en direct**. Si le trajet est **terminé** : durée du trajet et heure d’arrivée.

### Accès
- Depuis la liste **Demandes de transport** (accompagnant) : tap sur « Détails » d’une carte.
- Depuis **Mes demandes de transport** : tap sur une carte.
- Route : `/transport/:id`.

### Structure de l’écran

1. **AppBar**
   - Titre : **« Détails du trajet »** (FR) / **« تفاصيل الرحلة »** (AR).
   - Retour : flèche gauche.
   - **Action (si trajet accepté) :** Icône « Suivi en direct » (ex. `location_on` ou `gps_fixed`) qui ouvre l’écran Suivi en direct.

2. **Zone principale (scroll vertical)**
   - **Chip / badge de statut** en haut : EN_ATTENTE (orange), ACCEPTEE (bleu), TERMINEE (vert), ANNULEE (gris). Texte lisible, contraste suffisant.
   - **Section Trajet :** Libellé « DÉPART / ARRIVÉE » puis adresses (départ, destination), type de transport (Urgence / Quotidien), date et heure. Si présents : **chips « Types d’assistance »** (ex. Fauteuil roulant, Aide à l’embarquement).
   - **Section Bénéficiaire (demandeur) :** Titre « Bénéficiaire », avatar + nom + téléphone (si disponible).
   - **Section Chauffeur :** Titre « Chauffeur », avatar + nom + téléphone (si disponible).
   - **Section Véhicule (si présent) :** Titre « Véhicule », icône voiture + marque/modèle + immatriculation.
   - **Si statut ACCEPTEE :**
     - **Bloc ETA :** Texte mis en avant du type « Arrivée estimée dans **X min** » (rafraîchi périodiquement), optionnel « Y km ».
     - **Bouton principal :** « Terminer le trajet » (icône check), pleine largeur, style FilledButton.
   - **Si statut TERMINEE :**
     - **Bloc durée :** « 25 min » (ou équivalent localisé).
     - **Heure d’arrivée** affichée (date/heure ou heure seule selon place).

3. **Dialogue « Terminer le trajet »**
   - Titre : « Terminer le trajet » (FR) / « إنهاء الرحلة » (AR).
   - Sous-titre : « Durée ou heure d’arrivée (optionnel) ».
   - Champ optionnel : **Durée (minutes)** (champ numérique).
   - Bouton : « Maintenant » pour définir l’heure d’arrivée à l’instant.
   - Actions : Annuler | Enregistrer. Au succès : message court type « Trajet terminé » puis retour à la liste ou rafraîchissement du détail.

4. **États**
   - **Chargement :** Spinner centré.
   - **Erreur / introuvable :** Message + bouton « Réessayer » ou retour.

### Contraintes UI
- Espacement cohérent (16px padding cartes, 12–16px entre sections).
- RTL : inverser ordre avatar/texte, aligner les sections.

---

## Écran 2 — Suivi en direct

### Objectif
Permettre au **demandeur** (ou à l’accompagnant) de suivre le trajet en cours sur une **carte** : **position du chauffeur**, **itinéraire** (ligne entre points), **départ** et **arrivée**. Afficher l’**ETA** (arrivée estimée dans X min) dans une barre en bas. Données fournies par GET /transport/:id/suivi (rafraîchies périodiquement, ex. toutes les 15 s).

### Accès
- Depuis l’écran **Détail d’une demande** (trajet en statut ACCEPTEE) : icône « Suivi en direct » dans l’AppBar.
- Route : `/transport/:id/suivi`.

### Structure de l’écran

1. **AppBar**
   - Titre : **« Suivi en direct »** (FR) / **« التتبع المباشر »** (AR).
   - Retour : flèche gauche (retour au détail).

2. **Carte (plein écran ou quasi)**
   - **Carte interactive** (type OpenStreetMap / fond type Voyager) avec :
     - **Marqueur départ** : icône type « trip_origin » (vert).
     - **Marqueur arrivée** : icône type « location_on » (rouge).
     - **Marqueur position chauffeur** : icône type « directions_car » (bleu), mis à jour à chaque refresh.
     - **Polyline / itinéraire** : ligne (couleur primaire, épaisseur ~4) reliant les points de l’itinéraire si l’API renvoie une géométrie (LineString).
   - **Zoom / centrage** : adapter la vue pour inclure départ, arrivée et position chauffeur (avec marge).

3. **Barre inférieure (au-dessus du safe area)**
   - Fond légèrement distinct (ex. surfaceContainerHighest).
   - **Ligne principale :** « Arrivée estimée dans **X min** » (gras, couleur primaire).
   - **Ligne secondaire (optionnelle) :** « Y km » (distance restante).

4. **États**
   - **Chargement initial :** Spinner ou skeleton sur la carte.
   - **Erreur :** Message + bouton « Réessayer ».
   - **Pas d’itinéraire :** Carte affichée avec au minimum départ, arrivée et position chauffeur (sans polyline).

### Contraintes UI
- Carte : hauteur suffisante pour lire les repères ; ne pas masquer les contrôles de zoom si présents.
- RTL : position de la barre ETA inchangée (en bas), textes RTL en arabe.

---

## Écran 3 — Mes demandes de transport

### Objectif
Afficher **toutes les demandes de transport** de l’utilisateur connecté : en tant que **demandeur** et en tant qu’**accompagnant** (GET /transport/me). Liste fusionnée, triée du plus récent au plus ancien. Pour les trajets **terminés**, afficher clairement la **durée** (ex. « 25 min ») et l’**heure d’arrivée** (optionnel). Chaque carte est cliquable et mène au **Détail** (écran 1).

### Accès
- Depuis l’écran **Historique des trajets** : icône « Liste » / « Mes demandes de transport » dans l’AppBar.
- Route : `/transport/my-requests`.

### Structure de l’écran

1. **AppBar**
   - Titre : **« Mes demandes de transport »** (FR) / équivalent AR.
   - Action : Icône « Rafraîchir » pour recharger la liste.

2. **Liste**
   - **Pull-to-refresh** pour recharger.
   - **Une carte par demande** (scroll vertical).
   - **Contenu de chaque carte :**
     - **Ligne 1 :** Destination (ou départ si pas de destination) en titre, **badge statut** à droite (EN_ATTENTE / ACCEPTEE / TERMINEE / ANNULEE) avec couleur cohérente (orange / bleu / vert / gris).
     - **Ligne 2 :** Contexte « En tant que demandeur » ou « En tant qu’accompagnant » (texte secondaire).
     - **Si trajet TERMINEE :** Ligne « **25 min** » (ex.) + optionnel « Arrivée 08:25 » (heure).
     - **Ligne de navigation :** « < Détails » ou chevron (lien vers l’écran Détail).
   - Tap sur toute la carte : navigation vers `/transport/:id`.

3. **État vide**
   - Grande icône (ex. `directions_car_outlined`) en gris/primary.
   - Texte : **« Aucune demande de transport »** (FR) / équivalent AR.

4. **États chargement / erreur**
   - Chargement : spinner centré.
   - Erreur : message + bouton « Enregistrer » ou « Réessayer ».

### Contraintes UI
- Cartes : padding 16px, espacement entre cartes 12px. RTL : badge à gauche si nécessaire, texte « Détails » aligné.

---

## Écran 4 — Demandes de transport (liste pour accompagnants) — évolutions

### Objectif
Écran existant **« Demandes de transport »** (demandes disponibles pour les accompagnants). À faire évoluer pour :
- Mettre en avant les **urgences** (badge « Urgence » visible).
- Proposer le **choix du véhicule** à l’acceptation (bottom sheet).
- Lien **« Détails »** sur chaque carte vers l’écran Détail (écran 1).

### Accès
- Depuis l’onglet Accompagnant / « Mes bénéficiaires » (ou équivalent).
- Route : `/beneficiaires` (ou celle utilisée pour cet écran).

### Évolutions à concevoir

1. **Carte demande (liste)**
   - **Badge « Urgence »** : pour les demandes de type URGENCE, afficher un badge rouge/orange bien visible (ex. « Urgence » / « عاجل ») à côté du nom du demandeur ou en haut à droite de la carte.
   - **Ligne type de transport :** Afficher « Transport d’urgence » ou « Transport quotidien » (libellés localisés) au lieu du code brut.
   - **Bouton / lien « Détails »** : en plus des boutons « Ignorer » et « Accepter », ajouter un lien « Détails » (ou icône info) qui ouvre l’écran Détail (`/transport/:id`).

2. **Bottom sheet « Choisir le véhicule »**
   - **Déclencheur :** Au tap sur **« Accepter »**, si l’accompagnant a au moins un véhicule enregistré, ouvrir un **bottom sheet** (modal depuis le bas) avant d’envoyer l’acceptation.
   - **Titre :** « Choisir le véhicule pour ce trajet » (FR) / « اختر المركبة لهذه الرحلة » (AR).
   - **Options :**
     - **« Sans véhicule »** : une ligne cliquable (ferme le sheet et envoie l’acceptation sans vehicleId).
     - **Liste des véhicules** : pour chaque véhicule, une ligne avec **marque + modèle** (titre) et **immatriculation** (sous-titre). Au tap : fermer le sheet et envoyer l’acceptation avec ce vehicleId.
   - **Comportement :** Si l’accompagnant n’a aucun véhicule, ne pas afficher le sheet et accepter directement sans vehicleId.

### Contraintes UI
- Bottom sheet : SafeArea, padding 16px, titres en titleMedium. RTL : alignement des listes.

---

## Écran 5 — Création de demande de transport — types d’assistance

### Objectif
Sur l’écran **existant** de création d’une demande de transport, la section **« Type d’assistance »** doit permettre une **sélection multiple** (au moins : Fauteuil roulant, Aide à l’embarquement). Les valeurs envoyées au backend sont par ex. `fauteuil_roulant`, `aide_embarquement`. L’UI doit être claire et accessible.

### Évolutions à concevoir

1. **Section « Type d’assistance »**
   - Titre : **« Type d’assistance »** (FR) / **« نوع المساعدة »** (AR).
   - **Chips ou boutons à bascule** (multi-select) :
     - **« Fauteuil roulant »** (FR) / **« كرسي متحرك »** (AR) — valeur backend `fauteuil_roulant`.
     - **« Aide à l’embarquement »** (FR) / **« مساعدة الصعود »** (AR) — valeur backend `aide_embarquement`.
   - L’utilisateur peut cocher **aucun, un ou les deux**. État sélectionné visuellement distinct (couleur primaire / fond rempli).

2. **Placement**
   - Conserver la cohérence avec le reste du formulaire (adresses, type de transport, date/heure). Espacement 8–12px entre les chips.

### Contraintes UI
- Zones de touch suffisantes pour chaque chip. RTL : ordre des chips adapté (droite à gauche en AR).

---

## Récapitulatif des écrans / composants

| Écran / Composant              | Route / Contexte                    | Rôle principal |
|--------------------------------|-------------------------------------|----------------|
| Détail demande de transport    | `/transport/:id`                    | Demandeur + Accompagnant |
| Suivi en direct                 | `/transport/:id/suivi`              | Demandeur + Accompagnant |
| Mes demandes de transport       | `/transport/my-requests`            | Demandeur + Accompagnant |
| Demandes disponibles (liste)    | `/beneficiaires` (ou équivalent)    | Accompagnant   |
| Création demande (types assist.)| Formulaire création transport       | Demandeur      |

---

## Libellés bilingues à prévoir (référence)

- **Détails du trajet** / تفاصيل الرحلة  
- **Suivi en direct** / التتبع المباشر  
- **Terminer le trajet** / إنهاء الرحلة  
- **Arrivée estimée dans X min** / الوصول المتوقع خلال X د  
- **Mes demandes de transport** / (équivalent AR)  
- **Urgence** / عاجل  
- **Choisir le véhicule pour ce trajet** / اختر المركبة لهذه الرحلة  
- **Sans véhicule** / بدون مركبة  
- **Type d’assistance** / نوع المساعدة  
- **Fauteuil roulant** / كرسي متحرك  
- **Aide à l’embarquement** / مساعدة الصعود  

---

*Document pour la synchronisation UI/UX avec le backend Transport adapté (NestJS). À utiliser par l’IA en charge du design pour générer ou ajuster les écrans correspondants.*
