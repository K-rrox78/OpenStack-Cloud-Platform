# Guide d'Utilisation de la Plateforme Cloud OpenStack

Ce document explique comment utiliser l'interface utilisateur pour déployer et gérer des machines virtuelles sur l'infrastructure OpenStack.

## Fonctionnalités principales

L'interface utilisateur permet de :
- Déployer des machines virtuelles Linux et Windows
- Surveiller l'état des VMs et de l'infrastructure
- Gérer le cycle de vie des VMs (démarrer, arrêter, supprimer)
- Visualiser les statistiques d'utilisation des ressources

## Accès à l'interface

L'interface web est accessible à l'adresse : `http://<adresse_serveur>:5000`

## Tableau de bord

Le tableau de bord fournit une vue d'ensemble de votre infrastructure OpenStack :

- **Statistiques générales** : Nombre total de VMs, répartition Linux/Windows
- **Utilisation des ressources** : CPU, RAM, stockage, réseau
- **État des nœuds** : Contrôleur et nœuds compute
- **VMs récentes** : Liste des dernières machines virtuelles déployées

## Déploiement de machines virtuelles

### Pour déployer des machines virtuelles :

1. Accédez à la page "Déployer" depuis le menu de navigation
2. Remplissez le formulaire de déploiement :
   - **Préfixe de nom** : Un nom de base pour vos VMs (sera suivi d'un numéro)
   - **Type d'OS** : Linux ou Windows
   - **Image** : Sélectionnez l'image de système d'exploitation
   - **Configuration** : Choisissez les ressources (CPU, RAM, disque)
   - **Nombre de VMs** : Spécifiez combien de machines identiques déployer
   - **Réseau** : Type de connexion réseau
   - **Options avancées** : Configuration additionnelle (scripts d'initialisation, etc.)
3. Cliquez sur "Déployer les machines virtuelles"

Le système vous redirigera vers la page de statut des déploiements où vous pourrez suivre la progression.

### Configurations prédéfinies pour Linux

| Configuration | RAM | vCPU | Disque |
|--------------|-----|------|--------|
| Petite       | 2 Go | 1    | 20 Go  |
| Moyenne      | 4 Go | 2    | 40 Go  |
| Grande       | 8 Go | 4    | 80 Go  |

### Configurations prédéfinies pour Windows

| Configuration | RAM  | vCPU | Disque |
|--------------|------|------|--------|
| Petite       | 4 Go  | 2    | 40 Go  |
| Moyenne      | 8 Go  | 4    | 80 Go  |
| Grande       | 16 Go | 8    | 160 Go |

## Gestion des machines virtuelles

Depuis la page "Statut des déploiements", vous pouvez :

- **Voir les détails** d'une VM en cliquant sur le bouton "Détails"
- **Arrêter/Démarrer** une VM en utilisant le bouton correspondant
- **Supprimer** une VM en cliquant sur "Supprimer"

## Surveillance de l'infrastructure

Le tableau de bord offre des informations en temps réel sur :

- L'état des machines virtuelles (en cours d'exécution, en cours de déploiement, arrêtées)
- L'utilisation des ressources de l'infrastructure
- Les journaux de déploiement

## API REST

Pour l'automatisation et l'intégration avec d'autres systèmes, l'interface offre également une API REST :

| Endpoint | Méthode | Description |
|----------|--------|-------------|
| `/api/vms` | GET | Liste toutes les VMs |
| `/api/vms/{id}` | GET | Détails d'une VM spécifique |
| `/api/deploy` | POST | Déploie de nouvelles VMs |
| `/api/vms/{id}` | DELETE | Supprime une VM |
| `/api/vms/{id}/action` | POST | Effectue une action (démarrer/arrêter) |

## Bonnes pratiques

- **Nommage des VMs** : Utilisez des préfixes descriptifs pour faciliter l'identification
- **Déploiement par lots** : Pour déployer plusieurs VMs similaires, utilisez l'option "Nombre de VMs"
- **Scripts d'initialisation** : Utilisez les scripts cloud-init pour automatiser la configuration post-déploiement
- **Monitoring** : Consultez régulièrement le tableau de bord pour surveiller l'utilisation des ressources
