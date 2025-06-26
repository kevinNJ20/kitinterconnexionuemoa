-- Table des manifestes reçus
CREATE TABLE IF NOT EXISTS manifestes_recus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_manifeste VARCHAR(50) UNIQUE NOT NULL,
    transporteur VARCHAR(100),
    port_embarquement VARCHAR(50),
    port_debarquement VARCHAR(50),
    date_arrivee DATE,
    pays_destination VARCHAR(3),
    data_json CLOB,
    date_reception TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'RECU'
);

-- Table des paiements reçus
CREATE TABLE IF NOT EXISTS paiements_recus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_declaration VARCHAR(50) NOT NULL,
    manifeste_origine VARCHAR(50),
    montant_paye DECIMAL(12,2),
    reference_paiement VARCHAR(100),
    date_paiement TIMESTAMP,
    pays_declarant VARCHAR(3),
    date_reception TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'RECU'
);

-- Table des autorisations mainlevée
CREATE TABLE IF NOT EXISTS autorisations_mainlevee (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_manifeste VARCHAR(50),
    numero_declaration VARCHAR(50),
    reference_autorisation VARCHAR(100) UNIQUE,
    montant_acquitte DECIMAL(12,2),
    pays_declarant VARCHAR(3),
    date_autorisation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'AUTORISE'
);

-- Table de traçabilité des échanges
CREATE TABLE IF NOT EXISTS tracabilite_echanges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    type_operation VARCHAR(50),
    pays_source VARCHAR(3),
    pays_destination VARCHAR(3),
    reference_operation VARCHAR(100),
    payload_entrant CLOB,
    payload_sortant CLOB,
    statut_traitement VARCHAR(20),
    date_traitement TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    duree_traitement_ms BIGINT
);

-- Insertion de données de test
INSERT INTO manifestes_recus (numero_manifeste, transporteur, port_embarquement, port_debarquement, date_arrivee, pays_destination, data_json, statut) VALUES
('MAN2025001', 'MAERSK LINE', 'ROTTERDAM', 'ABIDJAN', '2025-01-15', 'BFA', '{"test": true}', 'RECU'),
('MAN2025002', 'CMA CGM', 'HAMBURG', 'DAKAR', '2025-01-16', 'MLI', '{"test": true}', 'RECU');