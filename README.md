# Kit d'Interconnexion UEMOA

> Solution MuleSoft pour l'interconnexion des systèmes douaniers des États membres de l'UEMOA

[![Version](https://img.shields.io/badge/version-1.0.0--UEMOA-blue.svg)](https://github.com/uemoa/kit-interconnexion)
[![Mule Runtime](https://img.shields.io/badge/Mule%20Runtime-4.9.2-green.svg)](https://www.mulesoft.com)
[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.org/)

## 📋 Table des matières

- [Vue d'ensemble](#-vue-densemble)
- [Architecture](#-architecture)
- [Installation rapide](#-installation-rapide)
- [Configuration](#-configuration)
- [Workflows](#-workflows)
- [API Endpoints](#-api-endpoints)
- [Tests](#-tests)
- [Dépannage](#-dépannage)
- [Support](#-support)

## 🎯 Vue d'ensemble

Le Kit d'Interconnexion UEMOA facilite les échanges de données entre les systèmes douaniers nationaux pour:
- ✅ Tracer les marchandises en transit
- ✅ Gérer le régime de libre pratique
- ✅ Réduire les délais de dédouanement
- ✅ Assurer la conformité UEMOA

### Cas d'usage

**Exemple**: Une marchandise destinée au Mali arrive au Port de Dakar (Sénégal)

```
Port de Dakar (🇸🇳) → Kit MuleSoft → Bamako (🇲🇱) → Commission UEMOA
```

1. Dakar enregistre le manifeste
2. Le Kit extrait et route vers Mali
3. Mali déclare et paie les droits
4. Le Kit autorise la mainlevée à Dakar
5. Commission UEMOA assure la traçabilité

## 🏗 Architecture

### Stack Technique

| Composant | Version | Usage |
|-----------|---------|-------|
| **MuleSoft Mule** | 4.9.2 | Moteur d'intégration |
| **Java** | 17 | Runtime JVM |
| **PostgreSQL** | Latest | Base Supabase (production) |
| **H2** | 2.3.232 | Base locale (développement) |
| **APIKit** | 1.11.6 | Spécification RAML |
| **ActiveMQ** | 5.16.7 | Messaging asynchrone |

### Architecture du Système

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   SÉNÉGAL    │────────▶│ KIT MULESOFT │────────▶│     MALI     │
│ (Port Dakar) │◀────────│    (Hub)     │◀────────│   (Bamako)   │
└──────────────┘         └──────┬───────┘         └──────────────┘
  Pays côtier                   │                   Hinterland
                                ▼
                       ┌──────────────┐
                       │  COMMISSION  │
                       │    UEMOA     │
                       └──────────────┘
```

### Composants Clés

1. **Base de données Supabase** - Stockage centralisé
2. **Serveur (S)FTP** - Gestion des documents
3. **Moteur de batchs** - Traitements automatisés
4. **Files JMS ActiveMQ** - Communications asynchrones
5. **APIs REST** - Endpoints d'intégration

## 🚀 Installation rapide

### Prérequis

```bash
# Vérifier Java 17+
java -version

# Vérifier Maven 3.6+
mvn -version
```

### Installation

```bash
# 1. Cloner le projet
git clone https://github.com/uemoa/kit-interconnexion-uemoa.git
cd kitinterconnexionuemoa

# 2. Configurer Supabase (voir section Configuration)
# Éditer src/main/resources/configs/dev.yaml

# 3. Build
mvn clean install

# 4. Démarrer
mvn mule:run
```

### Vérification

```bash
# Test health check
curl http://localhost:8080/api/v1/health

# Console API
open http://localhost:8080/console
```

## ⚙️ Configuration

### Configuration Supabase (Obligatoire)

```yaml
# src/main/resources/configs/dev.yaml
supabase:
  url: "https://YOUR_PROJECT.supabase.co"
  host: "YOUR_PROJECT.supabase.co"
  port: "443"
  anon_key: "YOUR_ANON_KEY"
  service_role_key: "YOUR_SERVICE_ROLE_KEY"
```

**Étapes**:
1. Créer un projet sur [supabase.com](https://supabase.com)
2. Récupérer les clés dans Project Settings → API
3. Exécuter `src/main/resources/db/init-interconnexion.sql`

### Configuration Systèmes Externes

```yaml
systeme:
  paysA:  # Sénégal
    url: "https://simulateur-pays-a-cotier.vercel.app"
  
  paysB:  # Mali
    url: "https://simulateur-pays-b-hinterland.vercel.app"

commission:
  uemoa:
    url: "https://simulateur-commission-uemoa.vercel.app"
    auth:
      token: "VOTRE_TOKEN"
```

### Ports et Timeouts

```yaml
http:
  port: "8080"  # Modifier si occupé
  host: "0.0.0.0"

external:
  timeout:
    connection: "15000"  # 15 secondes
    read: "20000"        # 20 secondes
```

## 🔄 Workflows

### Workflow 1: Libre Pratique (21 étapes)

Permet le dédouanement de marchandises destinées à un pays enclavé arrivant dans un port côtier.

**Flux simplifié**:

```
SÉNÉGAL (Étapes 1-5)
  ↓ Transmission manifeste
KIT MULESOFT (Étapes 4-5, 16-17, 20-21)
  ↓ Routage vers Mali
MALI (Étapes 6-16)
  • Réception manifeste (6)
  • Déclaration + Paiement (7-14)
  • Transmission déclaration (15-16)
  ↓
KIT MULESOFT
  ↓ Autorisation mainlevée
SÉNÉGAL (Étapes 17-19)
  • Mainlevée + Enlèvement
```

### Workflow 2: Transit (16 étapes)

Suivi des marchandises en transit entre pays.

**Flux simplifié**:

```
SÉNÉGAL (Étapes 1-6)
  • Création déclaration transit
  ↓
KIT MULESOFT (Étapes 10-11)
  • Transmission copie vers Mali
  ↓
MALI (Étapes 13-14)
  • Réception + Message arrivée
  ↓
KIT MULESOFT (Étape 16)
  • Confirmation retour Sénégal
  ↓
SÉNÉGAL (Étapes 17-18)
  • Apurement transit
```

## 🔌 API Endpoints

### Health Check

```bash
GET /api/v1/health
```

Vérifie l'état du Kit et la connectivité avec tous les systèmes externes.

### Workflow Libre Pratique

**Étapes 4-5: Réception manifeste (Sénégal → Mali)**

```bash
POST /api/v1/manifeste/transmission
Content-Type: application/json
X-Source-Country: SEN

{
  "annee_manif": "2025",
  "bureau_manif": "18N",
  "numero_manif": 5016,
  "consignataire": "MAERSK LINE",
  "navire": "MARCO POLO",
  "articles": [{
    "art": 1,
    "pays_dest": "MALI",
    "marchandise": "Véhicule Toyota",
    "poids": 1500
  }]
}
```

**Étapes 14-16: Réception déclaration (Mali → Sénégal)**

```bash
POST /api/v1/declaration/soumission
Content-Type: application/json
X-Source-Country: MLI

{
  "numeroDeclaration": "DEC-MLI-2025-001",
  "manifesteOrigine": "5016",
  "montantPaye": 250000,
  "referencePaiement": "PAY-MLI-2025-001",
  "datePaiement": "2025-01-15T14:30:00Z"
}
```

### Workflow Transit

**Étapes 1-6: Création transit**

```bash
POST /api/v1/transit/creation
X-Source-Country: SEN

{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "paysDepart": "SEN",
  "paysDestination": "MLI",
  "transporteur": "TRANSPORT SAHEL",
  "itineraire": "Dakar-Bamako",
  "delaiRoute": "72 heures"
}
```

**Étape 14: Message arrivée**

```bash
POST /api/v1/transit/arrivee
X-Source-Country: MLI

{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "dateArrivee": "2025-01-23T10:00:00Z",
  "controleEffectue": true,
  "conformiteItineraire": true
}
```

### Commission UEMOA

**Étapes 20-21: Traçabilité**

```bash
POST /api/v1/tracabilite/enregistrer

{
  "typeOperation": "TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE",
  "paysOrigine": "SEN",
  "paysDestination": "MLI",
  "numeroOperation": "5016-2025-20250115"
}
```

## 🧪 Tests

### Test Manuel via Console

1. Ouvrir http://localhost:8080/console
2. Sélectionner l'endpoint à tester
3. Utiliser les exemples pré-remplis
4. Cliquer "Try it"

### Test Workflow Complet

```bash
# 1. Transmission manifeste
curl -X POST http://localhost:8080/api/v1/manifeste/transmission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -d @examples/manifeste.json

# 2. Soumission déclaration
curl -X POST http://localhost:8080/api/v1/declaration/soumission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -d @examples/declaration.json
```

### Tests Unitaires

```bash
# Exécuter tous les tests
mvn test

# Tests spécifiques
mvn test -Dtest=ManifestTransmissionTest
```

## 🔧 Dépannage

### Problème: Kit ne démarre pas

**Symptôme**: `Failed to deploy application`

**Solutions**:
```bash
# 1. Vérifier Java 17
java -version

# 2. Vérifier port disponible
lsof -i :8080  # Mac/Linux
netstat -ano | findstr :8080  # Windows

# 3. Changer le port si nécessaire
# Éditer dev.yaml: http.port: "8081"

# 4. Vérifier logs
tail -f logs/kitinterconnexionuemoa.log
```

### Problème: Erreur connexion Supabase

**Symptôme**: `401 Unauthorized`

**Solutions**:
```bash
# 1. Tester connexion directe
curl https://YOUR_PROJECT.supabase.co/rest/v1/configurations_pays \
  -H "apikey: YOUR_ANON_KEY"

# 2. Vérifier clés dans dev.yaml
# 3. Vérifier tables créées
# 4. Désactiver RLS (Row Level Security)
```

### Problème: Manifeste non routé vers Mali

**Symptôme**: `Connection timeout`

**Solutions**:
```bash
# 1. Tester connectivité Mali
curl https://simulateur-pays-b-hinterland.vercel.app/api/health

# 2. Augmenter timeout
# dev.yaml: external.timeout.connection: "30000"

# 3. Vérifier logs détaillés
tail -f logs/kitinterconnexionuemoa.log | grep Mali
```

### Problème: Format UEMOA invalide

**Symptôme**: `400 Bad Request: Format invalide`

**Champs obligatoires**:
- ✅ `numero_manif` (integer)
- ✅ `annee_manif` (string)
- ✅ `bureau_manif` (string)
- ✅ `articles` (array non vide)
- ✅ `articles[].pays_dest` (contient "MALI")

**Exemple minimal valide**:
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

## 📊 Base de Données

### Tables Principales

| Table | Description |
|-------|-------------|
| `manifestes_recus` | Manifestes transmis depuis pays côtiers |
| `declarations_recues` | Déclarations pays hinterland |
| `declarations_transit` | Déclarations de transit |
| `paiements_recus` | Notifications paiement |
| `autorisations_mainlevee` | Autorisations mainlevée |
| `tracabilite_echanges` | Audit complet |

### Requêtes Utiles

```sql
-- Vérifier derniers manifestes
SELECT numero_manifeste, pays_origine, pays_destination, date_reception 
FROM manifestes_recus 
ORDER BY date_reception DESC 
LIMIT 10;

-- Statistiques par pays
SELECT pays_destination, COUNT(*) as total
FROM manifestes_recus
GROUP BY pays_destination;

-- Temps de traitement moyen
SELECT AVG(duree_traitement_ms) as temps_moyen_ms
FROM tracabilite_echanges
WHERE type_operation = 'TRANSMISSION_MANIFESTE';
```

## 🚢 Déploiement

### Déploiement Standalone

```bash
# 1. Build package
mvn clean package

# 2. Copier vers Mule Runtime
cp target/kit-interconnexion-uemoa-*.jar $MULE_HOME/apps/

# 3. Démarrer
$MULE_HOME/bin/mule start
```

### Déploiement CloudHub

```bash
mvn clean package deploy -DmuleDeploy \
  -Dmule.application.name=kit-interconnexion-uemoa \
  -Danypoint.platform.client_id=$CLIENT_ID \
  -Danypoint.platform.client_secret=$CLIENT_SECRET \
  -Danypoint.platform.environment=Production \
  -Danypoint.platform.workers=2
```

### Configuration Production

```yaml
# Timeouts plus élevés
external:
  timeout:
    connection: "30000"
    read: "60000"

# URLs réelles
systeme:
  paysA:
    url: "https://douanes.senegal.sn/api"
  paysB:
    url: "https://douanes.mali.ml/api"

# Sécurité
tls:
  enabled: true
  keystore: "/path/to/keystore.jks"
```

## 📚 Documentation

- **API RAML**: `src/main/resources/api/kitinterconnexionuemoa.raml`
- **Console interactive**: http://localhost:8080/console
- **Logs**: `logs/kitinterconnexionuemoa.log`
- **Architecture**: Voir section [Architecture](#-architecture)

## 🤝 Support

### Obtenir de l'aide

- 📧 **Email**: support-kit@uemoa.int
- 📚 **Documentation**: https://docs.uemoa.int/kit-interconnexion
- 💬 **Forum**: https://forum.uemoa.int/interconnexion
- 🐛 **Issues**: https://github.com/uemoa/kit-interconnexion/issues

### Contribuer

```bash
# 1. Fork le projet
# 2. Créer une branche
git checkout -b feature/ma-fonctionnalite

# 3. Commiter
git commit -m "feat: ajout support Burkina Faso"

# 4. Pousser et créer Pull Request
git push origin feature/ma-fonctionnalite
```

## 📝 Informations Projet

| Info | Valeur |
|------|--------|
| **Version** | 1.0.0-UEMOA |
| **Format** | UEMOA 2025.1 |
| **Runtime** | Mule 4.9.2 |
| **Java** | 17 |
| **Licence** | MIT |
| **Organisation** | UEMOA - Commission |

---

**Architecture**: Sénégal 🇸🇳 ↔ Kit MuleSoft ↔ Mali 🇲🇱 ↔ Commission UEMOA

**Workflows**: Libre Pratique (21 étapes) • Transit (16 étapes)

*Documentation mise à jour: Janvier 2025*
