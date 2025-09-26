# Kit d'Interconnexion UEMOA

## Vue d'ensemble

Le **Kit d'Interconnexion UEMOA** est une solution MuleSoft permettant l'interconnexion des systèmes informatiques douaniers des États membres de l'Union Économique et Monétaire Ouest Africaine (UEMOA) dans le cadre de la mise en œuvre du régime de la libre pratique et du transit.

Cette API facilite les échanges de données entre les pays côtiers (points d'entrée) et les pays de l'hinterland (destinations finales) pour le suivi des marchandises et des procédures douanières.

## Contexte métier et architecture fonctionnelle

### Workflow Libre Pratique (21 étapes)

Le workflow de libre pratique suit le scénario fonctionnel défini par la Commission UEMOA avec les étapes suivantes :

#### Phase 1 : Prise en charge et transmission (Étapes 1-5)
1. **Étape 1** : Prise en charge des marchandises au pays de prime abord (Sénégal - Port de Dakar)
2. **Étape 2** : Enregistrement du manifeste dans le système douanier sénégalais
3. **Étape 3** : Validation et contrôles préliminaires
4. **Étape 4** : Extraction du manifeste (articles destinés au Mali uniquement)
5. **Étape 5** : **[KIT]** Transmission vers Mali (Endpoint: `POST /api/v1/manifeste/transmission`)

#### Phase 2 : Traitement au pays de destination (Étapes 6-13)
6. **Étape 6** : Réception et enregistrement au Mali
7. **Étape 7** : Collecte documents pré-dédouanement (GUCE Mali)
8. **Étape 8** : Établissement déclaration par déclarant malien
9. **Étape 9** : Contrôles de recevabilité
10. **Étape 10** : Calcul du devis (pré-liquidation)
11. **Étape 11** : Enregistrement déclaration détaillée
12. **Étape 12** : Contrôles douaniers (documents/marchandises)
13. **Étape 13** : Émission bulletin de liquidation

#### Phase 3 : Paiement et autorisation (Étapes 14-16)
14. **Étape 14** : Paiement droits et taxes (BCEAO/Trésor Mali)
15. **Étape 15** : Confirmation paiement et génération autorisation
16. **Étape 16** : **[KIT]** Transmission données au Kit (Endpoint: `POST /api/v1/declaration/soumission`)

#### Phase 4 : Mainlevée au pays de prime abord (Étapes 17-19)
17. **Étape 17** : **[KIT]** Transmission autorisation vers Sénégal
18. **Étape 18** : Apurement manifeste et mainlevée
19. **Étape 19** : Enlèvement marchandise (Port de Dakar)

#### Phase 5 : Traçabilité Commission UEMOA (Étapes 20-21)
20. **Étape 20** : **[KIT]** Notification Commission UEMOA (manifeste)
21. **Étape 21** : **[KIT]** Notification Commission UEMOA (finalisation)

### Workflow Transit (16 étapes)

Le workflow de transit suit le scénario technique de la figure 20 du document de référence :

#### Phase 1 : Création transit au départ (Étapes 1-6)
1. **Étape 1** : Collecte documents pré-dédouanement (GUCE Sénégal)
2. **Étape 2** : Établissement déclaration transit
3. **Étape 3** : Contrôles et validation
4. **Étape 4** : Calcul garanties et cautions
5. **Étape 5** : Délivrance bon à enlever
6. **Étape 6** : **[KIT]** Début opération transit (Endpoint: `POST /api/v1/transit/creation`)

#### Phase 2 : Transmission et acheminement (Étapes 7-12)
7. **Étape 7** : Début transport marchandises
8. **Étape 8** : Suivi itinéraire (optionnel : géolocalisation)
9. **Étape 9** : Contrôles bureaux de passage (facultatif libre pratique)
10. **Étape 10** : **[KIT]** Transmission copie déclaration vers Mali
11. **Étape 11** : **[KIT]** Réception et enregistrement au Mali
12. **Étape 12** : Préparation arrivée Mali

#### Phase 3 : Arrivée et apurement (Étapes 13-16)
13. **Étape 13** : Arrivée bureau de destination (Mali)
14. **Étape 14** : **[KIT]** Message arrivée Mali (Endpoint: `POST /api/v1/transit/arrivee`)
15. **Étape 15** : Dépôt déclaration détaillée (optionnel)
16. **Étape 16** : **[KIT]** Confirmation retour et apurement Sénégal

## Architecture technique

### Technologies utilisées

- **MuleSoft Mule Runtime** 4.9.2
- **Java** 17
- **APIKit** 1.11.6 pour la spécification RAML
- **Base de données Supabase** (PostgreSQL) - Production
- **Base de données H2** (en mémoire) - Développement
- **JMS ActiveMQ** 5.16.7 pour le messaging asynchrone
- **Maven** 3.6+ pour la gestion des dépendances

### Architecture décentralisée

La solution suit le modèle d'architecture décentralisé recommandé par l'étude UEMOA, où chaque État membre héberge son propre Kit d'Interconnexion intégré à son SI douanier via une solution d'API Management.

#### Composants du Kit d'Interconnexion

1. **Base de données embarquée** : Tables de correspondance et données de référence
2. **Serveur de fichiers (S)FTP** : Stockage documents accompagnant déclarations
3. **Moteur de batchs** : Procédures automatisées inter-bases
4. **Gestionnaire de files d'attente** : Messages asynchrones entre SI
5. **Ensemble d'APIs** : Calculs, transformations, routage

### Structure du projet

```
kitinterconnexionuemoa/
├── src/main/
│   ├── mule/
│   │   ├── global.xml                    # Configuration globale (BDD, HTTP, JMS)
│   │   ├── interface.xml                 # Endpoints API avec CORS
│   │   └── implementation/
│   │       └── kit-impl.xml              # Logique métier workflows
│   └── resources/
│       ├── api/
│       │   └── kitinterconnexionuemoa.raml  # Spécification API RAML
│       ├── configs/
│       │   └── dev.yaml                  # Configuration environnements
│       ├── db/
│       │   ├── init.sql                  # Scripts base H2 (développement)
│       │   └── init-interconnexion.sql   # Scripts Supabase (production)
│       └── log4j2.xml                    # Configuration logging
├── pom.xml                               # Configuration Maven
└── README.md                             # Documentation projet
```

## Services et endpoints détaillés

### 1. Service Manifeste - Libre Pratique

#### `POST /api/v1/manifeste/transmission` (Étapes 4-5)

**Fonction** : Réception de l'extraction du manifeste depuis le Sénégal et routage vers le Mali.

**Workflow technique** :
1. Réception manifeste UEMOA depuis Port de Dakar
2. Validation format et données obligatoires
3. Stockage dans Supabase pour traçabilité
4. Extraction articles destinés au Mali uniquement
5. Transformation format compatible système malien
6. Transmission vers Mali (Bamako) via HTTP
7. Notification asynchrone Commission UEMOA

**Headers requis** :
- `X-Source-Country: SEN`
- `X-Source-System: SENEGAL_DOUANES_DAKAR`
- `X-Correlation-ID: [UUID]`
- `X-Manifeste-Format: UEMOA`

**Exemple payload** :
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
  "nbre_article": 1,
  "articles": [
    {
      "art": 1,
      "pays_dest": "MALI",
      "ville_dest": "BAMAKO",
      "marchandise": "Véhicule particulier Toyota",
      "poids": 1500,
      "destinataire": "IMPORT SARL BAMAKO",
      "connaissement": "233698813"
    }
  ]
}
```

### 2. Service Déclaration - Libre Pratique

#### `POST /api/v1/declaration/soumission` (Étapes 14-16)

**Fonction** : Réception déclaration et paiement depuis Mali, génération autorisation vers Sénégal.

**Workflow technique** :
1. Réception déclaration détaillée depuis Mali
2. Validation paiement droits et taxes
3. Stockage dans Supabase avec référence manifeste origine
4. Génération autorisation de mainlevée
5. Transformation format compatible système sénégalais
6. Transmission autorisation vers Sénégal (Port de Dakar)
7. Notification Commission UEMOA (finalisation workflow)

**Exemple payload** :
```json
{
  "numeroDeclaration": "DEC-MLI-2025-001",
  "manifesteOrigine": "5016",
  "anneeDecl": "2025",
  "bureauDecl": "10S_BAMAKO",
  "dateDecl": "2025-01-08",
  "montantPaye": 250000,
  "referencePaiement": "PAY-MLI-2025-001",
  "datePaiement": "2025-01-15T14:30:00Z",
  "paysDeclarant": "MLI",
  "articles": [
    {
      "numArt": 1,
      "codeSh": "8703210000",
      "designationCom": "Véhicule Toyota Corolla",
      "valeurCaf": 15000000,
      "liquidation": 2500000
    }
  ]
}
```

### 3. Service Transit

#### `POST /api/v1/transit/creation` (Étapes 1-6)

**Fonction** : Création déclaration transit depuis Sénégal avec transmission copie vers Mali.

**Workflow technique** :
1. Réception déclaration transit depuis Sénégal
2. Validation itinéraire, délais, garanties
3. Stockage dans Supabase
4. Préparation copie pour Mali avec instructions attente
5. Transmission vers Mali (étapes 10-11)
6. Confirmation création successful

#### `POST /api/v1/transit/arrivee` (Étape 14)

**Fonction** : Réception message arrivée depuis Mali avec confirmation retour vers Sénégal.

**Workflow technique** :
1. Réception confirmation arrivée depuis Mali
2. Validation contrôles effectués et délais respectés
3. Stockage message arrivée
4. Préparation données apurement
5. Transmission confirmation vers Sénégal (étape 16)
6. Libération garanties et finalisation transit

### 4. Service Commission UEMOA

#### `POST /api/v1/tracabilite/enregistrer` (Étapes 20-21)

**Fonction** : Enregistrement traçabilité centralisée pour supervision Commission UEMOA.

**Types d'opérations** :
- `TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE` (Étape 20)
- `COMPLETION_LIBRE_PRATIQUE` (Étape 21)
- `CREATION_TRANSIT`
- `COMPLETION_TRANSIT`

**Traitement** :
- Mode asynchrone pour ne pas bloquer workflows principaux
- Normalisation codes pays UEMOA (SEN, MLI, BFA, NER, CIV, TGO, BEN, GNB)
- Agrégation statistiques et métriques
- Stockage centralisé pour analyses Commission

### 5. Service Health Check

#### `GET /api/v1/health`

**Fonction** : Vérification état complet du Kit d'Interconnexion et connectivité systèmes externes.

**Contrôles effectués** :
1. **Connectivité Sénégal** : Test endpoint `/api/health`
2. **Connectivité Mali** : Test endpoint `/api/health`
3. **Connectivité Commission** : Test endpoint `/api/health`
4. **Connectivité Supabase** : Test requête base de données
5. **État interne** : Vérification composants MuleSoft

**Réponse détaillée** :
```json
{
  "service": "Kit d'Interconnexion UEMOA",
  "status": "UP",
  "version": "1.0.0-UEMOA",
  "format_support": "UEMOA_2025.1",
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
      "endpoints_actifs": ["/api/mainlevee/autorisation"]
    },
    "mali": {
      "nom": "Mali - Bamako", 
      "role": "Pays de destination",
      "status": "UP",
      "endpoints_actifs": ["/api/manifeste/reception"]
    },
    "commission": {
      "status": "UP",
      "endpoints_actifs": ["/api/tracabilite/manifeste", "/api/tracabilite/declaration"]
    }
  }
}
```

## Installation et démarrage

### Prérequis

- **Java 17+**
- **Maven 3.6+**
- **MuleSoft Anypoint Studio** (optionnel)
- **Accès Supabase** (production)

### Configuration

1. **Cloner le repository**
```bash
git clone <repository-url>
cd kitinterconnexionuemoa
```

2. **Configuration environnement**

Modifier `src/main/resources/configs/dev.yaml` :

```yaml
# Configuration HTTP
http:
  port: "8080"
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
      tracabilite: "/api/tracabilite/enregistrer"
    auth:
      token: "COMMISSION_TOKEN"

