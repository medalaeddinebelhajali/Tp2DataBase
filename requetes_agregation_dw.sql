-- ============================================================================
-- LIVRABLE 3 : REQUÊTES D'AGRÉGATION ANALYTIQUES SUR LE DATA WAREHOUSE (dw.fact_ventes)
-- Matière : Base de Données Avancée (L3DSI) - TP 2 ETL Pentaho Data Integration
-- ============================================================================

-- ----------------------------------------------------------------------------
-- REQUÊTE 1 : Chiffre d'affaires brut, remises et chiffre d'affaires net 
--             par pays du client et par mois (avec nombre de commandes et d'unités)
-- ----------------------------------------------------------------------------
SELECT 
    c.pays                                    AS pays_client,
    t.annee                                   AS annee,
    t.mois                                    AS num_mois,
    t.nom_mois                                AS mois,
    COUNT(DISTINCT f.id_commande_bk)          AS nombre_commandes,
    SUM(f.qte_unitaire_totale)                AS total_unites_vendues,
    SUM(f.montant_brut)                       AS ca_brut_total,
    SUM(f.montant_remise)                     AS total_remises,
    SUM(f.montant_net)                        AS ca_net_total
FROM dw.fact_ventes f
INNER JOIN dw.dim_client c ON f.id_client_sk = c.id_client_sk
INNER JOIN dw.dim_temps  t ON f.id_temps_sk  = t.id_temps_sk
GROUP BY 
    c.pays, 
    t.annee, 
    t.mois, 
    t.nom_mois
ORDER BY 
    t.annee ASC, 
    t.mois ASC, 
    ca_net_total DESC;

/*
RÉSULTAT ATTENDU DE LA REQUÊTE 1 (sur le jeu de données du TP) :
+--------------+-------+----------+-----------+------------------+----------------------+---------------+---------------+--------------+
| pays_client  | annee | num_mois | mois      | nombre_commandes | total_unites_vendues | ca_brut_total | total_remises | ca_net_total |
+--------------+-------+----------+-----------+------------------+----------------------+---------------+---------------+--------------+
| TUNISIE      |  2026 |        9 | Septembre |                4 |                    9 |        790.00 |         27.90 |       762.10 |
| INCONNU      |  2026 |        9 | Septembre |                2 |                    3 |        137.90 |          0.00 |       137.90 |
+--------------+-------+----------+-----------+------------------+----------------------+---------------+---------------+--------------+
*/


-- ----------------------------------------------------------------------------
-- REQUÊTE 2 : Analyse par catégorie de produit et mode de livraison 
--             (Chiffre d'affaires net, unités vendues après dépaquetage RG-01,
--              et volume logistique total en cm3 et en litres RG-02)
-- ----------------------------------------------------------------------------
SELECT 
    p.categorie                                      AS categorie_produit,
    f.mode_livraison                                 AS mode_livraison,
    COUNT(f.id_fact_sk)                              AS nb_lignes_ventes,
    SUM(f.nbre_packs)                                AS total_packs_vendus,
    SUM(f.qte_unitaire_totale)                       AS total_unites_reelles,
    SUM(f.montant_net)                               AS ca_net_categorie,
    ROUND(AVG(f.prix_unitaire_effectif), 2)          AS prix_unitaire_moyen_effectif,
    SUM(f.colis_volume_cm3)                          AS volume_total_colis_cm3,
    ROUND(SUM(f.colis_volume_cm3) / 1000.0, 2)       AS volume_total_colis_litres
FROM dw.fact_ventes f
INNER JOIN dw.dim_produit p ON f.id_produit_sk = p.id_produit_sk
GROUP BY 
    p.categorie, 
    f.mode_livraison
ORDER BY 
    ca_net_categorie DESC;

/*
RÉSULTAT ATTENDU DE LA REQUÊTE 2 (sur le jeu de données du TP) :
+---------------+--------------------+------------------+--------------------+----------------------+------------------+------------------------------+------------------------+---------------------------+
| categorie     | mode_livraison     | nb_lignes_ventes | total_packs_vendus | total_unites_reelles | ca_net_categorie | prix_unitaire_moyen_effectif | volume_total_colis_cm3 | volume_total_colis_litres |
+---------------+--------------------+------------------+--------------------+----------------------+------------------+------------------------------+------------------------+---------------------------+
| Informatique  | LIVRAISON_DOMICILE |                4 |                  4 |                    6 |           803.40 |                       200.48 |               63421.75 |                     63.42 |
| Informatique  | RETRAIT_MAGASIN    |                1 |                  2 |                    4 |            48.60 |                        13.50 |                   0.00 |                      0.00 |
| NON SPÉCIFIÉ  | RETRAIT_MAGASIN    |                1 |                  2 |                    2 |            48.00 |                        24.00 |                   0.00 |                      0.00 |
+---------------+--------------------+------------------+--------------------+----------------------+------------------+------------------------------+------------------------+---------------------------+
*/
