# Kit d'Interconnexion UEMOA

> Solution MuleSoft pour l'interconnexion des systèmes douaniers des États membres de l'UEMOA

[![Version](https://img.shields.io/badge/version-1.0.0--UEMOA-blue.svg)](https://github.com/uemoa/kit-interconnexion)
[![Mule Runtime](https://img.shields.io/badge/Mule%20Runtime-4.9.2-green.svg)](https://www.mulesoft.com)
[![Java](https://img.shields.io/badge/Java-17-orange.svg)](https://openjdk.org/)

## 📋 Vue d'ensemble

Le Kit d'Interconnexion est un **composant middleware** basé sur MuleSoft qui facilite les échanges de données entre les systèmes douaniers des pays de l'UEMOA pour le régime de **Libre Pratique** et le **Transit**.

### Rôle du Kit

Le Kit agit comme un **hub d'échange** qui :
- ✅ Reçoit les données d'un pays source
- ✅ Transforme les données au format requis
- ✅ Route vers le pays de destination
- ✅ Stocke pour traçabilité (Supabase)
- ✅ Notifie la Commission UEMOA

### Cas d'usage typique

Marchandise arrivant au **Port de Dakar (Sénégal)** destinée à **Bamako (Mali)** :

```
Port Dakar → Kit MuleSoft → Bamako → Commission UEMOA
```

## 🏗 Architecture

### Stack Technique

| Composant | Version | Rôle |
|-----------|---------|------|
| **MuleSoft Mule** | 4.9.2 | Moteur d'intégration & APIs |
| **Java** | 17 | Runtime |
| **PostgreSQL (Supabase)** | Latest | Base de données centralisée |
| **APIKit** | 1.11.6 | Spécification RAML des APIs |
| **ActiveMQ** | 5.16.7 | Messaging asynchrone |

### Composants du Kit

```
┌─────────────────────────────────────────────────────┐
│              KIT D'INTERCONNEXION                   │
├─────────────────────────────────────────────────────┤
│  1. API REST Endpoints                              │
│  2. Base Supabase (stockage intermédiaire)          │
│  3. Transformateurs de données (DataWeave)          │
│  4. Moteur de routage (HTTP Request)                │
│  5. Files JMS (messaging asynchrone)                │
│  6. Traçabilité vers Commission UEMOA               │
└─────────────────────────────────────────────────────┘
```

## 🔄 Workflows Supportés

### Workflow 1 : Libre Pratique (21 étapes)

Le Kit intervient à **3 moments clés** :

#### **Étapes 4-5 : Réception & Transmission Manifeste**
```
SÉNÉGAL (Étapes 1-3)
  ↓ Enregistre manifeste dans son SI
  
KIT MULESOFT (Étapes 4-5)
  • Reçoit extraction manifeste depuis Sénégal
  • Filtre articles destinés au Mali
  • Stocke dans Supabase
  • Transmet vers SI Mali
  ↓
  
MALI (Étapes 6-13)
  • Reçoit manifeste
  • Traite la déclaration
  • Effectue le paiement
```

#### **Étapes 14-16 : Réception Déclaration & Autorisation**
```
MALI (Étapes 14-15)
  • Envoie déclaration + paiement
  ↓
  
KIT MULESOFT (Étape 16)
  • Reçoit déclaration depuis Mali
  • Vérifie paiement
  • Stocke dans Supabase
  • Génère autorisation mainlevée
  • Transmet au Sénégal
  ↓
  
SÉNÉGAL (Étapes 17-19)
  • Reçoit autorisation
  • Délivre BAE (Bon à Enlever)
  • Libère marchandise
```

#### **Étapes 20-21 : Notification Commission**
```
KIT MULESOFT
  • Transmet données à la Commission UEMOA
  • Assure traçabilité complète
```

### Workflow 2 : Transit (16 étapes)

Le Kit intervient à **2 moments clés** :

#### **Étapes 10-11 : Transmission Copie Transit**
```
SÉNÉGAL (Étapes 1-9)
  • Crée déclaration transit
  ↓
  
KIT MULESOFT (Étapes 10-11)
  • Reçoit déclaration transit
  • Transmet copie au Mali
  ↓
  
MALI (Attend arrivée marchandise)
```

#### **Étape 16 : Confirmation Arrivée**
```
MALI (Étapes 13-15)
  • Marchandise arrive
  • Envoie message arrivée
  ↓
  
KIT MULESOFT (Étape 16)
  • Reçoit confirmation Mali
  • Transmet au Sénégal pour apurement
  ↓
  
SÉNÉGAL (Étapes 17-18)
  • Apure le transit
  • Libère garanties
```

## 🚀 Installation

### Prérequis

```bash
# Vérifier Java 17+
java -version

# Vérifier Maven 3.6+
mvn -version
```

### Installation Rapide

```bash
# 1. Cloner
git clone https://github.com/uemoa/kit-interconnexion-uemoa.git
cd kitinterconnexionuemoa

# 2. Configurer Supabase
# Éditer src/main/resources/configs/dev.yaml
# Renseigner : supabase.url, supabase.anon_key, supabase.service_role_key

# 3. Build & Run
mvn clean install
mvn mule:run
```

### Vérification

```bash
# Health check
curl http://localhost:8080/api/v1/health

# Console API
open http://localhost:8080/console
```

## 🔌 API Endpoints Clés

### Libre Pratique

**Étapes 4-5 : Réception Manifeste (Sénégal → Kit → Mali)**
```bash
POST /api/v1/manifeste/transmission
Content-Type: application/json
X-Source-Country: SEN

{
  "annee_manif": "2025",
  "bureau_manif": "18N",
  "numero_manif": 5016,
  "consignataire": "MAERSK LINE",
  "articles": [{
    "art": 1,
    "pays_dest": "MALI",
    "marchandise": "Véhicule Toyota",
    "poids": 1500
  }]
}
```

**Étapes 14-16 : Réception Déclaration (Mali → Kit → Sénégal)**
```bash
POST /api/v1/declaration/soumission
Content-Type: application/json
X-Source-Country: MLI

{
  "numeroDeclaration": "DEC-MLI-2025-001",
  "manifesteOrigine": "5016",
  "montantPaye": 250000,
  "referencePaiement": "PAY-MLI-2025-001"
}
```

### Transit

**Étapes 1-6 : Création Transit**
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

**Étape 14 : Message Arrivée**
```bash
POST /api/v1/transit/arrivee
X-Source-Country: MLI

{
  "numeroDeclaration": "TRA-SEN-2025-001",
  "dateArrivee": "2025-01-23T10:00:00Z",
  "controleEffectue": true
}
```

## ⚙️ Configuration

### Supabase (Obligatoire)

```yaml
# src/main/resources/configs/dev.yaml
supabase:
  url: "https://YOUR_PROJECT.supabase.co"
  host: "YOUR_PROJECT.supabase.co"
  port: "443"
  anon_key: "YOUR_ANON_KEY"
  service_role_key: "YOUR_SERVICE_ROLE_KEY"
```

**Étapes** :
1. Créer projet sur [supabase.com](https://supabase.com)
2. Récupérer clés dans Project Settings → API
3. Exécuter `src/main/resources/db/init-interconnexion.sql`

### Systèmes Externes

```yaml
systeme:
  paysA:  # Sénégal
    url: "https://simulateur-pays-a-cotier.vercel.app"
  
  paysB:  # Mali
    url: "https://simulateur-pays-b-hinterland.vercel.app"

commission:
  uemoa:
    url: "https://simulateur-commission-uemoa.vercel.app"
```

## 🧪 Tests

### Test Manuel

```bash
# 1. Transmission manifeste (Étapes 4-5)
curl -X POST http://localhost:8080/api/v1/manifeste/transmission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: SEN" \
  -d '{"annee_manif":"2025","bureau_manif":"18N","numero_manif":5016,"articles":[{"art":1,"pays_dest":"MALI"}]}'

# 2. Soumission déclaration (Étapes 14-16)
curl -X POST http://localhost:8080/api/v1/declaration/soumission \
  -H "Content-Type: application/json" \
  -H "X-Source-Country: MLI" \
  -d '{"numeroDeclaration":"DEC-MLI-2025-001","manifesteOrigine":"5016","montantPaye":250000}'
```

## 📊 Base de Données

### Tables Principales

| Table | Rôle dans le Kit |
|-------|------------------|
| `manifestes_recus` | Stocke manifestes transmis (Étape 4) |
| `declarations_recues` | Stocke déclarations Mali (Étape 14) |
| `declarations_transit` | Stocke déclarations transit |
| `autorisations_mainlevee` | Stocke autorisations (Étape 16) |
| `tracabilite_echanges` | Audit complet des échanges |

## 🔧 Dépannage

### Problème : Manifeste non routé vers Mali

**Symptôme** : `Connection timeout`

**Solutions** :
```bash
# 1. Tester connectivité Mali
curl https://simulateur-pays-b-hinterland.vercel.app/api/health

# 2. Augmenter timeout dans dev.yaml
external:
  timeout:
    connection: "30000"

# 3. Vérifier logs
tail -f logs/kitinterconnexionuemoa.log | grep Mali
```

### Problème : Format UEMOA invalide

**Champs obligatoires** :
- `numero_manif` (integer)
- `annee_manif` (string)
- `bureau_manif` (string)
- `articles` (array non vide)
- `articles[].pays_dest` (contient "MALI")

## 📚 Documentation

- **API RAML** : `src/main/resources/api/kitinterconnexionuemoa.raml`
- **Console** : http://localhost:8080/console
- **Logs** : `logs/kitinterconnexionuemoa.log`

## 🤝 Support

- 📧 **Email** : support-kit@uemoa.int
- 📚 **Docs** : https://docs.uemoa.int/kit-interconnexion
- 🐛 **Issues** : https://github.com/uemoa/kit-interconnexion/issues

---

**Architecture** : Sénégal 🇸🇳 ↔ Kit MuleSoft ↔ Mali 🇲🇱 ↔ Commission UEMOA

**Workflows** : Libre Pratique (21 étapes) • Transit (16 étapes)

*Version 1.0.0-UEMOA • Format UEMOA 2025.1 • Mule 4.9.2 • Java 17*