# Configuration Supabase
supabase:
  url: "https://hgkuqkjvgshfrayjelps.supabase.co"
  host: "hgkuqkjvgshfrayjelps.supabase.co"
  port: "443"
  anon_key: "your-anon-key"
  service_role_key: "your-service-role-key"
```

3. **Démarrage**

```bash
# Via Maven
mvn clean install
mvn mule:run

# Via Anypoint Studio
# Importer le projet et Run As > Mule Application
```

L'application sera accessible sur `http://localhost:8080`

## Utilisation de l'API

### Console API interactive

Une console Anypoint est disponible à l'adresse :
`http://localhost:8080/console`

### Exemples d'utilisation

#### 1. Test workflow libre pratique complet

```bash
# Étape 5 : Transmission manifeste depuis Sénégal
curl -X POST http://localhost:8080/api/v1/manifeste/transmission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -H "X-Source-System: SENEGAL_DOUANES_DAKAR" \
  -d @manifeste_exemple.json

# Étape 16 : Soumission déclaration depuis Mali  
curl -X POST http://localhost:8080/api/v1/declaration/soumission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -H "X-Source-System: MALI_DOUANES_BAMAKO" \
  -d @declaration_exemple.json
```

#### 2. Test workflow transit

```bash
# Étape 6 : Création transit
curl -X POST http://localhost:8080/api/v1/transit/creation \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -d @transit_creation.json

# Étape 14 : Message arrivée
curl -X POST http://localhost:8080/api/v1/transit/arrivee \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -d @transit_arrivee.json
```

