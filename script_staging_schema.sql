CREATE SCHEMA IF NOT EXISTS staging;

-- Vider les tables si réexécution
DROP TABLE IF EXISTS staging.stg_ventes;
DROP TABLE IF EXISTS staging.stg_clients;
DROP TABLE IF EXISTS staging.stg_produits;

CREATE TABLE staging.stg_clients (
    code_client VARCHAR(255),
    nom         VARCHAR(255),
    prenom      VARCHAR(255),
    email       VARCHAR(255),
    ville       VARCHAR(255),
    pays        VARCHAR(255)
);

CREATE TABLE staging.stg_produits (
    produit_id       VARCHAR(255),
    nom_produit      VARCHAR(255),
    id_categorie     VARCHAR(255),
    prix_unitaire    VARCHAR(255),
    statut_catalogue VARCHAR(255),
    diagonale_pouces VARCHAR(255),
    ratio_ecran      VARCHAR(255),
    longueur_std_cm  VARCHAR(255),
    largeur_std_cm   VARCHAR(255),
    hauteur_std_cm   VARCHAR(255)
);

CREATE TABLE staging.stg_ventes (
    id_commande    VARCHAR(255),
    date_commande  VARCHAR(255),
    client_id      VARCHAR(255),
    produit_id     VARCHAR(255),
    quantite       VARCHAR(255),
    prix_facture   VARCHAR(255),
    remise_pct     VARCHAR(255),
    qte_par_pack   VARCHAR(255),
    mode_livraison VARCHAR(255)
);