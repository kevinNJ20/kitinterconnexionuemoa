-- ================================================
-- BASE DE DONNÉES KIT D'INTERCONNEXION
-- ================================================

-- Table des manifestes reçus
CREATE TABLE IF NOT EXISTS manifestes_recus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_manifeste VARCHAR(50) UNIQUE NOT NULL,
    transporteur VARCHAR(100) NOT NULL,
    port_embarquement VARCHAR(50),
    port_debarquement VARCHAR(50),
    date_arrivee DATE,
    pays_origine VARCHAR(3),
    pays_destination VARCHAR(3),
    data_json CLOB,
    date_reception TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'RECU',
    INDEX idx_manifeste_numero (numero_manifeste),
    INDEX idx_manifeste_statut (statut),
    INDEX idx_manifeste_date (date_reception)
);

-- Table des paiements reçus
CREATE TABLE IF NOT EXISTS paiements_recus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_declaration VARCHAR(50) NOT NULL,
    manifeste_origine VARCHAR(50),
    montant_paye DECIMAL(12,2) NOT NULL,
    reference_paiement VARCHAR(100) UNIQUE,
    date_paiement TIMESTAMP,
    pays_declarant VARCHAR(3),
    mode_paiement VARCHAR(50) DEFAULT 'ELECTRONIQUE',
    date_reception TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'CONFIRME',
    INDEX idx_paiement_declaration (numero_declaration),
    INDEX idx_paiement_manifeste (manifeste_origine),
    INDEX idx_paiement_reference (reference_paiement)
);

-- Table des autorisations mainlevée
CREATE TABLE IF NOT EXISTS autorisations_mainlevee (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_manifeste VARCHAR(50) NOT NULL,
    numero_declaration VARCHAR(50),
    reference_autorisation VARCHAR(100) UNIQUE,
    montant_acquitte DECIMAL(12,2),
    pays_declarant VARCHAR(3),
    pays_origine VARCHAR(3),
    date_autorisation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_envoi TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'AUTORISE',
    INDEX idx_auth_manifeste (numero_manifeste),
    INDEX idx_auth_reference (reference_autorisation)
);

-- Table de traçabilité des échanges
CREATE TABLE IF NOT EXISTS tracabilite_echanges (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    type_operation VARCHAR(50) NOT NULL,
    pays_source VARCHAR(3),
    pays_destination VARCHAR(3),
    reference_operation VARCHAR(100),
    endpoint_source VARCHAR(200),
    endpoint_destination VARCHAR(200),
    payload_entrant CLOB,
    payload_sortant CLOB,
    statut_traitement VARCHAR(20),
    code_erreur VARCHAR(10),
    message_erreur VARCHAR(500),
    date_debut TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_fin TIMESTAMP,
    duree_traitement_ms BIGINT,
    INDEX idx_trace_operation (type_operation),
    INDEX idx_trace_statut (statut_traitement),
    INDEX idx_trace_date (date_debut)
);

-- Table des configurations pays
CREATE TABLE IF NOT EXISTS configurations_pays (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    code_pays VARCHAR(3) UNIQUE NOT NULL,
    nom_pays VARCHAR(100),
    type_pays VARCHAR(20), -- COTIER, HINTERLAND
    url_systeme VARCHAR(200),
    port_systeme INTEGER,
    api_key VARCHAR(100),
    statut VARCHAR(20) DEFAULT 'ACTIF',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des métriques
CREATE TABLE IF NOT EXISTS metriques_operations (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    date_mesure DATE,
    heure_mesure INTEGER, -- 0-23
    type_operation VARCHAR(50),
    pays_source VARCHAR(3),
    pays_destination VARCHAR(3),
    nombre_operations INTEGER DEFAULT 0,
    temps_reponse_moyen DECIMAL(8,2),
    nombre_erreurs INTEGER DEFAULT 0,
    volume_donnees_kb DECIMAL(10,2),
    PRIMARY KEY (date_mesure, heure_mesure, type_operation, pays_source, pays_destination)
);