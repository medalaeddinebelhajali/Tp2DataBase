-- ============================================================================
-- SCRIPT DDL COMPLET : CRÉATION DU DATA WAREHOUSE (SCHÉMA DW)
-- SGBD : PostgreSQL
-- ============================================================================

-- 1. Création du schéma de destination
CREATE SCHEMA IF NOT EXISTS dw;

-- Suppression préalable des tables (dans l'ordre inverse des dépendances FK)
DROP TABLE IF EXISTS dw.fact_ventes CASCADE;
DROP TABLE IF EXISTS dw.dim_client CASCADE;
DROP TABLE IF EXISTS dw.dim_produit CASCADE;
DROP TABLE IF EXISTS dw.dim_temps CASCADE;

-- ============================================================================
-- 2. DIMENSION CLIENT (dw.dim_client)
-- ============================================================================
CREATE TABLE dw.dim_client (
    id_client_sk   SERIAL PRIMARY KEY,           -- Clé substituée (Surrogate Key)
    code_client_bk VARCHAR(50) NOT NULL UNIQUE,  -- Clé métier source (Business Key)
    nom            VARCHAR(100),
    prenom         VARCHAR(100),
    email          VARCHAR(150),
    ville          VARCHAR(100),
    pays           VARCHAR(100) DEFAULT 'INCONNU'
);

-- Insertion de la ligne par défaut pour les clients orphelins / inconnus
INSERT INTO dw.dim_client (id_client_sk, code_client_bk, nom, prenom, email, ville, pays)
VALUES (-1, 'CLIENT_INCONNU', 'NON SPÉCIFIÉ', 'NON SPÉCIFIÉ', 'inconnu@dw.local', 'INCONNU', 'INCONNU')
ON CONFLICT (id_client_sk) DO NOTHING;

-- Réinitialisation de la séquence pour démarrer les vrais clients à 1
SELECT setval(pg_get_serial_sequence('dw.dim_client', 'id_client_sk'), 1, false);


-- ============================================================================
-- 3. DIMENSION PRODUIT (dw.dim_produit)
-- Contient les informations relatives aux catégories, écrans et dimensions colis
-- ============================================================================
CREATE TABLE dw.dim_produit (
    id_produit_sk    SERIAL PRIMARY KEY,          -- Clé substituée (Surrogate Key)
    ref_produit_bk   VARCHAR(50) NOT NULL UNIQUE, -- Clé métier source (Business Key)
    nom_produit      VARCHAR(150),
    categorie        VARCHAR(100) DEFAULT 'NON SPÉCIFIÉ', -- Provenant du lookup sur oltp.categories
    prix_catalogue   NUMERIC(10, 2),
    
    -- Extension Écrans / Moniteurs
    diagonale_pouces NUMERIC(4, 1),               -- Ex: 27.0, 24.0 (NULL si non-écran)
    ratio_ecran      VARCHAR(10),                 -- Ex: '16/9'
    
    -- Extension Dimensions Emballage Produit Standard
    longueur_std_cm  NUMERIC(6, 2),
    largeur_std_cm   NUMERIC(6, 2),
    hauteur_std_cm   NUMERIC(6, 2)
);

-- Insertion de la ligne par défaut pour les produits obsolètes / introuvables (-1)
INSERT INTO dw.dim_produit (
    id_produit_sk, ref_produit_bk, nom_produit, categorie, prix_catalogue, 
    diagonale_pouces, ratio_ecran, longueur_std_cm, largeur_std_cm, hauteur_std_cm
)
VALUES (
    -1, 'PROD_INCONNU', 'PRODUIT INACTIF OU INCONNU', 'NON SPÉCIFIÉ', 0.00,
    NULL, NULL, NULL, NULL, NULL
)
ON CONFLICT (id_produit_sk) DO NOTHING;

-- Réinitialisation de la séquence
SELECT setval(pg_get_serial_sequence('dw.dim_produit', 'id_produit_sk'), 1, false);


-- ============================================================================
-- 4. DIMENSION TEMPS (dw.dim_temps)
-- Clé primaire au format entier YYYYMMDD (ex: 20260927)
-- ============================================================================
CREATE TABLE dw.dim_temps (
    id_temps_sk   INT PRIMARY KEY,               -- Clé sous forme d'entier YYYYMMDD
    date_complete DATE NOT NULL,
    annee         INT NOT NULL,
    trimestre     INT NOT NULL,                  -- 1 à 4
    mois          INT NOT NULL,                  -- 1 à 12
    nom_mois      VARCHAR(20) NOT NULL,          -- Ex: 'Septembre'
    jour          INT NOT NULL,                  -- 1 à 31
    nom_jour        VARCHAR(20) NOT NULL,        -- Ex: 'Lundi'
    est_week_end    BOOLEAN NOT NULL          
);


-- ============================================================================
-- 5. TABLE DE FAITS VENTES (dw.fact_ventes)
-- Contient les métriques financières, l'unification des prix unitaires (Packs)
-- et le calcul du volume de colis pour la livraison
-- ============================================================================
CREATE TABLE dw.fact_ventes (
    id_fact_sk             BIGSERIAL PRIMARY KEY,  -- Clé substituée de la ligne de fait
    
    -- Clés Étrangères (Foreign Keys vers les Dimensions)
    id_client_sk           INT NOT NULL REFERENCES dw.dim_client(id_client_sk),
    id_produit_sk          INT NOT NULL REFERENCES dw.dim_produit(id_produit_sk),
    id_temps_sk            INT NOT NULL REFERENCES dw.dim_temps(id_temps_sk),
    
    -- Attributs dégénérés / Transactionnels
    id_commande_bk         VARCHAR(50) NOT NULL,   -- N° de commande métier
    mode_livraison         VARCHAR(50),            -- 'LIVRAISON_DOMICILE', 'RETRAIT_MAGASIN'
    
    -- Métriques de quantité et d'unification des Packs (RG-01)
    nbre_packs              INT,                   -- Nombre de packs achetés
	qte_par_pack              INT,                 -- Nombre d'unités contenues dans un pack
    qte_unitaire_totale    INT,                    -- Quantité réelle d'unités
    prix_unitaire_effectif NUMERIC(10, 2),         -- Prix ramené à 1 seule unité
    
    -- Métriques financières (KPIs)
    montant_brut           NUMERIC(10, 2),
    montant_remise         NUMERIC(10, 2),
    montant_net            NUMERIC(10, 2),
    
    -- Métriques logistiques / Géométrie du colis (RG-02)
    colis_longueur_cm      NUMERIC(6, 2),          -- Calculé ou extrait
    colis_largeur_cm       NUMERIC(6, 2),          -- Calculé ou extrait
    colis_hauteur_cm       NUMERIC(6, 2),          -- Calculé ou extrait
    colis_volume_cm3       NUMERIC(12, 2)          -- Volume total (L x l x h)
);

-- Création d'index pour optimiser les requêtes OLAP de jointure
CREATE INDEX idx_fk_fact_ventes_client  ON dw.fact_ventes(id_client_sk);
CREATE INDEX idx_fk_fact_ventes_produit ON dw.fact_ventes(id_produit_sk);
CREATE INDEX idx_fk_fact_ventes_temps   ON dw.fact_ventes(id_temps_sk);


-- ============================================================================
-- 3. SCRIPT D'ALIMENTATION AUTOMATIQUE DE LA DIMENSION TEMPS (2024 - 2026)
-- ============================================================================
INSERT INTO dw.dim_temps (id_temps_sk, date_complete, annee, trimestre, mois, nom_mois, jour, nom_jour, est_week_end)
SELECT 
    TO_CHAR(datum, 'YYYYMMDD')::INT AS id_temps_sk,
    datum AS date_complete,
    EXTRACT(YEAR FROM datum)::INT AS annee,
    EXTRACT(QUARTER FROM datum)::INT AS trimestre,
    EXTRACT(MONTH FROM datum)::INT AS mois,
    TO_CHAR(datum, 'TMMonth') AS nom_mois,
    EXTRACT(DAY FROM datum)::INT AS jour,
    TO_CHAR(datum, 'TMDay') AS nom_jour,
    CASE WHEN EXTRACT(ISODOW FROM datum) IN (6, 7) THEN TRUE ELSE FALSE END AS est_week_end
FROM generate_series(
    '2024-01-01'::DATE,
    '2028-12-31'::DATE,
    '1 day'::INTERVAL
) AS datum;