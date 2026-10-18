# Odoo Community — Docker Compose

Infrastructure d'exploration pour Odoo Community 19.0 et PostgreSQL 16. Le code est 100 % dans ce dépôt ; Odoo et PostgreSQL s'exécutent dans deux conteneurs Docker d'une même stack.

## Architecture

- **odoo** : application Odoo Community sur le port 8069 (écoute locale par défaut).
- **db** : PostgreSQL 16 privé, non publié sur la machine hôte.
- **postgres_data** et **odoo_data** : volumes persistants.
- **addons/** : emplacement pour les modules Odoo personnalisés.
- **secrets/** : mots de passe générés localement, exclus de Git et du build Docker.

## Prérequis

Docker Engine / Docker Desktop avec Docker Compose v2. Sur Windows, Docker Desktop (moteur Linux/WSL2) et PowerShell suffisent. Sur Linux/macOS, prévoir Bash et OpenSSL pour l'initialisation. Prévoir environ 8 Go de RAM disponibles pour les essais.

## Installation depuis Windows PowerShell

Depuis le dossier du projet (`C:\\dev\\odoo` si tu l'as déjà cloné) :

~~~powershell
cd C:\dev\odoo
git pull --ff-only
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\init.ps1
docker compose config --quiet
docker compose up -d --build --force-recreate
docker compose ps
~~~

Le script `scripts/init.ps1` utilise le générateur cryptographique de Windows, crée `secrets/postgresql_password` et `secrets/odoo_master_password`, puis crée `.env` si nécessaire. Les secrets existants ne sont pas écrasés. **Ne lance pas `scripts/init.sh` directement dans PowerShell** : ce script est pour Bash.

Ouvrir ensuite **http://localhost:8069**. Pour consulter le mot de passe principal dans PowerShell :

~~~powershell
Get-Content .\secrets\odoo_master_password
~~~

### Si PostgreSQL est marqué `unhealthy`

Vérifier la présence de fichiers (et non de répertoires) dans `secrets/` :

~~~powershell
Get-ChildItem .\secrets -Force
docker compose logs --tail=100 db
~~~

Si un secret n'existe pas, relancer `init.ps1` puis `docker compose up -d --build --force-recreate`. Si un chemin de secret est un **répertoire**, examiner son contenu avant toute suppression, puis relancer l'initialisation. Ne pas utiliser `docker compose down -v` pour ce problème.

## Installation en local ou sur un serveur Linux

~~~bash
git clone https://github.com/eigen-forge/odoo.git
cd odoo
bash scripts/init.sh
docker compose config --quiet
docker compose up -d --build
docker compose ps
docker compose logs -f odoo
~~~

Laisser les conteneurs démarrés et accéder à **http://localhost:8069** dans le navigateur de la machine Docker.

### Première connexion

À l'écran de création de base Odoo :

1. Récupérer le **Master Password** sur l'hôte Docker avec la commande `cat secrets/odoo_master_password`.
2. Choisir une base, par exemple : **odoo_demo**.
3. Définir un email et un mot de passe administrateur Odoo propres à cette base (différents du Master Password).
4. Choisir la langue, éventuellement les données de démonstration, puis créer la base.
5. Dans le menu Applications, installer **Ventes**, **Achats**, **Inventaire** et **Point de vente** selon les besoins.

Il peut s'écouler un court délai entre le démarrage des conteneurs et l'affichage de la page Odoo.

## Accéder depuis son ordinateur à une instance AWS EC2

Par défaut, le port 8069 est lié à 127.0.0.1 sur la machine hôte ; il n'est **pas exposé publiquement**.

Démarrer Docker Compose sur l'EC2 avec les commandes précédentes, puis depuis votre ordinateur :

~~~bash
ssh -i ~/.ssh/ma-cle-ec2.pem -N -L 8069:127.0.0.1:8069 ubuntu@IP_PUBLIQUE_EC2
~~~

Garder la connexion SSH ouverte et ouvrir **http://localhost:8069** sur votre ordinateur. Adapter la clé, l'adresse IP et le nom d'utilisateur SSH. Limiter le port 22 du Security Group AWS à votre IP ; ne pas ouvrir 8069 ou 5432 à Internet.

## Utilisation

~~~bash
docker compose ps                   # état des conteneurs
docker compose logs -f odoo        # journaux Odoo
docker compose logs -f db          # journaux PostgreSQL
docker compose stop               # arrêter, sans supprimer les données
docker compose start              # redémarrer
docker compose down               # supprimer les conteneurs, garder les volumes
docker compose up -d --build      # reconstruire après modification
~~~

**Ne pas utiliser docker compose down -v** sans sauvegarde : cela efface les volumes et peut détruire les données.

### Sauvegarde de démonstration

Après avoir créé la base odoo_demo :

~~~bash
mkdir -p backups
docker compose exec -T db pg_dump -U odoo -Fc odoo_demo > backups/odoo_demo.dump
docker compose exec -T odoo tar -C /var/lib/odoo -cf - filestore > backups/odoo_filestore.tar
~~~

Pour une sauvegarde cohérente, interrompre temporairement les écritures ou utiliser le mécanisme de sauvegarde Odoo. Les sauvegardes automatisées, la restauration, HTTPS, le monitoring et le reverse proxy devront être ajoutés avant une mise en production.

## Configuration Ventes « as code » (exemple)

Le dépôt contient un module Odoo Community installable : **addons/eigen_sales_config/**. Il installe l'application officielle Ventes (dépendance **sale_management**) et applique des paramètres versionnés **uniquement dans la base de données sélectionnée** :

- Devis valables 21 jours
- Signature en ligne activée
- Paiement en ligne à la confirmation désactivé

Sur Windows PowerShell, après avoir créé la base **odoo_demo**, appliquer la configuration avec :

~~~powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\apply-sales-config.ps1 -Database odoo_demo -Action install
~~~

Pour réappliquer la configuration après modification du XML, remplacer **install** par **upgrade**.

Lire **[docs/sales-as-code.md](docs/sales-as-code.md)** pour les explications, les commandes Linux et les vérifications. Le script arrête temporairement le service web Odoo pour toutes les bases partagées par cette stack.

## Personnalisation et évolutions

Placer les nouveaux modules Odoo dans **addons/** (un sous-répertoire par module). Leur code est monté en lecture seule dans le conteneur ; redémarrer Odoo lorsque nécessaire et installer/actualiser les modules via l'interface ou la CLI.

Cette première version sert à **explorer Odoo Community**, et non encore à exploiter un SaaS multi-tenant. La souscription des clients, le provisionnement automatique, la gestion des sous-domaines et l'isolation multi-clients sont des chantiers ultérieurs.

Documentation de référence : https://hub.docker.com/_/odoo
