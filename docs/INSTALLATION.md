# Guide d'Installation de la Plateforme Cloud OpenStack

Ce document détaille les étapes nécessaires pour installer et configurer l'infrastructure OpenStack Cloud Platform.

## Prérequis matériels

### Nœud contrôleur
- 16 vCPU
- 32 Go RAM
- 500 Go SSD
- Interface réseau 10 Gbps

### Nœuds compute (2)
- 48 vCPU par nœud
- 96 Go RAM par nœud
- 2 To stockage par nœud
- Interface réseau 10 Gbps

## Prérequis logiciels

- Ubuntu Server 22.04 LTS
- Accès root sur tous les nœuds
- Connexion réseau entre tous les nœuds
- Python 3.10+
- Ansible 2.12+
- Terraform 1.3+

## Architecture du réseau

L'infrastructure requiert la configuration de trois réseaux distincts :

1. **Réseau de gestion** : Communication entre les services OpenStack
2. **Réseau de tenant** : Réseau interne pour les machines virtuelles
3. **Réseau externe** : Connexion des VMs au réseau externe

## Procédure d'installation

### 1. Configuration initiale

1. Installer Ubuntu Server 22.04 LTS sur tous les nœuds
2. Configurer les noms d'hôtes et les adresses IP statiques
3. Configurer SSH sans mot de passe entre le nœud de déploiement et tous les autres nœuds

### 2. Déploiement via Ansible

1. Cloner ce dépôt :
   ```
   git clone https://github.com/K-rrox78/OpenStack-Cloud-Platform.git
   cd OpenStack-Cloud-Platform
   ```

2. Mettre à jour le fichier d'inventaire Ansible :
   ```
   vim ansible/inventory.ini
   ```

3. Personnaliser les variables de déploiement :
   ```
   vim ansible/group_vars/all.yml
   ```

4. Lancer le déploiement :
   ```
   cd ansible
   ansible-playbook -i inventory.ini deploy-openstack.yml
   ```

Le déploiement complet peut prendre entre 30 et 60 minutes selon les performances du matériel.

### 3. Installation manuelle (alternative)

Si vous préférez une installation manuelle :

1. Sur le nœud contrôleur :
   ```
   bash scripts/install_controller.sh
   ```

2. Sur chaque nœud compute :
   ```
   bash scripts/install_compute.sh
   ```

### 4. Vérification de l'installation

Après l'installation, vérifiez que tous les services fonctionnent correctement :

1. Sur le nœud contrôleur :
   ```
   source /root/admin-openrc
   openstack service list
   openstack compute service list
   openstack network agent list
   ```

2. Accès au tableau de bord Horizon :
   - URL : http://<IP_DU_CONTROLEUR>/dashboard
   - Utilisateur : admin
   - Mot de passe : ADMIN_PASS (à modifier)

## Installation de l'interface utilisateur

### Prérequis
- Python 3.10+
- pip
- virtualenv

### Installation

1. Créer un environnement virtuel :
   ```
   cd ui
   python3 -m venv venv
   source venv/bin/activate  # Sous Windows : venv\Scripts\activate
   ```

2. Installer les dépendances :
   ```
   pip install -r requirements.txt
   ```

3. Configurer les variables d'environnement :
   ```
   export OPENSTACK_AUTH_URL="http://controller:5000/v3"
   export OPENSTACK_USERNAME="admin"
   export OPENSTACK_PASSWORD="ADMIN_PASS"
   ```

4. Lancer l'application :
   ```
   python app.py
   ```

L'interface sera accessible à l'adresse : http://localhost:5000

## Troubleshooting

Si vous rencontrez des problèmes durant l'installation, vérifiez :

1. La connectivité réseau entre les nœuds
2. Les journaux système : `/var/log/syslog`
3. Les journaux des services OpenStack : `/var/log/nova/`, `/var/log/neutron/`, etc.
4. L'état des services : `systemctl status nova-api`, `systemctl status neutron-server`, etc.
