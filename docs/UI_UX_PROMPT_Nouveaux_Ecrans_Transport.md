# Prompt UI/UX — Nouveaux écrans Transport (Historique & Évaluation)

**À transmettre à l’IA responsable du design UI/UX** pour générer les maquettes / spécifications des écrans suivants dans l’application **Ma3ak** (mobilité inclusive, Tunisie, FR + AR).

---

## Contexte produit

- **Application :** Ma3ak — application mobile pour personnes en situation de handicap et leurs accompagnants (Tunisie).
- **Module concerné :** Transport adapté intelligent. Le **moyen de transport = véhicule** ; chaque trajet = réservation d’un **véhicule adapté** avec un **chauffeur** (propriétaire du véhicule) identifié.
- **Utilisateurs cibles :** Bénéficiaires (personnes en situation de handicap) qui réservent des véhicules et consultent l’historique / évaluent les trajets.
- **Langues :** Français et Arabe (RTL). Tous les textes doivent être prévus en bilingue.
- **Accessibilité :** Contraste minimum WCAG 4.5:1, tailles de police lisibles (16px body minimum), zones de touch suffisantes (min 44pt), éviter le seul usage de la couleur pour l’information.

---

## Design system existant (à respecter)

- **Thème :** Material 3, mode clair par défaut, dark mode supporté.
- **Couleur primaire :** Bleu `#1976D2` (primary), `#1565C0` (primary dark).
- **Surfaces :** Fond général `#FAFAFA`, cartes sur fond blanc, bordures légères.
- **Typographie :** Roboto ; titres 20–24px bold, corps 14–16px, labels 14px.
- **Composants :** Boutons avec `borderRadius: 12`, champs avec `borderRadius: 12`, cartes avec ombre légère et `borderRadius: 12`.
- **Icônes :** Material Icons (style outlined pour états inactifs, filled pour actifs).
- **Navigation :** AppBar avec titre centré, bouton retour à gauche ; pas de drawer sur ces écrans.

---

## Écran 1 — Historique des déplacements

### Objectif
Permettre à l’utilisateur de consulter la liste de **tous ses trajets passés** (réservations de véhicules terminées), avec pour chaque trajet : **véhicule** et **chauffeur** clairement identifiés.

### Accès
- Depuis l’onglet **Transport** : icône « Historique » dans l’AppBar.
- Depuis **Mes réservations de véhicules** : bouton « Historique des déplacements ».

### Structure de l’écran

1. **AppBar**
   - Titre : **« Historique des déplacements »** (FR) / **« سجل التنقلات »** (AR).
   - Retour : flèche gauche (retour à l’écran précédent).
   - Pas d’actions secondaires obligatoires (optionnel : filtre par période si besoin plus tard).

2. **Zone principale**
   - **Liste verticale** de cartes (une carte = un trajet passé).
   - **Pull-to-refresh** pour rafraîchir la liste.
   - Liste triée du **plus récent au plus ancien**.

3. **Contenu de chaque carte (un trajet)**
   - **En-tête de carte :**
     - **Avatar** du chauffeur (photo ou initiales / icône personne) à gauche.
     - **Date du trajet** (ex. 23/02/2025) en titre principal, gras.
     - **Heure** + **nom du véhicule** (marque + modèle) en sous-titre.
     - **Ligne « Chauffeur : [Nom du chauffeur] »** en texte secondaire.
     - Indication de navigation (chevron droit) à droite pour montrer que la carte est cliquable.
   - **Corps de carte (optionnel selon place) :**
     - **Lieu de départ** : icône type « trip_origin » (vert) + adresse sur une ligne (ou 2 avec ellipsis).
     - **Lieu d’arrivée** : icône type « location_on » (rouge) + adresse.
   - Au tap sur la carte : navigation vers l’**écran Détail de la réservation** (déjà existant), où l’utilisateur peut voir tout le détail et, si le trajet est terminé, **évaluer** le trajet.

4. **État vide**
   - Illustration ou grande icône (ex. « history » ou « directions_car » en gris).
   - Titre : **« Aucun déplacement enregistré »** (FR) / **« لا توجد تنقلات سابقة »** (AR).
   - Sous-titre optionnel : « Vos trajets passés apparaîtront ici. »

5. **États chargement / erreur**
   - **Chargement :** indicateur centré (spinner).
   - **Erreur :** icône d’erreur + message court + bouton « Réessayer ».

### Contraintes UI
- Cartes : padding interne confortable (16px), espacement entre cartes (12px).
- Texte secondaire en `onSurfaceVariant`, titres en `onSurface` gras.
- Couleur primaire pour les liens / chevron si souhaité.
- Prévoir **RTL** : avatar à droite en AR, chevron à gauche, alignement des textes.

---

## Écran 2 — Évaluation après trajet (section + dialogue)

### Contexte
Sur l’écran **Détail d’une réservation de véhicule** (déjà existant), lorsque le **statut = Terminée**, on affiche une **section dédiée à l’évaluation** du trajet (véhicule + chauffeur).

### Objectif
Permettre à l’utilisateur d’**évaluer le trajet** (note 1–5 étoiles + commentaire optionnel) pour améliorer la qualité du service. L’évaluation porte sur le **trajet / véhicule / chauffeur**.

---