## Base de données

### Configuration Supabase (Production)

Le système utilise PostgreSQL sur Supabase pour le stockage persistant :

**Tables principales** :
- `manifestes_recus` : Manifestes transmis depuis Sénégal
- `declarations_recues` : Déclarations soumises depuis Mali  
- `declarations_transit` : Déclarations de transit
- `paiements_recus` : Notifications paiement
- `autorisations_mainlevee` : Autorisations pour Sénégal
- `messages_arrivee` : Messages arrivée transit
- `tracabilite_echanges` : Audit complet échanges
- `configurations_pays` : Configuration pays membres
- `metriques_operations` : Métriques performance

### Base H2 (Développement)

Pour le développement local, utilisation H2 en mémoire avec initialisation via `init.sql`.

## Sécurité et authentification

### Authentification par système

- **Basic Auth** : Sénégal/Mali (systèmes externes)
- **Bearer Token** : Commission UEMOA 
- **Token-based** : Supabase

### Headers sécurité recommandés

```http
X-Source-Country: [SEN, MLI]
X-Source-System: [Nom système source]
X-Correlation-ID: [UUID unique]
X-Authorization-Source: KIT_INTERCONNEXION
X-Manifeste-Format: UEMOA
X-Workflow-Step: [Numéro étape]
```

