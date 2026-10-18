# Odoo Community — Docker Compose

Infrastructure d'exploration pour Odoo Community 19.0 et PostgreSQL 16. Le code est 100 % dans ce dépôt ; Odoo et PostgreSQL s'exécutent dans deux conteneurs Docker d'une même stack.

## Architecture

- **odoo** : application Odoo Community sur le port 8069 (écoute locale par défaut).
- **db** : PostgreSQL 16 privé, non publié sur la machine hôte.
- **postgres_data** et **odoo_data** : volumes persistants.
- **addons/** : emplacement pour les modules Odoo personnalisés.
- **secrets/** : mots de passe générés localement, exclus de Git et du build Docker.

## Prérequis

Docker Engine / Docker Desktop avec Docker Compose v2, Bash et OpenSSL. Sur Windows, utiliser WSL2. Prévoir environ 8 Go de RAM disponibles pour les essais.

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

1. Récupérer le **Master Password** sur l'hôte Docker avec : ~~~bash
   cat secrets/odoo_master_password
   ~~~
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

## Personnalisation et évolutions

Placer les nouveaux modules Odoo dans **addons/** (un sous-répertoire par module). Leur code est monté en lecture seule dans le conteneur ; redémarrer Odoo lorsque nécessaire et installer/actualiser les modules via l'interface ou la CLI.

Cette première version sert à **explorer Odoo Community**, et non encore à exploiter un SaaS multi-tenant. La souscription des clients, le provisionnement automatique, la gestion des sous-domaines et l'isolation multi-clients sont des chantiers ultérieurs.

Documentation de référence : https://hub.docker.com/_/odoo