### Cas A — L’utilisateur n’a pas encore évalué

1. **Section dans la page Détail réservation**
   - Un **bouton plein large** (Outlined ou Filled selon charte) :
     - Icône : « rate_review » ou « star_outline ».
     - Libellé : **« Évaluer ce trajet »** (FR) / **« تقييم الرحلة »** (AR).
   - Style : bordure primaire, coins arrondis 12, hauteur confortable (min 48pt).
   - Au tap : ouverture d’un **dialogue (modal)** d’évaluation.

2. **Dialogue d’évaluation**
   - **Titre du dialogue :** « Évaluer ce trajet » (FR) / « تقييم الرحلة » (AR).
   - **Bloc Note (obligatoire) :**
     - Label : « Note » (FR) / « التقييم » (AR).
     - **5 étoiles** cliquables (1 à 5). Étoiles pleines jusqu’à la note choisie, vides au-delà. Couleur : ambre/or (ex. `#FFA000` ou équivalent Material Amber).
     - Taille des étoiles suffisante pour le touch (min 44pt de zone active par étoile).
   - **Bloc Commentaire (optionnel) :**
     - Label : « Commentaire (optionnel) » (FR) / « تعليق (اختياري) » (AR).
     - Champ texte multiligne (2–3 lignes), bordure standard, `borderRadius: 12`.
     - Placeholder : ex. « Décrivez votre expérience... » (FR) / équivalent AR.
   - **Actions du dialogue :**
     - **Annuler / Ignorer** (texte ou outlined) : ferme le dialogue sans enregistrer.
     - **Envoyer l’évaluation** (bouton principal) : envoi de la note + commentaire, puis fermeture + message de confirmation (SnackBar : « Merci, votre évaluation a bien été enregistrée. »).
   - **État chargement :** pendant l’envoi, désactiver les boutons et afficher un indicateur (spinner) sur le bouton principal ou en ligne.

### Cas B — L’utilisateur a déjà évalué

1. **Section dans la page Détail réservation**
   - **Bloc en lecture seule** (fond légèrement grisé / surfaceContainerHighest, `borderRadius: 12`, padding 16).
   - **Titre de section :** icône étoile + **« Déjà évalué »** (FR) / **« تم التقييم »** (AR).
   - **Affichage de la note :** 5 étoiles (pleines jusqu’à la note donnée, vides après), même style ambre.
   - **Commentaire :** si présent, affiché en dessous en `bodyMedium`, lecture seule.

### Contraintes UI (évaluation)
- Dialogue : largeur raisonnable (pas plein écran sur tablette), padding interne généreux.
- Étoiles : cohérence entre l’état « sélection » dans le dialogue et l’état « déjà évalué » sur la page.
- Bouton « Envoyer » désactivé tant que la note n’est pas choisie (entre 1 et 5).
- Prévoir **RTL** pour le dialogue (titres, champs, boutons).

---

## Récapitulatif des écrans / composants à concevoir

| Élément | Type | Description courte |
|--------|------|--------------------|
| **Historique des déplacements** | Écran plein | Liste de cartes « trajet passé » (date, heure, véhicule, chauffeur, départ, arrivée), état vide, chargement, erreur. |
| **Carte trajet (historique)** | Composant liste | Carte cliquable avec avatar chauffeur, date/heure, véhicule, chauffeur, lieux. |
| **Section « Évaluer ce trajet »** | Section page | Bouton « Évaluer ce trajet » OU bloc « Déjà évalué » (note + commentaire). |
| **Dialogue Évaluation** | Modal | Titre, 5 étoiles, champ commentaire optionnel, Annuler + Envoyer. |

---

## Textes à prévoir (FR / AR)

- **Historique des déplacements** / **سجل التنقلات**
- **Aucun déplacement enregistré** / **لا توجد تنقلات سابقة**
- **Chauffeur** / **السائق**
- **Véhicule** / **المركبة**
- **Évaluer ce trajet** / **تقييم الرحلة**
- **Déjà évalué** / **تم التقييم**
- **Note** / **التقييم**
- **Commentaire (optionnel)** / **تعليق (اختياري)**
- **Envoyer l’évaluation** / **إرسال التقييم**
- **Merci, votre évaluation a bien été enregistrée.** / **شكراً، تم إرسال تقييمك.**

---

## Livrables attendus du designer / de l’IA UI/UX

1. **Maquettes** (Figma, Sketch ou équivalent) pour :
   - Écran Historique des déplacements (liste + état vide + un exemple de carte détaillée).
   - Écran Détail réservation avec section « Évaluer ce trajet » (deux variantes : bouton d’action vs « Déjà évalué »).
   - Dialogue d’évaluation (état initial + état avec note sélectionnée + état chargement).
2. **Spécifications** : couleurs (hex), typo (taille, graisse), espacements (padding/margin), rayons de bordure.
3. **Variante RTL (arabe)** : au moins une vue par écran pour vérifier alignements et hiérarchie.
4. **États** : vide, chargement, erreur pour l’historique ; désactivé / chargement pour le bouton d’envoi d’évaluation.

Utiliser ce document comme brief complet pour générer les écrans de manière cohérente avec l’existant Ma3ak et les bonnes pratiques d’accessibilité et de bilinguisme FR/AR.