## Monitoring et observabilité

### Configuration logging

Logs configurés via `log4j2.xml` :
- **INFO** : Opérations normales, étapes workflows
- **ERROR** : Erreurs traitement, communications
- **DEBUG** : Détails transformations

### Métriques automatiques

Enregistrement dans `metriques_operations` :
- Nombre opérations par type/pays
- Temps réponse moyens
- Taux d'erreur par endpoint
- Volume données échangées

### Traçabilité complète

Toutes les opérations sont tracées dans `tracabilite_echanges` avec :
- Type opération et pays source/destination
- Payloads entrant/sortant complets
- Statut traitement et codes erreur
- Durées traitement en millisecondes

## CORS et intégration frontend

### Configuration CORS

Support complet CORS pour intégration applications web :

```yaml
cors:
  enabled: "true"
  origins:
    - "*.vercel.app"
    - "localhost"
    - "127.0.0.1"
```

Headers CORS supportés incluent tous les headers spécifiques UEMOA.

## Déploiement

### Standalone
```bash
mvn clean package
mvn mule:run
```

### CloudHub (Anypoint Platform)
```bash
mvn clean package deploy -DmuleDeploy \
  -Dmule.application.name=kit-interconnexion-uemoa
```

### Configuration production

Ajuster dans `dev.yaml` :
- URLs réelles systèmes douaniers
- Tokens authentification production
- Configuration Supabase production
- Timeouts réseaux UEMOA appropriés

