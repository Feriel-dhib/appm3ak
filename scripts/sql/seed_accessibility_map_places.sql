-- ═══════════════════════════════════════════════════════════════════════════
-- M3ak — données de démo : lieux accessibles, avis (posts), utilisateurs
-- Compatible logique Flutter : GET /lieux → LocationModel → AccessiblePlace
-- (voir `LocationRepository.getAllLocations` + `AccessiblePlace.fromLocation`).
--
-- Adapter les noms de tables / colonnes à votre backend (Nest + Prisma,
-- Supabase, etc.). Les valeurs `categorie` et `statut` suivent les enums
-- Flutter : LocationCategory.toApiString() = UPPERCASE, LocationStatus idem.
-- ═══════════════════════════════════════════════════════════════════════════

BEGIN;

CREATE TABLE IF NOT EXISTS users (
  id              VARCHAR(64) PRIMARY KEY,
  email           TEXT UNIQUE NOT NULL,
  display_name    TEXT,
  preferred_lang  VARCHAR(8) DEFAULT 'fr',
  created_at      TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS lieux (
  id                    VARCHAR(64) PRIMARY KEY,
  nom                   TEXT NOT NULL,
  categorie             VARCHAR(32) NOT NULL DEFAULT 'HOSPITAL',
  adresse               TEXT NOT NULL DEFAULT '',
  ville                 TEXT NOT NULL DEFAULT 'Tunis',
  latitude              DOUBLE PRECISION NOT NULL,
  longitude             DOUBLE PRECISION NOT NULL,
  description           TEXT,
  telephone             TEXT,
  horaires              TEXT,
  statut                VARCHAR(16) NOT NULL DEFAULT 'APPROVED',
  score_accessibilite   INT CHECK (score_accessibilite BETWEEN 0 AND 100),
  ai_summary            TEXT,
  obstacle_present      BOOLEAN DEFAULT false,
  amenities             TEXT[] DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_lieux_ville ON lieux (ville);
CREATE INDEX IF NOT EXISTS idx_lieux_statut ON lieux (statut);

CREATE TABLE IF NOT EXISTS community_posts (
  id           VARCHAR(64) PRIMARY KEY,
  user_id      VARCHAR(64) NOT NULL REFERENCES users (id) ON DELETE CASCADE,
  contenu      TEXT NOT NULL,
  type         VARCHAR(32) NOT NULL,
  lieu_id      VARCHAR(64) REFERENCES lieux (id) ON DELETE SET NULL,
  has_place    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_posts_lieu ON community_posts (lieu_id);

-- ─── Utilisateurs fictifs ───────────────────────────────────────────────────
INSERT INTO users (id, email, display_name) VALUES
  ('u-demo-1', 'amina.k@demo.ma3ak', 'Amina K.'),
  ('u-demo-2', 'samir.b@demo.ma3ak', 'Samir B.'),
  ('u-demo-3', 'lea.m@demo.ma3ak', 'Léa M.')
ON CONFLICT (id) DO NOTHING;

-- ─── Lieux (alimentent « Accessibility Map & Places » via /lieux) ───────────
INSERT INTO lieux (
  id, nom, categorie, adresse, ville, latitude, longitude,
  description, statut, score_accessibilite, ai_summary, amenities
) VALUES
(
  'h001',
  'Hôpital Charles Nicolle',
  'HOSPITAL',
  'Rue des Forces de l''Ordre, Montfleury',
  'Tunis',
  36.833,
  10.1633,
  'L''hôpital Charles Nicolle présente des aspects positifs et négatifs en matière d''accessibilité. Les couloirs sont larges et les personnels sont bienveillants, mais l''ascenseur est souvent en panne et la signalétique est difficile à lire.',
  'APPROVED',
  72,
  'Synthèse : accueil favorable, ascenseurs peu fiables, signalétique perfectible.',
  ARRAY['wheelchair', 'elevator', 'accessible_toilets', 'audio_loop']
),
(
  'cafe-001',
  'Café du Théâtre',
  'RESTAURANT',
  'Avenue Habib Bourguiba',
  'Tunis',
  36.7992,
  10.1857,
  'Terrasse au rez-de-chaussée, rampe d''accès côté cour. WC adaptés au premier étage avec ascenseur étroit.',
  'APPROVED',
  68,
  NULL,
  ARRAY['wheelchair', 'ramp', 'accessible_toilets']
),
(
  'adm-001',
  'Municipalité de Tunis — accueil',
  'OTHER',
  'Place de la Victoire',
  'Tunis',
  36.8061,
  10.1712,
  'Guichet prioritaire signalé ; files longues en fin de matinée.',
  'APPROVED',
  61,
  NULL,
  ARRAY['wheelchair', 'braille']
)
ON CONFLICT (id) DO UPDATE SET
  nom = EXCLUDED.nom,
  description = EXCLUDED.description,
  score_accessibilite = EXCLUDED.score_accessibilite,
  amenities = EXCLUDED.amenities;

-- ─── Avis / posts liés aux lieux (communauté) ───────────────────────────────
INSERT INTO community_posts (id, user_id, contenu, type, lieu_id, has_place, created_at) VALUES
(
  'p-h001-1',
  'u-demo-1',
  'Hôpital Charles Nicolle (Tunis) : L''ascenseur est souvent en panne ; il faut prévoir un détour ou attendre très longtemps. Sinon personnel à l''écoute.',
  'handicapMoteur',
  'h001',
  true,
  now() - interval '10 days'
),
(
  'p-h001-2',
  'u-demo-2',
  'Hôpital Charles Nicolle (Tunis) : L''équipe est bienveillante, mais les bâtiments sont vieillissants et l''accessibilité varie selon les services.',
  'temoignage',
  'h001',
  true,
  now() - interval '12 days'
),
(
  'p-h001-3',
  'u-demo-3',
  'Hôpital Charles Nicolle (Tunis) : Le personnel m''a guidée jusqu''au bon service quand je ne voyais pas les panneaux : accueil très humain.',
  'handicapVisuel',
  'h001',
  true,
  now() - interval '14 days'
),
(
  'p-cafe-1',
  'u-demo-1',
  'Café du Théâtre : rampe correcte, mais passage un peu étroit aux heures de pointe.',
  'handicapMoteur',
  'cafe-001',
  true,
  now() - interval '3 days'
)
ON CONFLICT (id) DO NOTHING;

COMMIT;

-- ═══════════════════════════════════════════════════════════════════════════
-- Notes implémentation API
-- 1) GET /lieux doit renvoyer une liste JSON ou { "data": [ ... ] } avec au
--    minimum : id, nom, categorie, adresse, ville, latitude, longitude,
--    description?, statut?, scoreAccessibilite?, aiSummary?, amenities? (liste),
--    obstaclePresent?.
-- 2) Les scores détaillés Fauteuil / Surdité / Cécité (capture d’écran) sont
--    produits par POST /accessibility/analyze (Python / Nest), pas par ce SQL.
-- 3) Pour exposer les « 11 avis » côté web, ajouter un endpoint du type
--    GET /lieux/:id/posts qui joint community_posts sur lieu_id.
-- ═══════════════════════════════════════════════════════════════════════════
