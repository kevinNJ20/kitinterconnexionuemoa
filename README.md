# Kit d'Interconnexion UEMOA

## Vue d'ensemble

Le **Kit d'Interconnexion UEMOA** est une solution MuleSoft permettant l'interconnexion des systèmes informatiques douaniers des États membres de l'Union Économique et Monétaire Ouest Africaine (UEMOA) dans le cadre de la mise en œuvre du régime de la libre pratique.

Cette API facilite les échanges de données entre les pays côtiers (points d'entrée) et les pays de l'hinterland (destinations finales) pour le suivi des marchandises et des procédures douanières.

## Contexte métier

Dans le cadre de l'UEMOA, lorsqu'une marchandise arrive dans un pays côtier (exemple : Côte d'Ivoire) mais est destinée à un pays de l'hinterland (exemple : Burkina Faso), le système doit :

1. **Réceptionner le manifeste** depuis le pays d'arrivée
2. **Router les informations** vers le pays de destination
3. **Notifier la Commission UEMOA** pour traçabilité
4. **Recevoir les notifications de paiement** du pays de destination
5. **Autoriser la mainlevée** vers le pays d'origine

## Architecture technique

### Technologies utilisées

- **MuleSoft Mule Runtime** 4.9.2
- **APIKit** pour la spécification RAML
- **Base de données H2** (en mémoire pour le développement)
- **JMS ActiveMQ** pour le messaging asynchrone
- **Java 17**

### Structure du projet

```
kitinterconnexionuemoa/
├── src/main/
│   ├── mule/
│   │   ├── global.xml              # Configuration globale
│   │   ├── interface.xml           # Endpoints API
│   │   └── implementation/
│   │       └── kit-impl.xml        # Logique métier
│   └── resources/
│       ├── api/
│       │   └── kitinterconnexionuemoa.raml  # Spécification API
│       ├── configs/
│       │   └── dev.yaml            # Configuration environnement
│       └── db/
│           ├── init.sql            # Scripts base de données
│           └── init-interconnexion.sql
└── pom.xml                         # Configuration Maven
```

## Installation et démarrage

### Prérequis

- Java 17+
- Maven 3.6+
- MuleSoft Anypoint Studio (optionnel pour le développement)

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
  paysA:
    host: "localhost"
    port: "8081"
  paysB:
    host: "localhost"
    port: "8082"

commission:
  uemoa:
    host: "localhost"
    port: "8083"
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

### Endpoints disponibles

#### 1. Transmission de manifeste

**POST** `/api/v1/manifeste/transmission`

```json
{
  "numeroManifeste": "MAN2025001",
  "transporteur": "MAERSK LINE",
  "portEmbarquement": "ROTTERDAM",
  "portDebarquement": "ABIDJAN",
  "dateArrivee": "2025-01-15",
  "marchandises": [
    {
      "codeSH": "8703.21.10",
      "designation": "Véhicule particulier",
      "poidsBrut": 1500.00,
      "nombreColis": 1,
      "destinataire": "IMPORT SARL",
      "paysDestination": "BFA"
    }
  ]
}
```

#### 2. Notification de paiement

**POST** `/api/v1/paiement/notification`

```json
{
  "numeroDeclaration": "DEC2025001",
  "manifesteOrigine": "MAN2025001",
  "montantPaye": 250000.00,
  "referencePaiement": "PAY2025001",
  "datePaiement": "2025-01-15T14:30:00Z",
  "paysDeclarant": "BFA"
}
```

#### 3. Vérification de santé

**GET** `/api/v1/health`

Retourne l'état du service et ses informations de version.

## Flux métier

### 1. Réception manifeste (Pays A → Kit)
- Validation des données du manifeste
- Stockage en base de données
- Routage vers le pays de destination
- Notification asynchrone de la Commission UEMOA

### 2. Notification paiement (Pays B → Kit)
- Validation de la notification de paiement
- Stockage de la confirmation
- Génération d'autorisation de mainlevée
- Envoi de l'autorisation au pays d'origine

## Base de données

### Tables principales

- **manifestes_recus** : Stockage des manifestes reçus
- **paiements_recus** : Notifications de paiement
- **autorisations_mainlevee** : Autorisations générées
- **tracabilite_echanges** : Audit des échanges
- **configurations_pays** : Configuration des pays membres

### Initialisation

Les scripts SQL d'initialisation se trouvent dans `src/main/resources/db/` et sont exécutés automatiquement au démarrage.

## Monitoring et logs

### Configuration des logs

Les logs sont configurés via `log4j2.xml` et sont disponibles dans :
- Console (développement)
- Fichier `${mule.home}/logs/kitinterconnexionuemoa.log` (production)

### Métriques

Le système enregistre automatiquement :
- Nombre d'opérations par type
- Temps de réponse moyens
- Taux d'erreur
- Volume de données échangées

## Sécurité

### Authentification

- **Basic Auth** pour les connexions vers les systèmes externes
- **API Key** pour les communications avec la Commission UEMOA
- Headers de corrélation pour le traçage des requêtes

### Headers recommandés

```
X-Source-Country: [Code pays 3 lettres]
X-Correlation-ID: [ID unique de corrélation]
X-Authorization-Source: KIT_INTERCONNEXION
```

## Développement

### Variables d'environnement

Le projet utilise des variables configurables via `dev.yaml` :

- Ports et hosts des systèmes externes
- Configuration base de données
- Clés d'API et secrets
- Niveaux de logging

### Tests

```bash
# Exécution des tests
mvn test

# Tests d'intégration
mvn verify
```

## Déploiement

### Environnements

- **Développement** : Configuration locale avec H2 en mémoire
- **Test** : Base de données persistante
- **Production** : Configuration haute disponibilité

### CloudHub (optionnel)

Pour déployer sur Anypoint CloudHub :

```bash
mvn clean package deploy -DmuleDeploy
```

## Support et maintenance

### Codes d'erreur

- **200** : Succès
- **400** : Erreur de validation des données
- **500** : Erreur interne du système

### Contact technique

Pour toute question technique ou support :
- Documentation Anypoint Exchange
- Logs applicatifs détaillés
- Endpoint de santé `/api/v1/health`

## Licence

Ce projet est développé dans le cadre de l'interconnexion des systèmes douaniers UEMOA.

---

**Version** : 1.0.0-SNAPSHOT  
**Runtime** : Mule 4.9.2  
**Dernière mise à jour** : Janvier 2025