## Format UEMOA 2025.1

### Conformité

Le Kit supporte intégralement le format UEMOA 2025.1 :
- Validation structures données
- Transformation automatique entre pays
- Normalisation codes pays (SEN, MLI, BFA, NER, CIV, TGO, BEN, GNB)
- Mapping champs selon spécifications Commission

### Pays supportés

- **SEN** : Sénégal (Port de Dakar) - Pays côtier
- **MLI** : Mali (Bamako) - Pays hinterland  
- **BFA** : Burkina Faso - Support prévu
- **NER** : Niger - Support prévu
- **CIV** : Côte d'Ivoire - Support prévu

## Codes d'erreur

### Statuts HTTP

- **200** : Succès opération
- **400** : Erreur validation format UEMOA
- **401** : Authentification requise/invalide
- **500** : Erreur interne système
- **503** : Service temporairement indisponible

### Gestion erreurs

Gestionnaire global avec :
- Capture exceptions non traitées
- Réponses JSON structurées
- Logging erreurs avec contexte
- Préservation headers CORS

### Retry et résilience

Configuration automatique :
- Communications systèmes externes (3 tentatives)
- Accès base données (2 tentatives)  
- Notifications Commission (mode asynchrone)

## Support et maintenance

### Dépannage courant

**Connectivité Commission UEMOA** :
- Vérifier token dans `dev.yaml`
- Contrôler connectivité réseau  
- Les échecs Commission n'interrompent pas flux principal

**Erreurs validation UEMOA** :
- Vérifier structure JSON contre types RAML
- Contrôler champs obligatoires (numero_manif, pays_dest)
- Valider codes pays normalisés

**Performance lente** :
- Vérifier métriques base données
- Ajuster timeouts `dev.yaml`
- Contrôler état systèmes externes via health check

## Évolutions et roadmap

### Version actuelle : 1.0.0-UEMOA

- Support complet workflows 21 étapes libre pratique
- Support complet workflows 16 étapes transit
- Intégration Sénégal-Mali fonctionnelle  
- Traçabilité Commission UEMOA opérationnelle
- Base données Supabase intégrée

### Prochaines versions

- Support autres pays UEMOA (BFA, NER, CIV, TGO, BEN, GNB)
- Interface administration web
- API reporting et statistiques avancées
- Support format EDI UEMOA
- Intégration systèmes paiement BCEAO
- Module géolocalisation marchandises transit

## Conformité et licence

### Conformité UEMOA

- Format UEMOA 2025.1 intégral
- Workflow libre pratique 21 étapes
- Workflow transit 16 étapes  
- Traçabilité centralisée Commission
- Architecture décentralisée (recommandation étude)

### Code source ouvert

**Important** : Conformément aux recommandations de l'étude UEMOA, le code source du Kit d'Interconnexion est ouvert aux équipes de mise en œuvre sans droits de licence pour assurer maintenabilité et autonomie des équipes projets.

---

**Version** : 1.0.0-UEMOA  
**Runtime** : Mule 4.9.2  
**Java** : 17  
**Format** : UEMOA 2025.1  
**Dernière mise à jour** : Janvier 2025

**Architecture** : Sénégal (Pays A) ↔ Kit MuleSoft ↔ Mali (Pays B) ↔ Commission UEMOA

**Workflows supportés** :
- ✅ Libre Pratique : 21 étapes complètes
- ✅ Transit : 16 étapes complètes  
- ✅ Traçabilité Commission : Étapes 20-21
- ✅ Health Check : Surveillance systèmes externes
- ✅ CORS : Support applications web
