# OpenStack Cloud Platform

Projet de fin d'études pour mon M2 Cybersécurité & Cloud Computing

## Aperçu du Projet
Ce projet implémente une infrastructure cloud privée avec OpenStack, capable de gérer une soixantaine de machines virtuelles (30 Linux, 30 Windows), avec une interface utilisateur pour automatiser le déploiement.

## Objectifs
- Concevoir et déployer une infrastructure OpenStack dimensionnée pour ~60 VMs
- Automatiser le déploiement via une interface web
- Fournir une expérience pédagogique sur les concepts avancés du cloud

## Structure du Projet
- `/scripts` - Scripts d'installation et de configuration
- `/ansible` - Playbooks Ansible pour l'automatisation
- `/terraform` - Templates Terraform pour l'infrastructure
- `/ui` - Interface utilisateur web pour le déploiement
- `/docs` - Documentation technique et guides utilisateur

## Spécifications Techniques
### Dimensionnement
- RAM: 200 Go
- CPU: 100 vCPU
- Stockage: 3 To
- Réseau: 10 Gbps

### Infrastructure
- 1 contrôleur: 16 vCPU, 32 Go RAM, 500 Go SSD
- 2 nœuds compute: 48 vCPU, 96 Go RAM, 2 To stockage par nœud
- Réseau: 10 Gbps avec support VLAN/VXLAN

### Services OpenStack
- Keystone (authentification)
- Nova (compute)
- Neutron (réseau)
- Glance (images)
- Horizon (dashboard)
- Cinder/Ceph (stockage)

## Prérequis
- Ubuntu Server 22.04 LTS pour les nœuds
- Ansible pour l'automatisation
- Terraform pour la gestion de l'infrastructure
- Python (Flask/Django) ou JavaScript (React/Angular) pour l'IHM

## Installation
Consultez la documentation dans le dossier `/docs` pour les instructions détaillées d'installation et de configuration.
