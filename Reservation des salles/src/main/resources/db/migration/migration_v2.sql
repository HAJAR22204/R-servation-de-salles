-- Script de migration pour la version 2.0 de l'application "Réservation de salles"
-- À exécuter sur une base de données existante pour la mettre à jour

-- 1. Sauvegarde des données existantes (à exécuter avant la migration)
CREATE TABLE IF NOT EXISTS backup_utilisateurs AS SELECT * FROM utilisateurs;
CREATE TABLE IF NOT EXISTS backup_salles AS SELECT * FROM salles;
CREATE TABLE IF NOT EXISTS backup_reservations AS SELECT * FROM reservations;
CREATE TABLE IF NOT EXISTS backup_equipements AS SELECT * FROM equipements;
CREATE TABLE IF NOT EXISTS backup_salle_equipement AS SELECT * FROM salle_equipement;

-- 2. Ajout de nouvelles colonnes aux tables existantes

-- Table utilisateurs: ajout de la colonne departement
ALTER TABLE utilisateurs ADD COLUMN IF NOT EXISTS departement VARCHAR(100);

-- Table salles: ajout des colonnes numero et version
ALTER TABLE salles ADD COLUMN IF NOT EXISTS numero VARCHAR(20);
ALTER TABLE salles ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- Table equipements: ajout des colonnes reference et version
ALTER TABLE equipements ADD COLUMN IF NOT EXISTS reference VARCHAR(50);
ALTER TABLE equipements ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- Table reservations: ajout des colonnes statut et version
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS statut VARCHAR(20) DEFAULT 'CONFIRMEE';
ALTER TABLE reservations ADD COLUMN IF NOT EXISTS version BIGINT DEFAULT 0;

-- 3. Mise à jour des données existantes

-- Mise à jour des numéros de salle basés sur le nom (extraction du numéro à partir du nom)
UPDATE salles SET numero = SUBSTRING(nom FROM '[A-Za-z]+([0-9]+)' FOR 1) WHERE numero IS NULL;

-- Mise à jour des statuts de réservation (toutes confirmées par défaut)
UPDATE reservations SET statut = 'CONFIRMEE' WHERE statut IS NULL;

-- 4. Création des index pour améliorer les performances

-- Index sur les dates de réservation pour accélérer les recherches de disponibilité
CREATE INDEX IF NOT EXISTS idx_reservation_dates ON reservations(date_debut, date_fin);

-- Index sur le statut des réservations
CREATE INDEX IF NOT EXISTS idx_reservation_statut ON reservations(statut);

-- Index sur la capacité des salles pour les recherches par capacité
CREATE INDEX IF NOT EXISTS idx_salle_capacite ON salles(capacite);

-- Index sur le bâtiment et l'étage pour les recherches multi-critères
CREATE INDEX IF NOT EXISTS idx_salle_batiment_etage ON salles(batiment, etage);

-- 5. Création de contraintes supplémentaires

-- Contrainte pour s'assurer que la date de fin est après la date de début
ALTER TABLE reservations ADD CONSTRAINT IF NOT EXISTS check_dates_coherentes
    CHECK (date_fin > date_debut);

-- Contrainte pour limiter les valeurs possibles du statut
ALTER TABLE reservations ADD CONSTRAINT IF NOT EXISTS check_statut_valide
    CHECK (statut IN ('CONFIRMEE', 'ANNULEE', 'EN_ATTENTE'));

-- 6. Création d'une vue pour faciliter les rapports

CREATE OR REPLACE VIEW vue_reservations_completes AS
SELECT
    r.id, r.date_debut, r.date_fin, r.motif, r.statut,
    u.nom AS nom_utilisateur, u.prenom AS prenom_utilisateur, u.email,
    s.nom AS nom_salle, s.capacite, s.batiment, s.etage, s.numero
FROM
    reservations r
        JOIN
    utilisateurs u ON r.utilisateur_id = u.id
        JOIN
    salles s ON r.salle_id = s.id;

-- 7. Création d'une procédure stockée pour nettoyer les anciennes réservations

DELIMITER //
CREATE PROCEDURE IF NOT EXISTS nettoyer_anciennes_reservations(IN nb_jours INT)
BEGIN
DELETE FROM reservations
WHERE date_fin < DATE_SUB(CURRENT_DATE(), INTERVAL nb_jours DAY)
  AND statut = 'ANNULEE';
END //
DELIMITER ;

-- 8. Mise à jour de la version de la base de données (table de métadonnées)

CREATE TABLE IF NOT EXISTS db_version (
                                          id INT PRIMARY KEY,
                                          version VARCHAR(10),
    date_mise_a_jour TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

INSERT INTO db_version (id, version) VALUES (1, '2.0')
    ON DUPLICATE KEY UPDATE version = '2.0', date_mise_a_jour = CURRENT_TIMESTAMP;

ALTER TABLE salles ADD COLUMN version BIGINT
ALTER TABLE reservations ADD COLUMN version BIGINT