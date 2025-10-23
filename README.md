# 🏛️ Commission UEMOA - Système Central de Traçabilité

**Supervision Centrale des Workflows Douaniers UEMOA**  
*Ouagadougou, Burkina Faso*

[![Version](https://img.shields.io/badge/version-1.0.0--UEMOA--FINAL-blue.svg)](package.json)
[![Node](https://img.shields.io/badge/node-22.x-green.svg)](package.json)
[![License](https://img.shields.io/badge/license-OPEN-green.svg)](README.md)

---

## 📋 Vue d'ensemble

La **Commission UEMOA** (Union Économique et Monétaire Ouest Africaine) assure la **supervision centralisée** des échanges douaniers entre les 8 États membres. Ce système implémente la traçabilité finale des workflows douaniers conformément au Document d'Interconnexion des Systèmes Douaniers UEMOA.

### 🎯 Rôle selon Document d'Interconnexion

La Commission UEMOA intervient à des **étapes finales spécifiques** des workflows douaniers :

| Workflow | Étapes Totales | Étapes Commission | Description |
|----------|----------------|-------------------|-------------|
| **Libre Pratique** | 21 étapes | **20-21** | Notification manifeste + Traçabilité finale |
| **Transit** | 16 étapes | **16** | Traçabilité finale opérations transit |

#### 📊 Détail des Étapes Commission

**ÉTAPE 20** - Notification Manifeste  
- ✅ Réception notification depuis Kit d'Interconnexion MuleSoft
- 📦 Traçabilité de la transmission du manifeste
- 💾 Enregistrement données pour supervision UEMOA

**ÉTAPE 21** - Traçabilité Finale Libre Pratique  
- ✅ Confirmation finalisation workflow (21 étapes complètes)
- 📋 Enregistrement déclaration et paiement
- 🗄️ Archivage centralisé pour analyses UEMOA

**ÉTAPE 16** - Traçabilité Finale Transit  
- ✅ Confirmation opération transit terminée
- 🚛 Apurement et traçabilité finale
- 🛣️ Supervision corridor commercial

---

## 🏗️ Architecture d'Interconnexion

```
Pays Côtier (ex: Sénégal - Dakar)
    ↓ Étapes 1-5, 17-19
Kit MuleSoft d'Interconnexion (hébergé localement)
    ↓ Étapes 6-16
Pays Hinterland (ex: Mali - Bamako)
    ↓ Étapes 20-21
🏛️ Commission UEMOA (Supervision Centrale - Ouagadougou)
```

---

## 🚀 Démarrage Rapide

### Prérequis

- **Node.js** 22.x ou supérieur
- **npm** ou **yarn**
- Connexion réseau (pour Kit MuleSoft)

### Installation

```bash
# Cloner le dépôt
git clone <repository-url>
cd simulateur-commission-uemoa

# Installer les dépendances
npm install
```

### Configuration

Créer un fichier `.env` (optionnel) :

```bash
PORT=3003
NODE_ENV=production
KIT_MULESOFT_URL=http://64.225.5.75:8086/api/v1
```

### Lancement

```bash
# Mode production
npm start

# Mode développement avec hot-reload
npm run dev

# Lancement local
npm run local
```

Le système démarre sur **http://localhost:3003**

---

## 🔐 Authentification

Le système Commission UEMOA nécessite une **authentification obligatoire** avant accès au dashboard.

### Comptes de Démonstration

| Utilisateur | Mot de passe | Rôle | Permissions |
|-------------|--------------|------|-------------|
| `admin_commission` | `uemoa2025` | 👑 Administrateur | Toutes permissions |
| `superviseur` | `super2025` | 👁️ Superviseur | Lecture, Écriture, Supervision |
| `analyste` | `analyse2025` | 📊 Analyste | Lecture, Analyse |
| `operateur` | `oper2025` | ⚙️ Opérateur | Lecture seule |

**Page de connexion** : http://localhost:3003/login.html

### Gestion des Sessions

- ✅ Tokens JWT sécurisés
- ⏱️ Durée de session : 12 heures
- 🔒 Vérification automatique à chaque requête
- 🚪 Déconnexion sécurisée

---

## 📡 API Endpoints Commission

### Authentification

```bash
POST /api/auth/login          # Connexion utilisateur
POST /api/auth/logout         # Déconnexion
POST /api/auth/verify         # Vérification session
```

#### Exemple Login

```bash
curl -X POST http://localhost:3003/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin_commission",
    "password": "uemoa2025"
  }'
```

### Supervision

```bash
GET /api/health               # État système Commission
GET /api/statistiques         # Stats supervision UEMOA
GET /api/dashboard            # Métriques dashboard
```

### Traçabilité Centrale (Étapes 20-21-16)

#### Endpoint Principal

```bash
POST /api/tracabilite/enregistrer
```

**Exemple ÉTAPE 20 (Manifeste)** :

```json
{
  "typeOperation": "TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE",
  "numeroOperation": "UEMOA_MAN_2025_001",
  "paysOrigine": "SEN",
  "paysDestination": "MLI",
  "donneesMetier": {
    "numero_manifeste": "MAN_SEN_2025_5016",
    "navire": "MARCO POLO",
    "consignataire": "MAERSK LINE SENEGAL",
    "nombre_articles": 3,
    "valeur_approximative": 25000000
  }
}
```

**Exemple ÉTAPE 21 (Déclaration)** :

```json
{
  "typeOperation": "COMPLETION_LIBRE_PRATIQUE",
  "numeroOperation": "UEMOA_FINAL_2025_001",
  "paysOrigine": "SEN",
  "paysDestination": "MLI",
  "donneesMetier": {
    "numero_declaration": "DEC_MLI_2025_001",
    "montant_paye": 3500000,
    "reference_paiement": "PAY_MLI_2025_001",
    "workflow_complete": true
  }
}
```

#### Endpoints Spécialisés

```bash
POST /api/tracabilite/manifeste      # ÉTAPE 20 (Notifications manifestes)
POST /api/tracabilite/declaration    # ÉTAPE 21 (Finalisations)
GET  /api/tracabilite/lister         # Liste opérations tracées
GET  /api/tracabilite/rechercher     # Recherche opérations
```

### Kit d'Interconnexion

```bash
GET  /api/kit/test              # Test connectivité Kit MuleSoft
GET  /api/kit/diagnostic        # Diagnostic complet
POST /api/kit/synchroniser      # Synchronisation
```

### Rapports

```bash
GET  /api/rapports/exporter     # Export CSV/JSON
POST /api/rapports/generer      # Génération rapport
```

---

## 🧪 Tests

### Health Check

```bash
npm test
# ou
curl http://localhost:3003/api/health
```

### Tests par Étape

```bash
# Test ÉTAPE 20 (Manifeste)
npm run test-etape-20

# Test ÉTAPE 21 (Déclaration)
npm run test-etape-21

# Test ÉTAPE 16 (Transit)
npm run test-etape-16

# Test Kit MuleSoft
npm run test-kit

# Tous les tests
npm run test-all-etapes
```

### Tests Manuels

**Test ÉTAPE 20** :
```bash
curl -X POST http://localhost:3003/api/tracabilite/manifeste \
  -H "Content-Type: application/json" \
  -d '{
    "typeOperation": "TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE",
    "numeroOperation": "TEST_MAN_001",
    "paysOrigine": "SEN",
    "paysDestination": "MLI",
    "donneesMetier": {
      "numero_manifeste": "MAN_TEST_001",
      "navire": "TEST VESSEL"
    }
  }'
```

---

## 🌍 États Membres UEMOA Surveillés

### Pays Côtiers (Prime abord)

| Code | Pays | Capitale | Port Principal | Rôle |
|------|------|----------|----------------|------|
| 🇸🇳 SEN | Sénégal | Dakar | Port de Dakar | Pays de prime abord |
| 🇨🇮 CIV | Côte d'Ivoire | Abidjan | Port d'Abidjan | Pays de prime abord |
| 🇧🇯 BEN | Bénin | Cotonou | Port de Cotonou | Pays de prime abord |
| 🇹🇬 TGO | Togo | Lomé | Port de Lomé | Pays de prime abord |
| 🇬🇼 GNB | Guinée-Bissau | Bissau | Port de Bissau | Pays de prime abord |

### Pays Hinterland (Destination)

| Code | Pays | Capitale | Rôle |
|------|------|----------|------|
| 🇲🇱 MLI | Mali | Bamako | Pays de destination |
| 🇧🇫 BFA | Burkina Faso | Ouagadougou | Pays de destination (Siège Commission) |
| 🇳🇪 NER | Niger | Niamey | Pays de destination |

**Total : 8 États membres UEMOA**

---

## 📁 Structure du Projet

```
simulateur-commission-uemoa/
├── api/                                # Endpoints API Commission
│   ├── auth/                          # Authentification
│   │   ├── login.js                  # Connexion
│   │   ├── logout.js                 # Déconnexion
│   │   └── verify.js                 # Vérification session
│   ├── health.js                      # Health check
│   ├── statistiques.js                # Stats supervision
│   ├── dashboard.js                   # Dashboard métriques
│   ├── tracabilite/
│   │   ├── enregistrer.js             # ⭐ ÉTAPES 20-21-16 (principal)
│   │   ├── manifeste.js               # ⭐ ÉTAPE 20 (spécialisé)
│   │   ├── declaration.js             # ⭐ ÉTAPE 21 (spécialisé)
│   │   ├── lister.js                  # Liste opérations
│   │   └── rechercher.js              # Recherche
│   ├── kit/
│   │   ├── test.js                    # Tests Kit MuleSoft
│   │   ├── diagnostic.js              # Diagnostic complet
│   │   └── synchroniser.js            # Synchronisation
│   └── rapports/
│       ├── exporter.js                # Export CSV/JSON
│       └── generer.js                 # Génération rapports
├── lib/
│   ├── database.js                    # ⭐ Base traçabilité Commission
│   ├── analytics.js                   # ⭐ Analytics supervision
│   └── kit-client.js                  # ⭐ Client Kit MuleSoft
├── public/
│   ├── index.html                     # 🌐 Dashboard Commission
│   ├── login.html                     # 🔐 Page authentification
│   ├── auth.js                        # Script auth client
│   ├── script.js                      # Script dashboard
│   └── style.css                      # Styles CSS
├── server.js                          # ⭐ Serveur HTTP
├── package.json
├── vercel.json                        # Config déploiement Vercel
├── .gitignore
└── README.md
```

---

## 📊 Dashboard Commission

Le dashboard web permet de :

- ✅ **Visualiser workflows** libre pratique (21 étapes) et transit (16 étapes)
- 📊 **Suivre activité** des 8 pays membres en temps réel
- 📈 **Consulter statistiques** supervision UEMOA
- 🔧 **Tester connectivité** Kit d'Interconnexion MuleSoft
- 📋 **Générer rapports** de supervision
- 📥 **Exporter données** tracées (CSV/JSON)
- 🔐 **Authentification sécurisée** avec gestion des rôles

**Accès Dashboard** : http://localhost:3003 (authentification requise)

### Fonctionnalités Principales

#### 1. Supervision en Temps Réel
- Métriques workflows libre pratique et transit
- Nombre de pays actifs
- Corridors commerciaux surveillés
- Opérations du jour

#### 2. Onglets Spécialisés
- 📦 **Manifestes** (ÉTAPE 20)
- 📋 **Déclarations** (ÉTAPE 21)
- 🚛 **Transit** (ÉTAPE 16)
- 🔍 **Toutes Opérations**

#### 3. Tests Kit MuleSoft
- Test connectivité
- Diagnostic complet
- Synchronisation
- Test notifications

#### 4. Rapports et Exports
- Export CSV
- Export JSON
- Génération rapports supervision
- Filtrage par période

---

## 🔧 Dépannage

### Problème : Échec Authentification

**Symptômes** :
- Impossible de se connecter
- Message "Identifiants incorrects"

**Solutions** :
1. Vérifier les identifiants (voir section Authentification)
2. Effacer le cache navigateur : `localStorage.clear()`
3. Vérifier que `api/auth/login.js` existe
4. Consulter les logs serveur

```bash
# Dans la console navigateur (F12)
localStorage.clear()
# Puis rafraîchir la page
```

### Problème : Fichiers API Manquants

**Symptômes** :
- Erreurs 404 sur endpoints
- "Handler Commission non trouvé"

**Vérifier l'existence des fichiers essentiels** :
```bash
ls -la api/tracabilite/enregistrer.js
ls -la api/tracabilite/manifeste.js
ls -la api/tracabilite/declaration.js
ls -la lib/database.js
ls -la lib/kit-client.js
```

Si manquants, vérifier le `.gitignore` et restaurer depuis le repository.

### Problème : Kit MuleSoft Inaccessible

**Symptômes** :
- Tests Kit échouent
- "Kit MuleSoft inaccessible"

**Solutions** :
1. Vérifier URL Kit dans `.env`
2. Tester connectivité : `npm run test-kit`
3. Vérifier pare-feu/proxy
4. Consulter logs serveur

```bash
# Test manuel
curl http://64.225.5.75:8086/api/v1/health
```

### Problème : Port 3003 Déjà Utilisé

**Symptômes** :
- "EADDRINUSE: address already in use"

**Solutions** :
```bash
# Linux/Mac
lsof -ti:3003 | xargs kill -9

# Windows
netstat -ano | findstr :3003
taskkill /PID <PID> /F

# Ou utiliser un autre port
PORT=3004 npm start
```

### Problème : Erreurs CORS

**Symptômes** :
- "CORS policy: No 'Access-Control-Allow-Origin'"

**Solutions** :
1. Vérifier headers CORS dans `server.js`
2. Utiliser le même domaine/port
3. Consulter logs navigateur (F12)

---

## 📚 Documentation Technique

### Workflows UEMOA

#### Workflow Libre Pratique (21 étapes)

**Étapes 1-5** : Sénégal (Manifeste)
- Création manifeste maritime
- Transmission vers Kit MuleSoft

**Étapes 6-16** : Mali (Déclaration, Contrôles, Paiement)
- Réception manifeste
- Déclaration douanière GUCE
- Contrôles documentaires/physiques
- Liquidation et paiement
- Transmission autorisation

**Étapes 17-19** : Sénégal (Autorisation, Apurement)
- Réception autorisation Mali
- Apurement manifeste
- Mainlevée marchandises

**⭐ Étapes 20-21** : Commission UEMOA (Traçabilité centrale)
- **20** : Notification manifeste
- **21** : Traçabilité finale workflow

#### Workflow Transit (16 étapes)

**Étapes 1-6** : Pays départ (Déclaration transit)
- Création déclaration transit
- Validation douane
- Scellement marchandises

**Étapes 7-14** : Circulation et arrivée
- Transit physique
- Arrivée destination
- Notification arrivée

**Étapes 15-16** : Pays départ + Commission
- **15** : Apurement transit (Pays départ)
- **⭐ 16** : Traçabilité finale (Commission UEMOA)

### Kit d'Interconnexion MuleSoft

Composant technique déployé dans chaque pays membre :

**Fonctions** :
- 🔄 Gère échanges entre systèmes douaniers
- 📊 Notifie Commission aux étapes 20-21 et 16
- 🔗 Basé sur plateforme API Management MuleSoft
- 💾 Hébergé localement dans chaque SI Douanier

**URL Production** : https://kit-interconnexion-uemoa-v4320.m3jzw3-1.deu-c1.cloudhub.io

**Endpoints Kit** :
- `/api/v1/health` - Health check
- `/api/v1/tracabilite/enregistrer` - Enregistrement opérations
- `/api/v1/console` - Console monitoring

---

## 🔒 Sécurité

### Bonnes Pratiques

1. **Authentification** :
   - ✅ Tokens sécurisés avec expiration
   - ✅ Vérification à chaque requête
   - ✅ Sessions limitées (12h)

2. **API** :
   - ✅ CORS configuré correctement
   - ✅ Validation des données entrantes
   - ✅ Gestion erreurs robuste

3. **Données** :
   - ✅ Pas de données sensibles en clair
   - ✅ Logs sécurisés
   - ✅ Backup régulier recommandé

### Variables d'Environnement

Ne **jamais** committer le fichier `.env` avec des secrets réels.

Exemple `.env.example` :
```bash
PORT=3003
NODE_ENV=production
KIT_MULESOFT_URL=<url-kit>
# Ajouter autres variables si nécessaire
```

---

## 🚀 Déploiement

### Déploiement Local

```bash
npm install
npm start
```

### Déploiement Vercel

Le projet est configuré pour Vercel avec `vercel.json` :

```bash
# Installation Vercel CLI
npm i -g vercel

# Déploiement
vercel

# Production
vercel --prod
```

### Variables d'Environnement Vercel

Dans le dashboard Vercel, ajouter :
- `PORT` : 3003
- `NODE_ENV` : production
- `KIT_MULESOFT_URL` : <url-kit>

---

## 📈 Monitoring et Logs

### Logs Serveur

Les logs incluent :
- ✅ Requêtes HTTP avec timestamp
- ✅ Opérations de traçabilité
- ✅ Erreurs détaillées avec stack trace
- ✅ Tests Kit MuleSoft
- ✅ Authentification

Exemple :
```
[23/10/2025 14:30:15] POST /api/tracabilite/enregistrer - [Commission UEMOA]
📊 [Commission UEMOA] POST /api/tracabilite/enregistrer - Traçabilité: {
  typeOperation: 'TRANSMISSION_MANIFESTE_LIBRE_PRATIQUE',
  numeroOperation: 'UEMOA_MAN_2025_001',
  corridor: 'SEN → MLI',
  etapeWorkflow: '20'
}
✅ [Commission] ÉTAPE 20 TERMINÉE: Opération abc123 tracée
```

### Journal Dashboard

Le dashboard inclut un journal en temps réel avec :
- 🕐 Timestamp de chaque opération
- 📋 Type d'opération
- 🔍 Détails de l'opération
- 🎯 Filtrage par type

---

## 🤝 Contribution

Ce projet est un prototype pour la mission d'interconnexion UEMOA.

### Standards de Code

- ✅ **ESLint** : Code JavaScript standardisé
- ✅ **Comments** : Code commenté (français)
- ✅ **Naming** : Noms explicites
- ✅ **Logs** : Logging détaillé Commission

---

## 📞 Support

**Organisme** : Commission UEMOA  
**Siège** : Ouagadougou, Burkina Faso  
**Rôle** : Supervision Centrale Traçabilité  
**Version** : 1.0.0-UEMOA-FINAL  
**Runtime** : Node.js 22.x  

**Documentation** :
- 📖 README.md (ce fichier)
- 📊 Document d'Interconnexion UEMOA
- 🔗 Kit MuleSoft Documentation

---

## 📄 Licence

**OPEN** - Projet supervision échanges douaniers UEMOA

---

## 🎯 Roadmap

### Version 1.x

- [x] Authentification sécurisée
- [x] Traçabilité ÉTAPES 20-21-16
- [x] Dashboard supervision
- [x] Tests Kit MuleSoft
- [x] Export données CSV/JSON
- [x] Analytics supervision

### Version 2.x (Futur)

- [ ] API REST complète avec OpenAPI
- [ ] Webhooks temps réel
- [ ] Dashboard analytics avancé
- [ ] Multi-tenancy pays membres
- [ ] Mobile app Commission
- [ ] Machine Learning prédictions

---

## 🙏 Remerciements

- **Jasmine Conseil** - Développement prototype
- **Commission UEMOA** - Cahier des charges
- **États Membres UEMOA** - Collaboration
- **MuleSoft** - Plateforme d'interconnexion

---

*Commission UEMOA - Système Central de Traçabilité selon Document d'Interconnexion des Systèmes Douaniers*

**Dernière mise à jour** : Octobre 2025
