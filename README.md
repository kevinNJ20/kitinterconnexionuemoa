# Kit d'Interconnexion UEMOA

## Vue d'ensemble

Le **Kit d'Interconnexion UEMOA** est une solution MuleSoft permettant l'interconnexion des systèmes informatiques douaniers des États membres de l'Union Économique et Monétaire Ouest Africaine (UEMOA) dans le cadre de la mise en œuvre du régime de la libre pratique et du transit.

Cette API facilite les échanges de données entre les pays côtiers (points d'entrée) et les pays de l'hinterland (destinations finales) pour le suivi des marchandises et des procédures douanières.

## Table des matières

- [Contexte métier](#contexte-métier)
- [Architecture technique](#architecture-technique)
- [Workflows détaillés](#workflows-détaillés)
- [Services et endpoints](#services-et-endpoints)
- [Installation et configuration](#installation-et-configuration)
- [Utilisation de l'API](#utilisation-de-lapi)
- [Base de données](#base-de-données)
- [Monitoring et observabilité](#monitoring-et-observabilité)
- [Déploiement](#déploiement)
- [Dépannage](#dépannage)

---

## Contexte métier

### Problématique

Les pays de l'UEMOA font face à des défis majeurs dans la gestion des flux de marchandises :
- **Pays côtiers** (Sénégal, Côte d'Ivoire, Togo, Bénin) : Points d'entrée des marchandises
- **Pays enclavés** (Mali, Burkina Faso, Niger) : Destinations finales nécessitant une coordination

### Solution

Le Kit d'Interconnexion UEMOA centralise et automatise les échanges entre systèmes douaniers nationaux, permettant :
- ✅ Traçabilité complète des marchandises
- ✅ Réduction des délais de dédouanement
- ✅ Transparence des opérations
- ✅ Conformité aux standards UEMOA

### Cas d'usage principal

**Scénario type** : Marchandise destinée au Mali arrivant au Port de Dakar (Sénégal)

1. **Port de Dakar** → Enregistrement manifeste
2. **Kit MuleSoft** → Extraction et routage vers Mali
3. **Bamako** → Déclaration et paiement droits de douane
4. **Kit MuleSoft** → Transmission autorisation vers Dakar
5. **Port de Dakar** → Mainlevée et enlèvement marchandise
6. **Commission UEMOA** → Traçabilité et supervision

---

## Architecture technique

### Technologies et versions

| Composant | Version | Rôle |
|-----------|---------|------|
| **MuleSoft Mule Runtime** | 4.9.2 | Moteur d'intégration |
| **Java** | 17 | Runtime JVM |
| **APIKit** | 1.11.6 | Spécification API RAML |
| **PostgreSQL (Supabase)** | Latest | Base de données production |
| **H2 Database** | 2.3.232 | Base de données développement |
| **ActiveMQ** | 5.16.7 | Messaging asynchrone |
| **Maven** | 3.6+ | Gestion dépendances |

### Architecture décentralisée

```
┌─────────────────────────────────────────────────────────────────┐
│                     Architecture UEMOA                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐         ┌─────────┐ │
│  │   SÉNÉGAL    │────────▶│ KIT MULESOFT │────────▶│  MALI   │ │
│  │ (Port Dakar) │◀────────│ INTERCONNEXION│◀────────│(Bamako) │ │
│  └──────────────┘         └───────┬──────┘         └─────────┘ │
│   Pays côtier                     │                 Hinterland  │
│   (Prime abord)                   │                             │
│                                   ▼                             │
│                          ┌──────────────┐                       │
│                          │  COMMISSION  │                       │
│                          │    UEMOA     │                       │
│                          │ (Traçabilité)│                       │
│                          └──────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
```

### Composants du Kit d'Interconnexion

Le Kit MuleSoft intègre les composants suivants :

#### 1. Base de données embarquée (Supabase)
- **Tables de correspondance** : Mapping codes pays, bureaux douaniers
- **Données de référence** : Configurations système, paramètres UEMOA
- **Traçabilité** : Audit complet de toutes les opérations

#### 2. Serveur de fichiers (S)FTP
- **Stockage documents** : Documents accompagnant les déclarations
- **Gestion versions** : Historique des documents transmis
- **Sécurisation** : Accès contrôlé par authentification

#### 3. Moteur de batchs
- **Procédures automatisées** : Synchronisation inter-bases
- **Apurement manifestes** : Traitement automatique mainlevées
- **Statistiques** : Agrégation données pour Commission

#### 4. Gestionnaire de files d'attente (JMS ActiveMQ)
- **Messages asynchrones** : Communications non-bloquantes
- **Garantie livraison** : Retry automatique en cas d'échec
- **Ordonnancement** : Traitement séquentiel des messages

#### 5. Ensemble d'APIs REST
- **Calculs** : Droits de douane, taxes, garanties
- **Transformations** : Conversion formats UEMOA
- **Routage** : Distribution intelligente vers destinations

### Structure du projet

```
kitinterconnexionuemoa/
│
├── src/
│   ├── main/
│   │   ├── mule/                              # Flows MuleSoft
│   │   │   ├── global.xml                     # Configuration globale
│   │   │   ├── interface.xml                  # Endpoints API + CORS
│   │   │   └── implementation/
│   │   │       └── kit-impl.xml               # Logique métier workflows
│   │   │
│   │   └── resources/
│   │       ├── api/
│   │       │   └── kitinterconnexionuemoa.raml # Spécification RAML
│   │       ├── configs/
│   │       │   └── dev.yaml                   # Configuration environnements
│   │       ├── db/
│   │       │   ├── init.sql                   # Scripts H2 (dev)
│   │       │   └── init-interconnexion.sql    # Scripts Supabase (prod)
│   │       └── log4j2.xml                     # Configuration logging
│   │
│   └── test/                                  # Tests unitaires
│       └── resources/
│           └── log4j2-test.xml
│
├── pom.xml                                    # Configuration Maven
├── README.md                                  # Documentation
└── .gitignore                                 # Fichiers ignorés Git
```

---

## Workflows détaillés

### Workflow Libre Pratique (21 étapes)

Le workflow de libre pratique permet le dédouanement de marchandises destinées à un pays de l'hinterland mais arrivant dans un port côtier.

#### **PHASE 1 : Prise en charge et transmission (Étapes 1-5)**

```
Sénégal (Port de Dakar)                 Kit MuleSoft                Mali (Bamako)
        │                                      │                           │
        │  ÉTAPE 1 : Prise en charge          │                           │
        │  ─────────────────────────           │                           │
        │  Débarquement marchandises          │                           │
        │  au Port de Dakar                    │                           │
        │                                      │                           │
        │  ÉTAPE 2 : Enregistrement            │                           │
        │  ─────────────────────────           │                           │
        │  Création manifeste dans             │                           │
        │  système douanier sénégalais         │                           │
        │                                      │                           │
        │  ÉTAPE 3 : Validation                │                           │
        │  ─────────────────────────           │                           │
        │  Contrôles préliminaires             │                           │
        │  conformité documents                │                           │
        │                                      │                           │
        │  ÉTAPE 4 : Extraction                │                           │
        │  ─────────────────────────           │                           │
        │  Filtrage articles destinés          │                           │
        │  au Mali uniquement                  │                           │
        │                                      │                           │
        │  ÉTAPE 5 : Transmission              │                           │
        │──POST /manifeste/transmission───────▶│                           │
        │  Headers:                            │  RÉCEPTION ET ROUTAGE     │
        │  - X-Source-Country: SEN             │  ─────────────────────    │
        │  - X-Correlation-ID: xxx             │  • Validation format      │
        │                                      │  • Stockage Supabase      │
        │                                      │  • Extraction articles    │
        │                                      │  • Transformation UEMOA   │
        │                                      │                           │
        │                                      │──POST /manifeste/reception─▶
        │                                      │  Vers Mali Bamako          │
        │                                      │  Format: UEMOA 2025.1      │
        │                                      │                           │
```

**Détails techniques Étape 5** :

**Endpoint** : `POST /api/v1/manifeste/transmission`

**Headers requis** :
```http
X-Source-Country: SEN
X-Source-System: SENEGAL_DOUANES_DAKAR
X-Correlation-ID: SEN_20250115_5016
X-Manifeste-Format: UEMOA
```

**Payload exemple** :
```json
{
  "annee_manif": "2025",
  "bureau_manif": "18N",
  "numero_manif": 5016,
  "consignataire": "MAERSK LINE SENEGAL",
  "navire": "MARCO POLO",
  "provenance": "ROTTERDAM",
  "date_arrivee": "2025-01-15",
  "paysOrigine": "SENEGAL",
  "portDebarquement": "Port de Dakar",
  "etapeWorkflow": 5,
  "nbre_article": 2,
  "articles": [
    {
      "art": 1,
      "pays_dest": "MALI",
      "ville_dest": "BAMAKO",
      "marchandise": "Véhicule particulier Toyota Corolla",
      "poids": 1500,
      "destinataire": "IMPORT SARL BAMAKO",
      "connaissement": "233698813",
      "nbre_colis": 1
    },
    {
      "art": 2,
      "pays_dest": "MALI",
      "ville_dest": "BAMAKO",
      "marchandise": "Pièces détachées automobiles",
      "poids": 500,
      "destinataire": "AUTO PIECES MALI",
      "connaissement": "233698814",
      "nbre_colis": 10
    }
  ]
}
```

**Traitement dans le Kit** :
1. ✅ Validation format UEMOA 2025.1
2. ✅ Vérification champs obligatoires (numero_manif, pays_dest)
3. ✅ Génération correlation ID unique si absent
4. ✅ Stockage dans Supabase table `manifestes_recus`
5. ✅ Filtrage articles Mali uniquement
6. ✅ Transformation vers format Mali
7. ✅ Transmission vers endpoint Mali `/api/manifeste/reception`
8. ✅ Notification asynchrone Commission UEMOA (Étape 20)

---

#### **PHASE 2 : Traitement au pays de destination (Étapes 6-13)**

```
        │                                      │                           │
        │                                      │  ÉTAPE 6 : Réception      │
        │                                      │  ◀────────────────────────┤
        │                                      │  Enregistrement manifeste │
        │                                      │  dans système malien      │
        │                                      │                           │
        │                                      │  ÉTAPE 7 : Documents       │
        │                                      │  ──────────────────────────┤
        │                                      │  Collecte pré-dédouanement│
        │                                      │  via GUCE Mali            │
        │                                      │                           │
        │                                      │  ÉTAPE 8 : Déclaration     │
        │                                      │  ──────────────────────────┤
        │                                      │  Établissement déclaration│
        │                                      │  par déclarant malien     │
        │                                      │                           │
        │                                      │  ÉTAPE 9 : Contrôles       │
        │                                      │  ──────────────────────────┤
        │                                      │  Recevabilité déclaration │
        │                                      │  vérifications formelles  │
        │                                      │                           │
        │                                      │  ÉTAPE 10 : Calcul devis   │
        │                                      │  ──────────────────────────┤
        │                                      │  Pré-liquidation droits   │
        │                                      │  et taxes (simulation)    │
        │                                      │                           │
        │                                      │  ÉTAPE 11 : Enregistrement │
        │                                      │  ──────────────────────────┤
        │                                      │  Déclaration détaillée    │
        │                                      │  définitive               │
        │                                      │                           │
        │                                      │  ÉTAPE 12 : Contrôles      │
        │                                      │  ──────────────────────────┤
        │                                      │  Douaniers (documents +   │
        │                                      │  marchandises physiques)  │
        │                                      │                           │
        │                                      │  ÉTAPE 13 : Liquidation    │
        │                                      │  ──────────────────────────┤
        │                                      │  Émission bulletin avec   │
        │                                      │  montants définitifs      │
        │                                      │                           │
```

**Processus Mali (Étapes 6-13)** :
- **Étape 6** : Réception manifeste via Kit → Enregistrement système malien
- **Étape 7** : Importateur collecte documents via GUCE Mali
- **Étape 8** : Déclarant établit déclaration détaillée (type, valeur, origine)
- **Étape 9** : Douanes vérifient recevabilité (documents complets, cohérents)
- **Étape 10** : Système calcule pré-liquidation (droits + taxes estimés)
- **Étape 11** : Enregistrement déclaration définitive avec numéro unique
- **Étape 12** : Contrôles douaniers (documentaires + visite physique si nécessaire)
- **Étape 13** : Émission bulletin de liquidation (montants définitifs à payer)

---

#### **PHASE 3 : Paiement et autorisation (Étapes 14-16)**

```
        │                                      │                           │
        │                                      │  ÉTAPE 14 : Paiement       │
        │                                      │  ──────────────────────────┤
        │                                      │  Paiement droits et taxes │
        │                                      │  via BCEAO/Trésor Mali   │
        │                                      │                           │
        │                                      │  ÉTAPE 15 : Confirmation   │
        │                                      │  ──────────────────────────┤
        │                                      │  Validation paiement +    │
        │                                      │  génération autorisation  │
        │                                      │                           │
        │                                      │  ÉTAPE 16 : Transmission   │
        │                                      │◀──POST /declaration/soumission
        │                                      │  Headers:                 │
        │  RÉCEPTION DÉCLARATION              │  - X-Source-Country: MLI  │
        │  ─────────────────────              │                           │
        │  • Validation paiement Mali         │                           │
        │  • Stockage Supabase                │                           │
        │  • Génération autorisation          │                           │
        │  • Transformation format Sénégal    │                           │
        │                                      │                           │
```

**Détails techniques Étape 16** :

**Endpoint** : `POST /api/v1/declaration/soumission`

**Headers requis** :
```http
X-Source-Country: MLI
X-Source-System: MALI_DOUANES_BAMAKO
X-Correlation-ID: MLI_20250115_DEC001
```

**Payload exemple** :
```json
{
  "numeroDeclaration": "DEC-MLI-2025-001",
  "manifesteOrigine": "5016",
  "anneeDecl": "2025",
  "bureauDecl": "10S_BAMAKO",
  "dateDecl": "2025-01-18",
  "montantPaye": 2750000,
  "referencePaiement": "PAY-MLI-2025-001",
  "datePaiement": "2025-01-18T14:30:00Z",
  "paysDeclarant": "MLI",
  "articles": [
    {
      "numArt": 1,
      "codeSh": "8703210000",
      "designationCom": "Véhicule Toyota Corolla essence",
      "valeurCaf": 15000000,
      "liquidation": 2500000,
      "droitDouane": 1500000,
      "tva": 1000000
    },
    {
      "numArt": 2,
      "codeSh": "8708999000",
      "designationCom": "Pièces détachées automobiles",
      "valeurCaf": 2500000,
      "liquidation": 250000,
      "droitDouane": 150000,
      "tva": 100000
    }
  ]
}
```

**Traitement dans le Kit** :
1. ✅ Réception déclaration + confirmation paiement Mali
2. ✅ Validation montant payé vs liquidation
3. ✅ Vérification référence paiement unique
4. ✅ Stockage dans Supabase table `declarations_recues`
5. ✅ Génération autorisation mainlevée
6. ✅ Transformation vers format Sénégal
7. ✅ Transmission vers Sénégal (Étape 17)
8. ✅ Notification Commission UEMOA (Étape 21)

---

#### **PHASE 4 : Mainlevée au pays de prime abord (Étapes 17-19)**

```
        │                                      │                           │
        │  ÉTAPE 17 : Autorisation             │                           │
        │◀──POST /mainlevee/autorisation───────│                           │
        │  RÉCEPTION AUTORISATION              │                           │
        │  ─────────────────────              │                           │
        │  • Validation autorisation Kit       │                           │
        │  • Vérification paiement Mali        │                           │
        │  • Déblocage manifeste               │                           │
        │                                      │                           │
        │  ÉTAPE 18 : Mainlevée                │                           │
        │  ─────────────────────────           │                           │
        │  Apurement manifeste +               │                           │
        │  génération bon à enlever            │                           │
        │                                      │                           │
        │  ÉTAPE 19 : Enlèvement               │                           │
        │  ─────────────────────────           │                           │
        │  Sortie marchandise du               │                           │
        │  Port de Dakar                       │                           │
        │                                      │                           │
```

**Détails Étape 17** :

Le Kit transforme la déclaration Mali en autorisation pour Sénégal :

```json
{
  "autorisationMainlevee": {
    "format": "UEMOA",
    "numeroManifeste": "5016",
    "referenceDeclaration": "DEC-MLI-2025-001",
    "montantAcquitte": 2750000,
    "monnaie": "FCFA",
    "paysDeclarant": "MLI",
    "referencePaiement": "PAY-MLI-2025-001",
    "datePaiement": "2025-01-18T14:30:00Z",
    "dateAutorisation": "2025-01-18T15:00:00Z",
    "referenceAutorisation": "AUTH-KIT-MLI-SEN-DEC001-20250118150000",
    "statut": "AUTORISE_MAINLEVEE",
    "etape_workflow": 17,
    "typeAutorisation": "MAINLEVEE_INTER_PAYS_UEMOA"
  }
}
```

**Processus Sénégal (Étapes 18-19)** :
- **Étape 18** : Douanes Dakar reçoivent autorisation → Apurement manifeste → Génération bon à enlever
- **Étape 19** : Transporteur présente bon → Sortie physique marchandise du port

---

#### **PHASE 5 : Traçabilité Commission UEMOA (Étapes 20-21)**

```
        │                                      │                           │
        │                                      │  ÉTAPE 20 : Notification   │
        │                                      │  ──────────────────────────┤
        │                                      │──POST /tracabilite/manifeste
        │                                      │  Vers Commission UEMOA    │
        │                                      │  (Transmission manifeste) │
        │                                      │                           │
        │                                      │  ÉTAPE 21 : Notification   │
        │                                      │  ──────────────────────────┤
        │                                      │──POST /tracabilite/declaration
        │                                      │  Vers Commission UEMOA    │
        │                                      │  (Finalisation workflow)  │
        │                                      │                           │
```

**Notifications Commission** :

**Étape 20** : Notification transmission manifeste
```json
{
  "typeOperation": "TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE",
  "numeroOperation": "5016-2025-20250115103000",
  "format": "UEMOA",
  "paysOrigine": "SEN",
  "paysDestination": "MLI",
  "donneesMetier": {
    "numero_manifeste": 5016,
    "nombre_articles": 2,
    "poids_total": 2000,
    "valeur_approximative": 17500000,
    "navire": "MARCO POLO",
    "port_origine": "Port de Dakar"
  },
  "horodatage": "2025-01-15T10:30:00Z"
}
```

**Étape 21** : Notification finalisation workflow
```json
{
  "typeOperation": "COMPLETION_LIBRE_PRATIQUE",
  "numeroOperation": "DEC-MLI-2025-001-FINAL",
  "paysOrigine": "SEN",
  "paysDestination": "MLI",
  "donneesMetier": {
    "numero_declaration": "DEC-MLI-2025-001",
    "manifeste_origine": "5016",
    "montant_paye": 2750000,
    "etapes_completees": "1-21",
    "workflow_type": "LIBRE_PRATIQUE",
    "statut_final": "TERMINE_SUCCES"
  },
  "horodatage": "2025-01-18T15:00:00Z"
}
```

---

### Workflow Transit (16 étapes)

Le workflow de transit permet le suivi des marchandises en transit d'un pays côtier vers un pays de l'hinterland.

#### **PHASE 1 : Création transit au départ (Étapes 1-6)**

```
Sénégal (Port de Dakar)                 Kit MuleSoft                Mali (Bamako)
        │                                      │                           │
        │  ÉTAPE 1 : Documents                 │                           │
        │  ─────────────────────────           │                           │
        │  Collecte documents                  │                           │
        │  pré-dédouanement GUCE               │                           │
        │                                      │                           │
        │  ÉTAPE 2 : Déclaration               │                           │
        │  ─────────────────────────           │                           │
        │  Établissement déclaration           │                           │
        │  transit par déclarant               │                           │
        │                                      │                           │
        │  ÉTAPE 3 : Validation                │                           │
        │  ─────────────────────────           │                           │
        │  Contrôles et validation             │                           │
        │  itinéraire + délais                 │                           │
        │                                      │                           │
        │  ÉTAPE 4 : Garanties                 │                           │
        │  ─────────────────────────           │                           │
        │  Calcul et dépôt caution             │                           │
        │  ou garantie bancaire                │                           │
        │                                      │                           │
        │  ÉTAPE 5 : Bon à enlever             │                           │
        │  ─────────────────────────           │                           │
        │  Délivrance autorisation             │                           │
        │  départ marchandise                  │                           │
        │                                      │                           │
        │  ÉTAPE 6 : Début opération           │                           │
        │──POST /transit/creation─────────────▶│                           │
        │  Headers:                            │  TRAITEMENT TRANSIT       │
        │  - X-Source-Country: SEN             │  ─────────────────────    │
        │  - X-Workflow-Step: 6                │  • Validation transit     │
        │                                      │  • Stockage Supabase      │
        │                                      │  • Préparation copie Mali │
        │                                      │                           │
```

**Détails techniques Étape 6** :

**Endpoint** : `POST /api/v1/transit/creation`

**Payload exemple** :
```json
{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "paysDepart": "SEN",
  "paysDestination": "MLI",
  "bureauDepart": "18N_DAKAR",
  "dateCreation": "2025-01-20T09:00:00Z",
  "transporteur": "TRANSPORT SAHEL SARL",
  "modeTransport": "ROUTIER",
  "vehicule": {
    "immatriculation": "DK-1234-AB",
    "chauffeur": "Mamadou DIALLO",
    "permis": "SEN-2024-12345"
  },
  "itineraire": "Dakar → Tambacounda → Kayes → Bamako",
  "delaiRoute": "72 heures",
  "dateArriveePrevu": "2025-01-23T09:00:00Z",
  "cautionRequise": 5000000,
  "referenceCaution": "CAU-SEN-2025-001",
  "marchandises": [
    {
      "designation": "Produits manufacturés",
      "codeSh": "8544429000",
      "poids": 5000,
      "nombreColis": 100,
      "valeurCaf": 25000000,
      "conteneurs": ["MSCU1234567", "TCLU7654321"]
    }
  ]
}
```

**Traitement dans le Kit** :
1. ✅ Validation déclaration transit Sénégal
2. ✅ Vérification itinéraire autorisé
3. ✅ Contrôle délai route raisonnable (< 7 jours)
4. ✅ Vérification caution déposée
5. ✅ Stockage dans Supabase table `declarations_transit`
6. ✅ Préparation copie pour Mali (Étapes 10-11)

---

#### **PHASE 2 : Transmission et acheminement (Étapes 7-12)**

```
        │                                      │                           │
        │  ÉTAPE 7 : Départ                    │                           │
        │  ─────────────────────────           │                           │
        │  Début transport physique            │                           │
        │  marchandises                        │                           │
        │                                      │                           │
        │  ÉTAPE 8 : Suivi                     │                           │
        │  ─────────────────────────           │                           │
        │  Suivi itinéraire                    │                           │
        │  (géolocalisation optionnelle)       │                           │
        │                                      │                           │
        │  ÉTAPE 9 : Contrôles passage         │                           │
        │  ─────────────────────────           │                           │
        │  Bureaux de passage                  │                           │
        │  (facultatif libre pratique)         │                           │
        │                                      │                           │
        │                                      │  ÉTAPE 10 : Transmission   │
        │                                      │  ──────────────────────────┤
        │                                      │  Envoi copie déclaration  │
        │                                      │  vers Mali                │
        │                                      │                           │
        │                                      │──POST /transit/copie──────▶
        │                                      │                           │
        │                                      │  ÉTAPE 11 : Réception      │
        │                                      │  ◀────────────────────────┤
        │                                      │  Enregistrement transit   │
        │                                      │  dans système malien      │
        │                                      │                           │
        │                                      │  ÉTAPE 12 : Préparation    │
        │                                      │  ──────────────────────────┤
        │                                      │  Attente arrivée          │
        │                                      │  marchandise              │
        │                                      │                           │
```

**Traitement Étapes 10-11** :

Le Kit transmet une copie de la déclaration transit vers Mali :

```json
{
  "transit_original": {
    "numero_declaration": "TRA-SEN-2025-001",
    "pays_depart": "SEN",
    "bureau_depart": "18N_DAKAR",
    "transporteur": "TRANSPORT SAHEL SARL",
    "itineraire": "Dakar → Tambacounda → Kayes → Bamako",
    "delai_route": "72 heures",
    "date_arrivee_prevu": "2025-01-23T09:00:00Z"
  },
  "marchandises": [...],
  "instructions_mali": {
    "attendre_arrivee": true,
    "delai_maximum": "72 heures",
    "message_arrivee_requis": true
  }
}
```

---

#### **PHASE 3 : Arrivée et apurement (Étapes 13-16)**

```
        │                                      │                           │
        │                                      │  ÉTAPE 13 : Arrivée        │
        │                                      │  ──────────────────────────┤
        │                                      │  Arrivée bureau destination│
        │                                      │  Bamako (contrôles)       │
        │                                      │                           │
        │                                      │  ÉTAPE 14 : Message arrivée│
        │                                      │◀──POST /transit/arrivee────┤
        │  TRAITEMENT ARRIVÉE                  │  Headers:                 │
        │  ─────────────────────              │  - X-Source-Country: MLI  │
        │  • Validation contrôles Mali         │                           │
        │  • Vérification délai respecté       │                           │
        │  • Stockage message arrivée          │                           │
        │  • Préparation confirmation Sénégal  │                           │
        │                                      │                           │
        │                                      │  ÉTAPE 15 : Dépôt déclaration│
        │                                      │  ──────────────────────────┤
        │                                      │  Déclaration détaillée    │
        │                                      │  (optionnel)              │
        │                                      │                           │
        │  ÉTAPE 16 : Confirmation             │                           │
        │◀──POST /transit/arrivee──────────────│                           │
        │  APUREMENT TRANSIT                   │                           │
        │  ─────────────────────              │                           │
        │  • Réception confirmation Kit        │                           │
        │  • Apurement transit                 │                           │
        │  • Libération garanties              │                           │
        │  • Clôture opération                 │                           │
        │                                      │                           │
```

**Détails techniques Étape 14** :

**Endpoint** : `POST /api/v1/transit/arrivee`

**Payload exemple** :
```json
{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "bureauArrivee": "10S_BAMAKO",
  "dateArrivee": "2025-01-22T16:30:00Z",
  "controleEffectue": true,
  "visaAppose": true,
  "conformiteItineraire": true,
  "delaiRespecte": true,
  "observations": "Transit effectué sans incident",
  "declarationDetailDeposee": false,
  "agent": {
    "nom": "TRAORE Moussa",
    "matricule": "MLI-2024-789"
  }
}
```

**Traitement dans le Kit** :
1. ✅ Réception message arrivée Mali
2. ✅ Validation contrôles effectués
3. ✅ Vérification délai route respecté
4. ✅ Stockage dans Supabase table `messages_arrivee`
5. ✅ Génération confirmation pour Sénégal
6. ✅ Transmission vers Sénégal (Étape 16)
7. ✅ Libération garanties automatique

---

## Services et endpoints

### Service Health Check

**Endpoint** : `GET /api/v1/health`

**Description** : Vérification complète de l'état du Kit et de la connectivité avec les systèmes externes.

**Contrôles effectués** :
1. ✅ Connectivité Sénégal (Port de Dakar)
2. ✅ Connectivité Mali (Bamako)
3. ✅ Connectivité Commission UEMOA
4. ✅ Connectivité base Supabase
5. ✅ État composants internes MuleSoft

**Réponse exemple** :
```json
{
  "service": "Kit d'Interconnexion UEMOA",
  "status": "UP",
  "version": "1.0.0-UEMOA",
  "format_support": "UEMOA_2025.1",
  "timestamp": "2025-01-20T10:00:00Z",
  "workflows": {
    "libre_pratique": {
      "enabled": true,
      "etapes": "21 étapes",
      "description": "Sénégal (1-5, 17-19) ↔ Mali (6-16) ↔ Commission (20-21)"
    },
    "transit": {
      "enabled": true,
      "etapes": "16 étapes",
      "description": "Sénégal (1-6, 17-18) ↔ Mali (13-14) ↔ Kit (10-11, 16)"
    }
  },
  "systemes_externes": {
    "senegal": {
      "nom": "Sénégal - Port de Dakar",
      "role": "Pays de prime abord",
      "status": "UP",
      "url": "https://simulateur-pays-a-cotier.vercel.app",
      "endpoints_actifs": [
        "/api/health",
        "/api/mainlevee/autorisation"
      ]
    },
    "mali": {
      "nom": "Mali - Bamako",
      "role": "Pays de destination",
      "status": "UP",
      "url": "https://simulateur-pays-b-hinterland.vercel.app",
      "endpoints_actifs": [
        "/api/health",
        "/api/manifeste/reception"
      ]
    },
    "commission": {
      "nom": "Commission UEMOA",
      "status": "UP",
      "url": "https://simulateur-commission-uemoa.vercel.app",
      "endpoints_actifs": [
        "/api/health",
        "/api/tracabilite/manifeste",
        "/api/tracabilite/declaration"
      ]
    },
    "supabase": {
      "nom": "Base de données Kit",
      "status": "UP",
      "host": "hgkuqkjvgshfrayjelps.supabase.co"
    }
  },
  "configuration": {
    "timeout_connection": "15000ms",
    "retry_attempts": "3",
    "cors_enabled": "true"
  }
}
```

---

### Service Manifeste (Libre Pratique)

#### Endpoint : `POST /api/v1/manifeste/transmission`

**Rôle** : Réception de l'extraction du manifeste depuis le Sénégal et routage vers le Mali.

**Workflow** : Étapes 4-5 du workflow Libre Pratique

**Headers** :
```http
Content-Type: application/json
X-Source-Country: SEN
X-Source-System: SENEGAL_DOUANES_DAKAR
X-Correlation-ID: [UUID unique]
X-Manifeste-Format: UEMOA
```

**Codes de retour** :
- `200 OK` : Manifeste transmis avec succès vers Mali
- `400 Bad Request` : Format manifeste invalide
- `500 Internal Server Error` : Erreur traitement Kit
- `503 Service Unavailable` : Mali injoignable

**Exemple d'appel** :
```bash
curl -X POST http://localhost:8080/api/v1/manifeste/transmission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -H "X-Source-System: SENEGAL_DOUANES_DAKAR" \
  -H "X-Correlation-ID: SEN_20250120_5016" \
  -d @manifeste_example.json
```

---

### Service Déclaration (Libre Pratique)

#### Endpoint : `POST /api/v1/declaration/soumission`

**Rôle** : Réception déclaration et paiement depuis Mali, génération autorisation vers Sénégal.

**Workflow** : Étapes 14-16 du workflow Libre Pratique

**Headers** :
```http
Content-Type: application/json
X-Source-Country: MLI
X-Source-System: MALI_DOUANES_BAMAKO
X-Correlation-ID: [UUID unique]
```

**Validations effectuées** :
1. ✅ Référence manifeste origine existe
2. ✅ Montant payé > 0
3. ✅ Référence paiement unique
4. ✅ Date paiement < date actuelle + 1 jour
5. ✅ Articles déclaration correspondent au manifeste

**Codes de retour** :
- `200 OK` : Déclaration traitée, autorisation transmise vers Sénégal
- `400 Bad Request` : Validation échouée
- `404 Not Found` : Manifeste origine introuvable
- `500 Internal Server Error` : Erreur traitement Kit

---

### Service Transit

#### Endpoint : `POST /api/v1/transit/creation`

**Rôle** : Création déclaration transit depuis Sénégal avec transmission copie vers Mali.

**Workflow** : Étapes 1-6 du workflow Transit

**Validations** :
1. ✅ Itinéraire autorisé dans UEMOA
2. ✅ Délai route < 7 jours
3. ✅ Caution déposée et référence valide
4. ✅ Mode transport valide (ROUTIER, FERROVIAIRE)
5. ✅ Marchandises avec code SH valide

---

#### Endpoint : `POST /api/v1/transit/arrivee`

**Rôle** : Réception message arrivée depuis Mali avec confirmation retour vers Sénégal.

**Workflow** : Étape 14 du workflow Transit

**Validations** :
1. ✅ Transit existe dans base Kit
2. ✅ Contrôles effectués par Mali
3. ✅ Délai route respecté
4. ✅ Itinéraire conforme

**Traitement automatique** :
- ✅ Génération confirmation apurement
- ✅ Transmission vers Sénégal (Étape 16)
- ✅ Libération garanties/cautions
- ✅ Clôture opération transit

---

### Service Commission UEMOA

#### Endpoint : `POST /api/v1/tracabilite/enregistrer`

**Rôle** : Enregistrement traçabilité centralisée pour supervision Commission UEMOA.

**Workflow** : Étapes 20-21 (Libre Pratique) + notifications Transit

**Types d'opération** :
```javascript
// Libre Pratique
"TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE"  // Étape 20
"COMPLETION_LIBRE_PRATIQUE"              // Étape 21

// Transit
"CREATION_TRANSIT"                       // Étape 6
"COMPLETION_TRANSIT"                     // Étape 16
```

**Traitement** :
- ✅ Mode asynchrone (ne bloque pas workflows principaux)
- ✅ Normalisation codes pays UEMOA (SEN, MLI, BFA, NER, CIV, TGO, BEN, GNB)
- ✅ Agrégation statistiques pour analyses Commission
- ✅ Retry automatique si Commission temporairement indisponible

---

## Installation et configuration

### Prérequis

**Logiciels requis** :
- ✅ **Java 17+** : `java -version` doit afficher Java 17 ou supérieur
- ✅ **Maven 3.6+** : `mvn -version`
- ✅ **MuleSoft Anypoint Studio** (optionnel mais recommandé)
- ✅ **Git** : Pour cloner le repository
- ✅ **Accès Supabase** : Credentials production requis

### Étape 1 : Clonage du repository

```bash
git clone https://github.com/uemoa/kit-interconnexion-uemoa.git
cd kitinterconnexionuemoa
```

### Étape 2 : Configuration environnement

Le fichier `src/main/resources/configs/dev.yaml` contient toute la configuration :

```yaml
# Configuration HTTP
http:
  port: "8081"  # Modifier si port 8080 occupé
  host: "0.0.0.0"

# Configuration Systèmes Externes
systeme:
  paysA:  # Sénégal
    host: "localhost"
    port: "3001"
    url: "https://simulateur-pays-a-cotier.vercel.app"
    endpoints:
      health: "/api/health"
      mainlevee: "/api/mainlevee/autorisation"

  paysB:  # Mali
    host: "localhost"
    port: "3002"
    url: "https://simulateur-pays-b-hinterland.vercel.app"
    endpoints:
      health: "/api/health"
      manifeste: "/api/manifeste/reception"

# Configuration Commission UEMOA
commission:
  uemoa:
    host: "localhost"
    port: "3003"
    url: "https://simulateur-commission-uemoa.vercel.app"
    endpoints:
      health: "/api/health"
      manifeste: "/api/tracabilite/manifeste"
      declaration: "/api/tracabilite/declaration"
    auth:
      token: "VOTRE_TOKEN_COMMISSION"  # ⚠️ À modifier

# Configuration Supabase (PRODUCTION)
supabase:
  url: "https://hgkuqkjvgshfrayjelps.supabase.co"
  host: "hgkuqkjvgshfrayjelps.supabase.co"
  port: "443"
  anon_key: "VOTRE_ANON_KEY"  # ⚠️ À modifier
  service_role_key: "VOTRE_SERVICE_ROLE_KEY"  # ⚠️ À modifier
```

**⚠️ Configuration Supabase obligatoire** :
1. Créer compte sur [supabase.com](https://supabase.com)
2. Créer nouveau projet
3. Récupérer `anon_key` et `service_role_key` dans Project Settings > API
4. Exécuter script SQL `src/main/resources/db/init-interconnexion.sql`

### Étape 3 : Build du projet

```bash
# Clean + compilation
mvn clean install

# Skip tests (développement rapide)
mvn clean install -DskipTests

# Vérification dépendances
mvn dependency:tree
```

### Étape 4 : Démarrage

#### Option A : Via Maven (ligne de commande)

```bash
mvn mule:run
```

**Logs de démarrage** :
```
[INFO] Mule Runtime: 4.9.2
[INFO] Démarrage application: kit-interconnexion-uemoa
[INFO] Listening on http://0.0.0.0:8080
[INFO] Console API disponible: http://localhost:8080/console
```

#### Option B : Via Anypoint Studio (GUI)

1. **Import projet** : File → Import → Anypoint Studio → Mule Project from File System
2. **Sélectionner** dossier `kitinterconnexionuemoa`
3. **Run** : Clic droit sur projet → Run As → Mule Application
4. **Console** : Voir logs dans vue Console

### Étape 5 : Vérification démarrage

```bash
# Test health check
curl http://localhost:8080/api/v1/health

# Test console API
open http://localhost:8080/console
```

**Réponse attendue health check** :
```json
{
  "service": "Kit d'Interconnexion UEMOA",
  "status": "UP",
  "version": "1.0.0-UEMOA"
}
```

---

## Utilisation de l'API

### Console API interactive

Une console Anypoint est disponible pour tester l'API interactivement :

**URL** : `http://localhost:8080/console`

La console permet :
- ✅ Visualiser tous les endpoints disponibles
- ✅ Consulter la documentation RAML
- ✅ Tester les endpoints avec exemples pré-remplis
- ✅ Voir les codes de retour et formats de réponse

### Test workflow libre pratique complet

#### Étape 1 : Transmission manifeste (Sénégal → Kit → Mali)

```bash
curl -X POST http://localhost:8080/api/v1/manifeste/transmission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -H "X-Source-System: SENEGAL_DOUANES_DAKAR" \
  -H "X-Correlation-ID: TEST_20250120_001" \
  -d '{
    "annee_manif": "2025",
    "bureau_manif": "18N",
    "numero_manif": 6001,
    "consignataire": "TEST SHIPPING",
    "navire": "TEST VESSEL",
    "provenance": "ROTTERDAM",
    "date_arrivee": "2025-01-20",
    "paysOrigine": "SENEGAL",
    "portDebarquement": "Port de Dakar",
    "etapeWorkflow": 5,
    "nbre_article": 1,
    "articles": [
      {
        "art": 1,
        "pays_dest": "MALI",
        "ville_dest": "BAMAKO",
        "marchandise": "Marchandise de test",
        "poids": 1000,
        "destinataire": "TEST IMPORT MALI",
        "connaissement": "TEST123456"
      }
    ]
  }'
```

**Réponse attendue** :
```json
{
  "status": "SUCCESS",
  "message": "Extraction manifeste transmise vers Mali avec succès",
  "numero_manif": 6001,
  "paysOrigine": "SENEGAL",
  "paysDestination": "MALI",
  "articles_transmis": 1,
  "etapeWorkflow": 5,
  "kitProcessing": {
    "correlationId": "TEST_20250120_001",
    "routageVers": "Mali Bamako",
    "formatTransmis": "UEMOA"
  }
}
```

#### Étape 2 : Soumission déclaration (Mali → Kit → Sénégal)

```bash
curl -X POST http://localhost:8080/api/v1/declaration/soumission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -H "X-Source-System: MALI_DOUANES_BAMAKO" \
  -H "X-Correlation-ID: TEST_MLI_20250120_001" \
  -d '{
    "numeroDeclaration": "DEC-TEST-MLI-001",
    "manifesteOrigine": "6001",
    "anneeDecl": "2025",
    "bureauDecl": "10S_BAMAKO",
    "dateDecl": "2025-01-20",
    "montantPaye": 500000,
    "referencePaiement": "PAY-TEST-001",
    "datePaiement": "2025-01-20T14:00:00Z",
    "paysDeclarant": "MLI",
    "articles": [
      {
        "numArt": 1,
        "codeSh": "8703210000",
        "designationCom": "Marchandise de test",
        "valeurCaf": 10000000,
        "liquidation": 500000
      }
    ]
  }'
```

### Test workflow transit

#### Création transit

```bash
curl -X POST http://localhost:8080/api/v1/transit/creation \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -H "X-Workflow-Step: 6_TRANSIT_CREATION" \
  -d '{
    "numeroDeclaration": "TRA-TEST-001",
    "paysDepart": "SEN",
    "paysDestination": "MLI",
    "transporteur": "TEST TRANSPORT",
    "modeTransport": "ROUTIER",
    "itineraire": "Dakar-Bamako",
    "delaiRoute": "72 heures",
    "cautionRequise": 1000000,
    "referenceCaution": "CAU-TEST-001",
    "marchandises": [
      {
        "designation": "Marchandises test",
        "poids": 2000,
        "nombreColis": 50
      }
    ]
  }'
```

#### Message arrivée transit

```bash
curl -X POST http://localhost:8080/api/v1/transit/arrivee \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -d '{
    "numeroDeclaration": "TRA-TEST-001",
    "bureauArrivee": "10S_BAMAKO",
    "dateArrivee": "2025-01-23T10:00:00Z",
    "controleEffectue": true,
    "visaAppose": true,
    "conformiteItineraire": true,
    "delaiRespecte": true
  }'
```

---

## Base de données

### Configuration Supabase (Production)

Le Kit utilise PostgreSQL hébergé sur Supabase pour le stockage persistant.

#### Tables principales

| Table | Description | Clés |
|-------|-------------|------|
| `manifestes_recus` | Manifestes transmis depuis pays côtiers | PK: id, UK: numero_manifeste |
| `declarations_recues` | Déclarations depuis pays hinterland | PK: id, FK: manifeste_origine |
| `declarations_transit` | Déclarations de transit | PK: id, UK: numero_declaration |
| `paiements_recus` | Notifications paiement | PK: id, UK: reference_paiement |
| `autorisations_mainlevee` | Autorisations pour pays côtiers | PK: id, UK: reference_autorisation |
| `messages_arrivee` | Messages arrivée transit | PK: id, FK: numero_declaration |
| `tracabilite_echanges` | Audit complet échanges | PK: id, INDEX: type_operation, statut |
| `configurations_pays` | Configuration pays membres | PK: id, UK: code_pays |
| `metriques_operations` | Métriques performance | PK: (date, heure, type, pays) |

#### Script d'initialisation

Le fichier `src/main/resources/db/init-interconnexion.sql` contient le DDL complet :

```sql
-- Table des manifestes
CREATE TABLE IF NOT EXISTS manifestes_recus (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    numero_manifeste VARCHAR(50) UNIQUE NOT NULL,
    transporteur VARCHAR(100) NOT NULL,
    pays_origine VARCHAR(3),
    pays_destination VARCHAR(3),
    data_json CLOB,
    date_reception TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    statut VARCHAR(20) DEFAULT 'RECU',
    INDEX idx_manifeste_numero (numero_manifeste),
    INDEX idx_manifeste_date (date_reception)
);

-- Autres tables...
```

**⚠️ À exécuter dans Supabase SQL Editor**

#### Connexion Supabase depuis le Kit

Configuration dans `global.xml` :

```xml
<http:request-config name="supabaseRestConfig" doc:name="Supabase REST API Config">
    <http:request-connection 
        host="${supabase.host}" 
        protocol="HTTPS" 
        port="${supabase.port}">
        <tls:context>
            <tls:trust-store insecure="true" />
        </tls:context>
    </http:request-connection>
    <http:default-headers>
        <http:default-header key="apikey" value="${supabase.anon_key}" />
        <http:default-header key="Authorization" value="Bearer ${supabase.anon_key}" />
        <http:default-header key="Content-Type" value="application/json" />
    </http:default-headers>
</http:request-config>
```

### Base H2 (Développement)

Pour le développement local, H2 en mémoire est utilisé :

```yaml
# dev.yaml
db:
  driver: "org.h2.Driver"
  url_interco: "jdbc:h2:mem:interconnexion;DB_CLOSE_DELAY=-1"
  user: "sa"
  password: ""
```

**Avantages H2** :
- ✅ Pas d'installation requise
- ✅ Rechargement automatique au redémarrage
- ✅ Idéal pour tests unitaires
- ✅ Console web H2 disponible

---

## Monitoring et observabilité

### Configuration logging

Le fichier `log4j2.xml` configure les logs :

```xml
<Configuration>
    <Appenders>
        <RollingFile name="file" 
                     fileName="${sys:mule.home}/logs/kitinterconnexionuemoa.log"
                     filePattern="${sys:mule.home}/logs/kitinterconnexionuemoa-%i.log">
            <PatternLayout pattern="%-5p %d [%t] [processor: %X{processorPath}; event: %X{correlationId}] %c: %m%n"/>
            <SizeBasedTriggeringPolicy size="10 MB"/>
            <DefaultRolloverStrategy max="10"/>
        </RollingFile>
    </Appenders>

    <Loggers>
        <AsyncLogger name="org.mule.runtime.core.internal.processor.LoggerMessageProcessor" level="INFO"/>
        <AsyncRoot level="INFO">
            <AppenderRef ref="file"/>
        </AsyncRoot>
    </Loggers>
</Configuration>
```

**Niveaux de log** :
- `INFO` : Opérations normales, étapes workflows
- `WARN` : Situations anormales non critiques
- `ERROR` : Erreurs traitement, échecs communications
- `DEBUG` : Détails transformations DataWeave (désactivé par défaut)

### Logs métier importants

Le Kit génère des logs structurés pour chaque opération :

```
INFO  [Kit] ÉTAPES 4-5: Réception manifeste depuis Sénégal: 6001
INFO  [Kit] Manifeste stocké dans Supabase: 6001
INFO  [Kit] ÉTAPE 5: Routage manifeste vers Mali (Bamako): 6001
INFO  [Kit] ÉTAPE 5 TERMINÉE: Manifeste transmis vers Mali (Bamako)
INFO  [Kit] Commission UEMOA notifiée - Manifeste
```

### Métriques automatiques

La table `metriques_operations` enregistre automatiquement :

```sql
INSERT INTO metriques_operations (
    date_mesure,
    heure_mesure,
    type_operation,
    pays_source,
    pays_destination,
    nombre_operations,
    temps_reponse_moyen,
    nombre_erreurs
) VALUES (
    CURRENT_DATE,
    EXTRACT(HOUR FROM CURRENT_TIMESTAMP),
    'TRANSMISSION_MANIFESTE',
    'SEN',
    'MLI',
    1,
    1250.5,  -- ms
    0
);
```

**Métriques disponibles** :
- ✅ Nombre d'opérations par type/pays/heure
- ✅ Temps de réponse moyen en millisecondes
- ✅ Taux d'erreur par endpoint
- ✅ Volume de données échangées (KB)

### Traçabilité complète

Toutes les opérations sont tracées dans `tracabilite_echanges` :

```sql
INSERT INTO tracabilite_echanges (
    type_operation,
    pays_source,
    pays_destination,
    reference_operation,
    payload_entrant,
    payload_sortant,
    statut_traitement,
    duree_traitement_ms
) VALUES (
    'TRANSMISSION_MANIFESTE',
    'SEN',
    'MLI',
    '6001',
    '{"annee_manif":"2025",...}',
    '{"status":"SUCCESS",...}',
    'SUCCESS',
    1345
);
```

### Dashboard de monitoring recommandé

**Grafana** + **Prometheus** peuvent être configurés pour :
- ✅ Visualiser métriques en temps réel
- ✅ Alertes sur taux d'erreur > seuil
- ✅ Graphes temps de réponse par endpoint
- ✅ Heatmaps d'activité par pays/heure

---

## Déploiement

### Déploiement Standalone

Le plus simple pour environnements de production :

```bash
# Build package déployable
mvn clean package

# Copier vers répertoire Mule Runtime
cp target/kit-interconnexion-uemoa-1.0.0-UEMOA-mule-application.jar \
   $MULE_HOME/apps/

# Démarrer Mule Runtime
$MULE_HOME/bin/mule start

# Vérifier déploiement
tail -f $MULE_HOME/logs/mule_ee.log
```

### Déploiement CloudHub (Anypoint Platform)

Pour bénéficier du cloud managé MuleSoft :

```bash
mvn clean package deploy -DmuleDeploy \
  -Dmule.application.name=kit-interconnexion-uemoa \
  -Danypoint.platform.client_id=$CLIENT_ID \
  -Danypoint.platform.client_secret=$CLIENT_SECRET \
  -Danypoint.platform.environment=Production \
  -Danypoint.platform.workers=2 \
  -Danypoint.platform.workerType=MICRO
```

**Avantages CloudHub** :
- ✅ Scaling automatique
- ✅ Haute disponibilité (99.99% SLA)
- ✅ Monitoring intégré
- ✅ Logs centralisés
- ✅ Déploiement zero-downtime

### Configuration production

Ajuster dans `dev.yaml` pour production :

```yaml
# URLs réelles systèmes douaniers
systeme:
  paysA:
    url: "https://douanes.senegal.sn/api"
  paysB:
    url: "https://douanes.mali.ml/api"

commission:
  uemoa:
    url: "https://interconnexion.uemoa.int/api"
    auth:
      token: "${secure::commission.token}"  # Vault

# Timeouts production (plus élevés)
external:
  timeout:
    connection: "30000"  # 30 secondes
    read: "60000"        # 60 secondes

# Retry plus agressif
retry:
  attempts: "5"
  delay: "5000"  # 5 secondes
```

### Sécurisation production

**1. Certificats SSL/TLS**
```yaml
tls:
  context:
    trust_store:
      path: "truststore.jks"
      password: "${secure::truststore.password}"
      type: "JKS"
    key_store:
      path: "keystore.jks"
      password: "${secure::keystore.password}"
      type: "JKS"
```

**2. Credentials sécurisés**
Utiliser MuleSoft Secure Properties :

```bash
# Chiffrer propriétés sensibles
mvn com.mulesoft.mule.maven:mule-maven-plugin:encrypt \
  -Dpassword=masterPassword \
  -Dvalue=tokenCommission
```

**3. Authentification API**
Ajouter API Gateway policies :
- ✅ Rate limiting (1000 req/min)
- ✅ IP whitelist (pays UEMOA uniquement)
- ✅ OAuth 2.0 client credentials
- ✅ JWT validation

---

## Dépannage

### Problème : Kit ne démarre pas

**Symptôme** :
```
ERROR Failed to deploy application: kit-interconnexion-uemoa
```

**Solutions** :
1. ✅ Vérifier Java 17 : `java -version`
2. ✅ Vérifier port 8080 libre : `lsof -i :8080` (Mac/Linux) ou `netstat -ano | findstr :8080` (Windows)
3. ✅ Modifier port si occupé dans `dev.yaml` : `http.port: "8081"`
4. ✅ Vérifier logs : `tail -f logs/kitinterconnexionuemoa.log`

---

### Problème : Erreur connexion Supabase

**Symptôme** :
```
ERROR HTTP POST to Supabase failed with 401 Unauthorized
```

**Solutions** :
1. ✅ Vérifier `anon_key` dans `dev.yaml`
2. ✅ Tester connexion directe :
```bash
curl https://hgkuqkjvgshfrayjelps.supabase.co/rest/v1/configurations_pays \
  -H "apikey: VOTRE_ANON_KEY" \
  -H "Authorization: Bearer VOTRE_ANON_KEY"
```
3. ✅ Vérifier tables créées dans Supabase SQL Editor
4. ✅ Vérifier RLS (Row Level Security) désactivé pour tables système

---

### Problème : Manifeste non routé vers Mali

**Symptôme** :
```
ERROR Failed to send manifeste to Mali: Connection timeout
```

**Solutions** :
1. ✅ Vérifier URL Mali dans `dev.yaml` : `systeme.paysB.url`
2. ✅ Tester connectivité Mali :
```bash
curl https://simulateur-pays-b-hinterland.vercel.app/api/health
```
3. ✅ Augmenter timeout dans `dev.yaml` :
```yaml
external:
  timeout:
    connection: "30000"  # 30 secondes
```
4. ✅ Vérifier logs détaillés :
```bash
tail -f logs/kitinterconnexionuemoa.log | grep Mali
```

---

### Problème : Commission UEMOA ne reçoit pas notifications

**Symptôme** :
Workflow fonctionne mais Commission ne reçoit rien

**Solutions** :
1. ✅ Vérifier token Commission dans `dev.yaml`
2. ✅ Les notifications Commission sont **asynchrones** → Le workflow principal n'est pas bloqué même si Commission échoue
3. ✅ Vérifier logs notification :
```bash
tail -f logs/kitinterconnexionuemoa.log | grep Commission
```
4. ✅ Les échecs Commission sont normaux en développement (simulateurs Vercel peuvent être inactifs)

---

### Problème : Erreur format UEMOA invalide

**Symptôme** :
```
400 Bad Request: Format manifeste UEMOA invalide
```

**Solutions** :
1. ✅ Vérifier champs obligatoires :
   - `numero_manif` (integer)
   - `annee_manif` (string)
   - `bureau_manif` (string)
   - `articles` (array avec au moins 1 élément)
   - `articles[].pays_dest` (string contenant "MALI")

2. ✅ Exemple payload minimal valide :
```json
{
  "annee_manif": "2025",
  "bureau_manif": "18N",
  "numero_manif": 6001,
  "consignataire": "TEST",
  "articles": [{
    "art": 1,
    "pays_dest": "MALI",
    "marchandise": "Test",
    "poids": 100
  }]
}
```

3. ✅ Valider JSON avec [jsonlint.com](https://jsonlint.com)

---

### Problème : Performances lentes

**Symptôme** :
Temps de réponse > 5 secondes

**Diagnostics** :
1. ✅ Vérifier métriques dans Supabase :
```sql
SELECT 
  type_operation,
  AVG(duree_traitement_ms) as temps_moyen_ms,
  COUNT(*) as nombre_operations
FROM tracabilite_echanges
WHERE date_debut > CURRENT_DATE - INTERVAL '1 day'
GROUP BY type_operation
ORDER BY temps_moyen_ms DESC;
```

2. ✅ Vérifier connectivité réseaux :
```bash
# Tester latence Sénégal
curl -w "@curl-format.txt" -o /dev/null -s https://simulateur-pays-a-cotier.vercel.app/api/health

# Tester latence Mali
curl -w "@curl-format.txt" -o /dev/null -s https://simulateur-pays-b-hinterland.vercel.app/api/health
```

3. ✅ Activer logs DEBUG temporairement dans `log4j2.xml` :
```xml
<AsyncLogger name="org.mule.runtime.core.internal.processor.LoggerMessageProcessor" level="DEBUG"/>
```

**Solutions** :
- ✅ Augmenter workers CloudHub (si déployé cloud)
- ✅ Ajouter cache Redis pour données référence
- ✅ Optimiser requêtes Supabase (index manquants)
- ✅ Activer compression HTTP

---

## Support et contribution

### Obtenir de l'aide

**Channels officiels** :
- 📧 Email : support-kit@uemoa.int
- 📚 Documentation : https://docs.uemoa.int/kit-interconnexion
- 💬 Forum : https://forum.uemoa.int/interconnexion
- 🐛 Issues GitHub : https://github.com/uemoa/kit-interconnexion/issues

### Contribuer au projet

Le code source du Kit d'Interconnexion est ouvert conformément aux recommandations UEMOA.

**Process de contribution** :
1. ✅ Fork le repository
2. ✅ Créer branche feature : `git checkout -b feature/nouvelle-fonctionnalite`
3. ✅ Commiter changements : `git commit -m "feat: ajouter support Burkina Faso"`
4. ✅ Pousser branche : `git push origin feature/nouvelle-fonctionnalite`
5. ✅ Créer Pull Request

**Guidelines** :
- ✅ Tests unitaires requis
- ✅ Documentation RAML mise à jour
- ✅ README.md mis à jour si nécessaire
- ✅ Commits conventionnels (feat, fix, docs, refactor)

---

## Évolutions et roadmap

### Version actuelle : 1.0.0-UEMOA

**Fonctionnalités** :
- ✅ Workflow Libre Pratique complet (21 étapes)
- ✅ Workflow Transit complet (16 étapes)
- ✅ Intégration Sénégal ↔ Mali opérationnelle
- ✅ Traçabilité Commission UEMOA
- ✅ Base de données Supabase
- ✅ CORS support complet
- ✅ Health check détaillé

---

### Version 1.1.0 (Q2 2025)

**Prévisions** :
- 🚀 Support Burkina Faso (BFA)
- 🚀 Support Niger (NER)
- 🚀 Support Côte d'Ivoire (CIV)
- 🚀 Module géolocalisation marchandises transit
- 🚀 API reporting et statistiques avancées

---

### Version 2.0.0 (Q4 2025)

**Vision** :
- 🚀 Support tous pays UEMOA (TGO, BEN, GNB)
- 🚀 Interface administration web
- 🚀 Support format EDI UEMOA
- 🚀 Intégration systèmes paiement BCEAO
- 🚀 Module blockchain pour traçabilité immuable
- 🚀 IA/ML pour détection fraudes

---

## Conformité et licence

### Conformité UEMOA

Le Kit d'Interconnexion est **100% conforme** aux spécifications UEMOA :

- ✅ **Format UEMOA 2025.1** : Support intégral
- ✅ **Workflow Libre Pratique** : 21 étapes validées
- ✅ **Workflow Transit** : 16 étapes validées
- ✅ **Traçabilité centralisée** : Commission UEMOA intégrée
- ✅ **Architecture décentralisée** : Chaque pays héberge son Kit

### Standards techniques

- ✅ **REST API** : RESTful level 2 (Richardson Maturity Model)
- ✅ **RAML 1.0** : Spécification API complète
- ✅ **JSON** : Format échange données
- ✅ **ISO 8601** : Format dates/timestamps
- ✅ **UTF-8** : Encodage caractères

### Code source ouvert

**Important** : Conformément aux recommandations de l'étude UEMOA, le code source du Kit d'Interconnexion est ouvert aux équipes de mise en œuvre **sans droits de licence** pour assurer :
- ✅ Maintenabilité par équipes nationales
- ✅ Autonomie des projets pays
- ✅ Personnalisation selon besoins locaux
- ✅ Transparence et auditabilité

**Licence** : MIT License

---

## Métadonnées projet

| Attribut | Valeur |
|----------|--------|
| **Nom** | Kit d'Interconnexion UEMOA |
| **Version** | 1.0.0-UEMOA |
| **Runtime** | Mule 4.9.2 |
| **Java** | 17 |
| **Format** | UEMOA 2025.1 |
| **Date release** | Janvier 2025 |
| **Organisation** | UEMOA - Union Économique et Monétaire Ouest Africaine |
| **URL** | https://www.uemoa.int |
| **Repository** | https://github.com/uemoa/kit-interconnexion |
| **Documentation** | https://docs.uemoa.int/kit-interconnexion |

---

## Contact

**Équipe Technique Kit UEMOA**
- 📧 Email : kit-technique@uemoa.int
- 🌐 Site : https://www.uemoa.int
- 📞 Téléphone : +226 25 30 09 00
- 📍 Adresse : 01 BP 543 Ouagadougou 01, Burkina Faso

---

**Architecture** : Sénégal (Pays A) ↔ Kit MuleSoft ↔ Mali (Pays B) ↔ Commission UEMOA

**Workflows supportés** :
- ✅ **Libre Pratique** : 21 étapes complètes
- ✅ **Transit** : 16 étapes complètes
- ✅ **Traçabilité Commission** : Étapes 20-21
- ✅ **Health Check** : Surveillance systèmes externes
- ✅ **CORS** : Support applications web

---

*Documentation mise à jour : Janvier 2025*
*Version Kit : 1.0.0-UEMOA*
*Format supporté : UEMOA 2025.1*
