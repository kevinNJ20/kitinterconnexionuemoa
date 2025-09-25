# Kit d'Interconnexion UEMOA

## Vue d'ensemble

Le **Kit d'Interconnexion UEMOA** est une solution MuleSoft permettant l'interconnexion des systèmes informatiques douaniers des États membres de l'Union Économique et Monétaire Ouest Africaine (UEMOA) dans le cadre de la mise en œuvre du régime de la libre pratique et du transit.

Cette API facilite les échanges de données entre les pays côtiers (points d'entrée) et les pays de l'hinterland (destinations finales) pour le suivi des marchandises et des procédures douanières.

## Contexte métier

Dans le cadre de l'UEMOA, lorsqu'une marchandise arrive dans un pays côtier (exemple : Sénégal) mais est destinée à un pays de l'hinterland (exemple : Mali), le système doit :

### Workflow Libre Pratique (21 étapes)
1. **ÉTAPES 4-5** : Réception et transmission du manifeste depuis le Sénégal (Port de Dakar)
2. **ÉTAPES 6-13** : Traitement par le Mali (réception, déclaration en détail)
3. **ÉTAPES 14-16** : Soumission déclaration et paiement par le Mali
4. **ÉTAPE 17** : Transmission autorisation mainlevée vers le Sénégal
5. **ÉTAPES 18-19** : Traitement final au Sénégal
6. **ÉTAPES 20-21** : Notification et traçabilité Commission UEMOA

### Workflow Transit (16 étapes)
1. **ÉTAPES 1-6** : Création déclaration transit au Sénégal
2. **ÉTAPES 10-11** : Transmission copie vers le Mali
3. **ÉTAPES 13-14** : Arrivée et contrôle au Mali
4. **ÉTAPE 16** : Confirmation retour vers le Sénégal
5. **ÉTAPES 17-18** : Apurement final au Sénégal

## Architecture technique

### Technologies utilisées

- **MuleSoft Mule Runtime** 4.9.2
- **Java** 17
- **APIKit** 1.11.6 pour la spécification RAML
- **Base de données Supabase** (PostgreSQL)
- **Base de données H2** (en mémoire pour le développement)
- **JMS ActiveMQ** 5.16.7 pour le messaging asynchrone

### Structure du projet

```
kitinterconnexionuemoa/
├── src/main/
│   ├── mule/
│   │   ├── global.xml              # Configuration globale
│   │   ├── interface.xml           # Endpoints API avec CORS
│   │   └── implementation/
│   │       └── kit-impl.xml        # Logique métier (workflows)
│   └── resources/
│       ├── api/
│       │   └── kitinterconnexionuemoa.raml  # Spécification API
│       ├── configs/
│       │   └── dev.yaml            # Configuration environnement
│       ├── db/
│       │   ├── init.sql            # Scripts base de données H2
│       │   └── init-interconnexion.sql  # Scripts Supabase
│       └── log4j2.xml              # Configuration logging
├── pom.xml                         # Configuration Maven
└── README.md                       # Documentation projet
```

## Installation et démarrage

### Prérequis

- **Java 17+**
- **Maven 3.6+**
- **MuleSoft Anypoint Studio** (optionnel pour le développement)
- **Accès Supabase** (pour la base de données de production)

### Configuration

1. **Cloner le repository**
```bash
git clone <repository-url>
cd kitinterconnexionuemoa
```

2. **Configuration de l'environnement**

Modifier le fichier `src/main/resources/configs/dev.yaml` :

```yaml
# Configuration HTTP
http:
  port: "8080"
  host: "0.0.0.0"

# Configuration Systèmes Externes
systeme:
  paysA:  # Sénégal - Port de Dakar
    host: "localhost"
    port: "3001"
    url: "https://simulateur-pays-a-cotier.vercel.app"
    endpoints:
      health: "/api/health"
      mainlevee: "/api/mainlevee/autorisation"

  paysB:  # Mali - Bamako
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

3. **Démarrage de l'application**

```bash
# Via Maven
mvn clean install
mvn mule:run

# Via Anypoint Studio
# Importer le projet et Run As > Mule Application
```

L'application sera accessible sur `http://localhost:8080`

## Utilisation de l'API

### Console API

Une console interactive est disponible à l'adresse :
`http://localhost:8080/console`

### Endpoints principaux

#### 1. Workflow Libre Pratique

##### ÉTAPES 4-5 : Transmission de manifeste depuis Sénégal

**POST** `/api/v1/manifeste/transmission`

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

##### ÉTAPES 14-16 : Réception déclaration depuis Mali

**POST** `/api/v1/declaration/soumission`

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

#### 2. Workflow Transit

##### ÉTAPES 1-6 : Création déclaration transit

**POST** `/api/v1/transit/creation`

```json
{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "paysDepart": "SEN",
  "paysDestination": "MLI",
  "transporteur": "TRANSPORT SAHEL",
  "modeTransport": "ROUTIER",
  "itineraire": "Dakar-Bamako via Kayes",
  "delaiRoute": "72 heures",
  "marchandises": [
    {
      "designation": "Produits manufacturés",
      "poids": 5000,
      "nombreColis": 100
    }
  ]
}
```

##### ÉTAPE 14 : Message arrivée transit

**POST** `/api/v1/transit/arrivee`

```json
{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "bureauArrivee": "10S_BAMAKO",
  "dateArrivee": "2025-01-18T10:30:00Z",
  "controleEffectue": true,
  "visaAppose": true,
  "conformiteItineraire": true,
  "delaiRespecte": true,
  "declarationDetailDeposee": false
}
```

#### 3. Endpoints de support

##### Vérification de santé

**GET** `/api/v1/health`

Retourne l'état détaillé du service, la connectivité aux systèmes externes, et les informations de version.

##### Notification paiement

**POST** `/api/v1/paiement/notification`

Support pour les notifications de paiement dans le workflow existant.

##### Traçabilité Commission UEMOA

**POST** `/api/v1/tracabilite/enregistrer`

Enregistrement des opérations pour la traçabilité centralisée de la Commission UEMOA.

##### Notification apurement

**POST** `/api/v1/apurement/notification`

Support pour la finalisation du workflow libre pratique depuis le Sénégal.

## Base de données

### Configuration Supabase (Production)

Le système utilise une base de données PostgreSQL hébergée sur Supabase pour le stockage persistant :

- **URL** : `https://hgkuqkjvgshfrayjelps.supabase.co`
- **Authentification** : Token-based avec clé anonyme et clé de service

### Tables principales

- **manifestes_recus** : Stockage des manifestes transmis depuis le Sénégal
- **declarations_recues** : Déclarations soumises par le Mali
- **declarations_transit** : Déclarations de transit
- **paiements_recus** : Notifications de paiement
- **autorisations_mainlevee** : Autorisations générées pour le Sénégal
- **messages_arrivee** : Messages d'arrivée transit
- **tracabilite_echanges** : Audit complet des échanges
- **configurations_pays** : Configuration des pays membres UEMOA
- **metriques_operations** : Métriques de performance du système

### Base de données H2 (Développement)

Pour le développement local, le système utilise une base H2 en mémoire avec initialisation automatique via les scripts dans `src/main/resources/db/`.

## Flux métier détaillés

### 1. Workflow Libre Pratique (Sénégal → Mali)

**Étapes 4-5 : Réception manifeste**
- Le Kit reçoit l'extraction du manifeste depuis le Port de Dakar
- Validation du format UEMOA
- Stockage dans Supabase pour traçabilité
- Routage automatique vers le Mali (Bamako)

**Étapes 14-16 : Traitement Mali**
- Réception de la déclaration en détail depuis le Mali
- Validation du paiement des droits et taxes
- Stockage de la confirmation de paiement
- Génération automatique d'autorisation de mainlevée

**Étape 17 : Autorisation vers Sénégal**
- Transmission de l'autorisation vers le Port de Dakar
- Format conforme aux attentes du système sénégalais
- Headers de traçabilité pour suivi complet

**Étapes 20-21 : Traçabilité Commission**
- Notification asynchrone de la Commission UEMOA
- Enregistrement de toutes les opérations
- Génération de statistiques centralisées

### 2. Workflow Transit (Sénégal → Mali → Sénégal)

**Étapes 1-6 : Création transit**
- Déclaration de transit créée au Sénégal
- Validation des informations de transport
- Stockage avec délais et itinéraires

**Étapes 10-11 : Transmission copie**
- Copie de la déclaration envoyée vers le Mali
- Instructions pour attendre l'arrivée
- Préparation des contrôles de passage

**Étape 14 : Message arrivée**
- Confirmation d'arrivée depuis le Mali
- Validation des contrôles effectués
- Vérification du respect des délais

**Étape 16 : Confirmation retour**
- Transmission du message de confirmation vers le Sénégal
- Données pour apurement de la déclaration transit
- Libération des garanties

## Sécurité et authentification

### Authentification

- **Basic Auth** pour les connexions vers les systèmes externes (Sénégal/Mali)
- **Bearer Token** pour les communications avec la Commission UEMOA
- **Token-based** pour l'accès à Supabase

### Headers de sécurité recommandés

```http
X-Source-Country: [Code pays 3 lettres - SEN, MLI]
X-Source-System: [Nom du système source]
X-Correlation-ID: [ID unique de corrélation]
X-Authorization-Source: KIT_INTERCONNEXION
X-Manifeste-Format: UEMOA
X-Workflow-Step: [Numéro d'étape du workflow]
```

### Configuration des tokens

```yaml
# Dans dev.yaml
commission:
  uemoa:
    auth:
      token: "COMMISSION_SECRET_KEY"

supabase:
  anon_key: "your-supabase-anon-key"
  service_role_key: "your-supabase-service-role-key"
```

## Monitoring et observabilité

### Configuration des logs

Les logs sont configurés via `log4j2.xml` avec plusieurs niveaux :
- **INFO** : Opérations normales, étapes des workflows
- **ERROR** : Erreurs de traitement, échecs de communication
- **DEBUG** : Détails des transformations de données

Fichiers de logs :
- Console (développement)
- `${mule.home}/logs/kitinterconnexionuemoa.log` (production)

### Métriques automatiques

Le système enregistre dans la table `metriques_operations` :
- Nombre d'opérations par type et par pays
- Temps de réponse moyens
- Taux d'erreur par endpoint
- Volume de données échangées

### Health Check détaillé

L'endpoint `/api/v1/health` fournit :
- État du Kit d'Interconnexion
- Connectivité aux systèmes externes (Sénégal, Mali, Commission)
- État de la base de données Supabase
- Versions des workflows supportés
- Endpoints actifs et leur statut

## CORS et intégration frontend

### Configuration CORS

Le système supporte CORS pour l'intégration avec des applications web :

```yaml
cors:
  enabled: "true"
  origins:
    - "*.vercel.app"
    - "localhost"
    - "127.0.0.1"
```

### Headers CORS supportés

- `Content-Type`, `Authorization`
- `X-Source-Country`, `X-Source-System`
- `X-Correlation-ID`, `X-Workflow-Step`
- `X-Authorization-Source`, `X-Manifeste-Format`

## Développement et tests

### Variables d'environnement

Configuration flexible via `dev.yaml` :
- URLs et ports des systèmes externes
- Configuration base de données (H2/Supabase)
- Clés d'API et tokens d'authentification
- Niveaux de logging et timeouts

### Structure des tests

```bash
# Exécution des tests unitaires
mvn test

# Tests d'intégration avec systèmes externes
mvn verify

# Test de connectivité
curl http://localhost:8080/api/v1/health
```

### Environnements

- **Développement** : H2 en mémoire, systèmes simulés localement
- **Test** : Supabase avec données de test, systèmes de staging
- **Production** : Supabase production, systèmes réels UEMOA

## Déploiement

### Standalone

```bash
# Construction du package
mvn clean package

# Déploiement local
mvn mule:run
```

### CloudHub (Anypoint Platform)

```bash
# Déploiement sur CloudHub
mvn clean package deploy -DmuleDeploy -Dmule.application.name=kit-interconnexion-uemoa
```

### Configuration production

Pour la production, ajuster dans `dev.yaml` :
- URLs réelles des systèmes douaniers
- Tokens et clés d'authentification de production
- Configuration Supabase de production
- Timeouts et retry appropriés pour les réseaux UEMOA

## Codes d'erreur et gestion des erreurs

### Codes de statut HTTP

- **200** : Succès de l'opération
- **400** : Erreur de validation des données (format UEMOA invalide)
- **401** : Authentification requise ou invalide
- **500** : Erreur interne du système
- **503** : Service temporairement indisponible

### Gestion des erreurs

Le système inclut un gestionnaire global d'erreurs qui :
- Capture toutes les exceptions non traitées
- Retourne des réponses JSON structurées
- Log les erreurs avec contexte complet
- Préserve les headers CORS

### Retry et résilience

Configuration automatique de retry pour :
- Communications avec systèmes externes (3 tentatives)
- Accès base de données (2 tentatives)
- Notifications Commission UEMOA (mode asynchrone)

## Format UEMOA 2025.1

### Support du format

Le Kit supporte le format UEMOA 2025.1 avec :
- Validation des structures de données
- Transformation automatique entre pays
- Normalisation des codes pays (SEN, MLI, BFA, etc.)
- Mapping des champs selon les spécifications UEMOA

### Pays supportés

- **SEN** : Sénégal (Port de Dakar) - Pays côtier
- **MLI** : Mali (Bamako) - Pays de l'hinterland
- **BFA** : Burkina Faso - Support prévu
- **NER** : Niger - Support prévu
- **CIV** : Côte d'Ivoire - Support prévu

## Support et maintenance

### Support technique

Pour toute question technique :
- Consulter la documentation Anypoint Exchange
- Vérifier les logs applicatifs détaillés
- Utiliser l'endpoint de santé `/api/v1/health`
- Consulter les métriques dans Supabase

### Dépannage courant

**Problème de connectivité Commission UEMOA :**
- Vérifier le token dans `dev.yaml`
- Contrôler la connectivité réseau
- Consulter les logs pour erreurs d'envoi asynchrone
- Note : Les échecs Commission n'interrompent pas le flux principal

**Erreurs de validation format UEMOA :**
- Vérifier la structure JSON contre les types RAML
- Contrôler les champs obligatoires (numero_manif, pays_dest)
- Valider les codes pays normalisés

**Performance lente :**
- Vérifier les métriques dans la base de données
- Ajuster les timeouts dans `dev.yaml`
- Contrôler l'état des systèmes externes via health check

## Évolutions et roadmap

### Version actuelle : 1.0.0-UEMOA

- Support complet workflows Libre Pratique et Transit
- Intégration Sénégal-Mali fonctionnelle
- Traçabilité Commission UEMOA opérationnelle
- Base de données Supabase intégrée

### Prochaines versions

- Support d'autres pays UEMOA (Burkina Faso, Niger, Côte d'Ivoire)
- Interface d'administration web
- API de reporting et statistiques
- Support du format EDI UEMOA
- Intégration avec systèmes de paiement BCEAO

## Licence et conformité

Ce projet est développé dans le cadre de l'interconnexion des systèmes douaniers UEMOA selon les spécifications techniques de la Commission UEMOA.

**Conformité :**
- Format UEMOA 2025.1
- Workflow Libre Pratique 21 étapes
- Workflow Transit 16 étapes
- Traçabilité centralisée Commission UEMOA

---

**Version** : 1.0.0-UEMOA  
**Runtime** : Mule 4.9.2  
**Java** : 17  
**Format** : UEMOA 2025.1  
**Dernière mise à jour** : Janvier 2025

**Architecture** : Sénégal (Pays A) ↔ Kit MuleSoft ↔ Mali (Pays B) ↔ Commission UEMOA
